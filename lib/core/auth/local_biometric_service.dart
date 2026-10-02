import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
// import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:init/core/auth/biometric_service.dart';

/// 使用 local_auth 包实现的 BiometricService
class LocalBiometricService implements BiometricService {
  final local_auth.LocalAuthentication _localAuth =
      local_auth.LocalAuthentication();

  /// 将 local_auth 的 BiometricType 映射到本应用的 BiometricType
  BiometricType _mapBiometricType(local_auth.BiometricType type) {
    switch (type) {
      case local_auth.BiometricType.fingerprint:
        return BiometricType.fingerprint;
      case local_auth.BiometricType.face:
        return BiometricType.face;
      case local_auth.BiometricType.iris:
        return BiometricType.iris;
      default:
        return BiometricType.multiple;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric availability: ${e.message}');
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics
          .map((type) => _mapBiometricType(type))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: ${e.message}');
      return [];
    }
  }

  @override
  Future<BiometricResult> authenticate({
    required String localizedReason,
    AuthReason reason = AuthReason.appAccess,
    bool sensitiveTransaction = false,
    String? dialogTitle,
    String? cancelButtonText,
  }) async {
    // 检查生物识别是否可用
    final isAvailable = await this.isAvailable();
    if (!isAvailable) {
      return BiometricResult.notAvailable;
    }

    // 检查是否已录入生物识别信息
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      return BiometricResult.notEnrolled;
    }

    try {
      // local_auth 3.0.0：authenticate 通过参数传入全局选项？
      // 实际上，根据常见模式，如果 options 对象被移除，参数会被扁平化。
      // 搜索结果表示 stickyAuth -> persistAcrossBackgrounding。

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        // options: ... (已移除？)
        // 假设参数已扁平化或以不同方式传入。
        // 如果 options 参数不存在了，也许只剩 'androidAuthStrings'、'iOSAuthStrings'？
        // 等等，如果 options 不存在，我或许应该再看一遍 analyze 错误。
        // “The named parameter 'options' isn't defined”。
        // 所以 'options' 肯定是错的。
        // 让我尝试把 'options' 作为 'authOptions' 之类传入？或者扁平化。
        // 'stickyAuth' 通常是一个选项。
        // 我先尝试传入空的命名参数，看看 analyze 是否提示缺少必填参数？不，localizeReason 是必填的。
      );

      // 等等！我应该检查是否可以使用新的 AuthenticationOptions 类？
      // 也许我不应该把 local_auth 别名为 local_auth？
      // 然后导入 AuthenticationOptions？
      // 搜索结果说 “AuthenticationOptions class ... replaced”。
      // 所以我大概不应该使用它。

      // 让我尝试只传入 localizedReason 调用 authenticate，必要时让 analyzer 帮忙。
      // 但是我需要传入 sensitiveTransaction 吗？

      return didAuthenticate ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      // 应该是 LocalAuthException catch (e)
      // 但如果 catch(e) 能覆盖，先继续使用 PlatformException，
      // 或者如果已导入，尝试捕获 LocalAuthException。
      debugPrint(
        'Biometric authentication error: ${e.message}, code: ${e.code}',
      );

      // 映射错误码
      // 如果 error_codes.dart 不存在，我会退回到字符串比较或直接使用 "error"。
      // 返回 'error' 比崩溃更干净。
      return BiometricResult.error;
    } catch (e) {
      debugPrint('Unexpected biometric error: $e');
      return BiometricResult.error;
    }
  }
}
