import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/analytics/analytics_providers.dart';
import 'package:init/core/auth/biometric_service.dart';
import 'package:init/core/auth/debug_biometric_service.dart';
import 'package:init/core/auth/local_biometric_service.dart';
import 'package:init/core/feature_flags/feature_flag_providers.dart';

/// 生物识别认证服务的 provider
final biometricServiceProvider = Provider<BiometricService>((ref) {
  // 检查是否处于 debug 模式或是否设置了 feature flag
  final useDebugService =
      kDebugMode &&
      ref.watch(
        featureFlagProvider('use_debug_biometrics', defaultValue: false),
      );

  // 创建合适的服务实现
  final service = useDebugService
      ? DebugBiometricService()
      : LocalBiometricService();

  // 将生物识别事件记录到分析服务
  final analytics = ref.watch(analyticsProvider);

  // 返回一个记录分析的代理服务
  return _AnalyticsBiometricServiceProxy(service, analytics);
});

/// 为生物识别操作添加分析日志的代理服务
class _AnalyticsBiometricServiceProxy implements BiometricService {
  final BiometricService _delegate;
  final Analytics _analytics;

  _AnalyticsBiometricServiceProxy(this._delegate, this._analytics);

  @override
  Future<bool> isAvailable() {
    return _delegate.isAvailable();
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() {
    return _delegate.getAvailableBiometrics();
  }

  @override
  Future<BiometricResult> authenticate({
    required String localizedReason,
    AuthReason reason = AuthReason.appAccess,
    bool sensitiveTransaction = false,
    String? dialogTitle,
    String? cancelButtonText,
  }) async {
    _analytics.logUserAction(
      action: 'biometric_auth_requested',
      category: 'authentication',
      label: reason.toString(),
      parameters: {
        'reason': reason.toString(),
        'sensitive_transaction': sensitiveTransaction,
      },
    );

    final result = await _delegate.authenticate(
      localizedReason: localizedReason,
      reason: reason,
      sensitiveTransaction: sensitiveTransaction,
      dialogTitle: dialogTitle,
      cancelButtonText: cancelButtonText,
    );

    _analytics.logUserAction(
      action: 'biometric_auth_completed',
      category: 'authentication',
      label: result.toString(),
      parameters: {'result': result.toString(), 'reason': reason.toString()},
    );

    return result;
  }
}

/// 检查生物识别认证是否可用的 provider
final biometricsAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.isAvailable();
});

/// 获取可用生物识别类型的 provider
final availableBiometricsProvider = FutureProvider<List<BiometricType>>((
  ref,
) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.getAvailableBiometrics();
});

/// 用于管理认证状态的控制器
/// 生物识别认证的状态
class BiometricAuthState {
  final bool isAuthenticated;
  final BiometricResult? lastResult;
  final DateTime? lastAuthTime;

  const BiometricAuthState({
    this.isAuthenticated = false,
    this.lastResult,
    this.lastAuthTime,
  });

  BiometricAuthState copyWith({
    bool? isAuthenticated,
    BiometricResult? lastResult,
    DateTime? lastAuthTime,
  }) {
    return BiometricAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lastResult: lastResult ?? this.lastResult,
      lastAuthTime: lastAuthTime ?? this.lastAuthTime,
    );
  }
}

/// 用于管理认证状态的控制器
class BiometricAuthController extends Notifier<BiometricAuthState> {
  @override
  BiometricAuthState build() {
    return const BiometricAuthState();
  }

  /// 用户当前是否已通过认证
  bool get isAuthenticated => state.isAuthenticated;

  /// 上次认证尝试的结果
  BiometricResult? get lastResult => state.lastResult;

  /// 用户上次通过认证的时间
  DateTime? get lastAuthTime => state.lastAuthTime;

  /// 使用生物识别对用户进行认证
  Future<BiometricResult> authenticate({
    required String reason,
    AuthReason authReason = AuthReason.appAccess,
    bool sensitiveTransaction = false,
    String? dialogTitle,
    String? cancelButtonText,
  }) async {
    final service = ref.read(biometricServiceProvider);
    final analytics = ref.read(analyticsProvider);

    final result = await service.authenticate(
      localizedReason: reason,
      reason: authReason,
      sensitiveTransaction: sensitiveTransaction,
      dialogTitle: dialogTitle,
      cancelButtonText: cancelButtonText,
    );

    BiometricAuthState newState = state.copyWith(lastResult: result);

    if (result == BiometricResult.success) {
      newState = newState.copyWith(
        isAuthenticated: true,
        lastAuthTime: DateTime.now(),
      );

      analytics.logUserAction(
        action: 'user_authenticated',
        category: 'authentication',
        label: authReason.toString(),
      );
    }

    state = newState;
    return result;
  }

  /// 清除已认证状态
  void logout() {
    final analytics = ref.read(analyticsProvider);

    state = const BiometricAuthState();

    analytics.logUserAction(
      action: 'user_logged_out',
      category: 'authentication',
    );
  }

  /// 检查是否需要重新认证（基于超时时间）
  bool isAuthenticationNeeded({Duration? timeout}) {
    if (!state.isAuthenticated) return true;

    if (timeout != null && state.lastAuthTime != null) {
      final now = DateTime.now();
      final sessionExpiry = state.lastAuthTime!.add(timeout);
      if (now.isAfter(sessionExpiry)) {
        state = state.copyWith(isAuthenticated: false);
        return true;
      }
    }

    return false;
  }
}

/// 生物识别认证控制器的 provider
final biometricAuthControllerProvider =
    NotifierProvider<BiometricAuthController, BiometricAuthState>(
      BiometricAuthController.new,
    );
