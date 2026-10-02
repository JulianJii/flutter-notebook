import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 应用版本检查的结果
enum UpdateCheckResult {
  /// 应用已是最新版本
  upToDate,

  /// 有可选的更新可用
  updateAvailable,

  /// 需要关键更新
  criticalUpdateRequired,

  /// 检查失败或无法执行
  checkFailed,
}

/// 可用更新的信息
class UpdateInfo {
  /// 可用的最新版本
  final String latestVersion;

  /// 最低要求版本
  final String minimumRequiredVersion;

  /// 该更新是否关键
  final bool isCritical;

  /// 最新版本的发布说明
  final String? releaseNotes;

  /// 更新应用的 URL（商店 URL）
  final String? updateUrl;

  /// 创建更新信息
  const UpdateInfo({
    required this.latestVersion,
    required this.minimumRequiredVersion,
    required this.isCritical,
    this.releaseNotes,
    this.updateUrl,
  });

  /// 使用给定字段替换创建此更新信息的副本
  UpdateInfo copyWith({
    String? latestVersion,
    String? minimumRequiredVersion,
    bool? isCritical,
    String? releaseNotes,
    String? updateUrl,
  }) {
    return UpdateInfo(
      latestVersion: latestVersion ?? this.latestVersion,
      minimumRequiredVersion:
          minimumRequiredVersion ?? this.minimumRequiredVersion,
      isCritical: isCritical ?? this.isCritical,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      updateUrl: updateUrl ?? this.updateUrl,
    );
  }
}

/// 应用更新服务的接口
abstract class UpdateService {
  /// 检查是否有可用更新
  Future<UpdateCheckResult> checkForUpdates();

  /// 获取可用更新的信息
  Future<UpdateInfo?> getUpdateInfo();

  /// 提示用户更新应用
  Future<bool> promptUpdate({bool force = false});

  /// 打开应用商店以更新应用
  Future<bool> openUpdateUrl();

  /// 初始化更新服务
  Future<void> init();

  /// 比较版本字符串以判断是否需要更新
  bool isUpdateNeeded(String currentVersion, String latestVersion);

  /// 判断更新是否关键
  bool isCriticalUpdate(String currentVersion, String minimumRequired);
}

/// 更新服务的基础实现
class BasicUpdateService implements UpdateService {
  final String _androidPackageName;
  final String _iOSAppId;

  PackageInfo? _packageInfo;
  UpdateInfo? _updateInfo;

  /// 创建基础更新服务
  BasicUpdateService({
    required String androidPackageName,
    required String iOSAppId,
  }) : _androidPackageName = androidPackageName,
       _iOSAppId = iOSAppId;

  @override
  Future<void> init() async {
    // 获取包信息
    _packageInfo = await PackageInfo.fromPlatform();
    debugPrint(
      '⬆️ Update service initialized: v${_packageInfo?.version}+${_packageInfo?.buildNumber}',
    );
  }

  @override
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      // 确保已初始化
      if (_packageInfo == null) {
        await init();
      }

      // 在真实实现中，这里会发起网络请求来检查更新
      // 在本示例中，我们仅用一些示例数据进行模拟
      await Future.delayed(const Duration(seconds: 1));

      // 模拟从服务器获取更新信息
      _updateInfo = await _fetchUpdateInfo();

      // 检查是否需要更新
      if (_updateInfo == null) {
        return UpdateCheckResult.checkFailed;
      }

      // 检查这是否是关键更新
      if (isCriticalUpdate(
        _packageInfo!.version,
        _updateInfo!.minimumRequiredVersion,
      )) {
        return UpdateCheckResult.criticalUpdateRequired;
      }

      // 检查是否有可用更新
      if (isUpdateNeeded(_packageInfo!.version, _updateInfo!.latestVersion)) {
        return UpdateCheckResult.updateAvailable;
      }

      return UpdateCheckResult.upToDate;
    } catch (e) {
      debugPrint('⬆️ Update check failed: $e');
      return UpdateCheckResult.checkFailed;
    }
  }

  @override
  Future<UpdateInfo?> getUpdateInfo() async {
    if (_updateInfo == null) {
      await checkForUpdates();
    }
    return _updateInfo;
  }

  @override
  Future<bool> promptUpdate({bool force = false}) async {
    // 确保我们有更新信息
    final updateInfo = await getUpdateInfo();
    if (updateInfo == null) {
      return false;
    }

    debugPrint(
      '⬆️ Prompting for update to version ${updateInfo.latestVersion} '
      '(current: ${_packageInfo?.version})',
    );

    // 在真实应用中，这里会向用户显示对话框
    // 若用户同意更新则返回 true
    return true;
  }

  @override
  Future<bool> openUpdateUrl() async {
    try {
      final updateInfo = await getUpdateInfo();
      if (updateInfo?.updateUrl != null) {
        // 如有则打开更新 URL
        return await _launchUrl(updateInfo!.updateUrl!);
      }

      // 根据平台回退到商店 URL
      String url;
      if (Platform.isAndroid) {
        url =
            'https://play.google.com/store/apps/details?id=$_androidPackageName';
      } else if (Platform.isIOS) {
        url = 'https://apps.apple.com/app/id$_iOSAppId';
      } else {
        return false;
      }

      return await _launchUrl(url);
    } catch (e) {
      debugPrint('⬆️ Failed to open update URL: $e');
      return false;
    }
  }

  @override
  bool isUpdateNeeded(String currentVersion, String latestVersion) {
    // 比较语义化版本
    // 这是一个简化的版本，仅比较 major.minor.patch
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      // 比较主版本号
      if (latest[0] > current[0]) return true;
      if (latest[0] < current[0]) return false;

      // 比较次版本号
      if (latest[1] > current[1]) return true;
      if (latest[1] < current[1]) return false;

      // 比较修订版本号
      return latest[2] > current[2];
    } catch (e) {
      debugPrint('⬆️ Version comparison error: $e');
      return false;
    }
  }

  @override
  bool isCriticalUpdate(String currentVersion, String minimumRequired) {
    try {
      final current = _parseVersion(currentVersion);
      final minimum = _parseVersion(minimumRequired);

      // 如果当前版本低于最低要求版本，则为关键更新
      if (current[0] < minimum[0]) return true;
      if (current[0] > minimum[0]) return false;

      if (current[1] < minimum[1]) return true;
      if (current[1] > minimum[1]) return false;

      return current[2] < minimum[2];
    } catch (e) {
      debugPrint('⬆️ Critical update check error: $e');
      return false;
    }
  }

  // 辅助方法：将类似 "1.2.3" 的版本字符串解析为整数列表 [1, 2, 3]
  List<int> _parseVersion(String version) {
    final parts = version.split('.');

    if (parts.length < 3) {
      // 如果部分少于 3 个，则用 0 补齐
      parts.addAll(List.filled(3 - parts.length, '0'));
    }

    return parts.take(3).map((part) {
      // 移除任何非数字后缀
      final match = RegExp(r'^\d+').firstMatch(part);
      final digitPart = match != null ? match.group(0) : '0';
      return int.tryParse(digitPart ?? '0') ?? 0;
    }).toList();
  }

  // 打开 URL 的辅助方法
  Future<bool> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      return await launchUrl(Uri.parse(url));
    }
    return false;
  }

  // 模拟从服务器获取更新信息
  Future<UpdateInfo> _fetchUpdateInfo() async {
    // 在真实实现中，这会从 API 或 appcast 获取
    // 这只是一个基于当前应用版本的示例
    final currentVersion = _packageInfo?.version ?? '1.0.0';

    // 出于演示目的，始终返回比当前高一个版本的更新
    final current = _parseVersion(currentVersion);
    final nextVersion = '${current[0]}.${current[1]}.${current[2] + 1}';
    final minRequired = '${current[0]}.${current[1]}.0';

    return UpdateInfo(
      latestVersion: nextVersion,
      minimumRequiredVersion: minRequired,
      isCritical: false,
      releaseNotes: 'Bug fixes and performance improvements.',
      updateUrl: Platform.isAndroid
          ? 'https://play.google.com/store/apps/details?id=$_androidPackageName'
          : 'https://apps.apple.com/app/id$_iOSAppId',
    );
  }
}
