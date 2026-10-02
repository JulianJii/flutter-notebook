import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/analytics/analytics_event.dart';
import 'package:init/core/analytics/analytics_service.dart';
import 'package:init/core/analytics/firebase_analytics_service.dart';
import 'package:init/core/feature_flags/feature_flag_providers.dart';

/// 供开发使用的调试分析服务
class DebugAnalyticsService implements AnalyticsService {
  bool _isEnabled = true;

  @override
  Future<void> init() async {
    debugPrint('📊 Debug Analytics initialized');
  }

  @override
  void logEvent(AnalyticsEvent event) {
    if (!_isEnabled) return;
    debugPrint('📊 DEBUG ANALYTICS: ${event.name} - ${event.parameters}');
  }

  @override
  void setUserProperties({
    required String userId,
    Map<String, dynamic>? properties,
  }) {
    if (!_isEnabled) return;
    debugPrint('📊 DEBUG ANALYTICS: Set user ID: $userId');
    if (properties != null) {
      debugPrint('📊 DEBUG ANALYTICS: User properties: $properties');
    }
  }

  @override
  void resetUser() {
    if (!_isEnabled) return;
    debugPrint('📊 DEBUG ANALYTICS: Reset user');
  }

  @override
  void enable() {
    _isEnabled = true;
    debugPrint('📊 DEBUG ANALYTICS: Enabled');
  }

  @override
  void disable() {
    _isEnabled = false;
    debugPrint('📊 DEBUG ANALYTICS: Disabled');
  }

  @override
  bool get isEnabled => _isEnabled;
}

/// 分析服务的 provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  // 通过 feature flag 检查分析功能是否启用
  final analyticsEnabled = ref.watch(
    featureFlagProvider('enable_analytics', defaultValue: true),
  );

  // 创建合适的分析服务实现
  final services = <AnalyticsService>[];

  // 在生产环境始终添加 Firebase Analytics
  if (!kDebugMode ||
      ref.watch(
        featureFlagProvider('force_firebase_analytics', defaultValue: false),
      )) {
    services.add(FirebaseAnalyticsService());
  }

  // 在 debug 模式下添加调试分析
  if (kDebugMode) {
    services.add(DebugAnalyticsService());
  }

  // 创建包含所有已启用分析 provider 的复合服务
  final service = CompositeAnalyticsService(services);

  // 根据用户偏好启用/禁用
  if (analyticsEnabled) {
    service.enable();
  } else {
    service.disable();
  }

  return service;
});

/// 用于访问分析事件记录器的 provider
final analyticsProvider = Provider<Analytics>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return Analytics(service);
});

/// 用于记录分析事件的辅助类
class Analytics {
  final AnalyticsService _service;

  Analytics(this._service);

  /// 记录屏幕浏览事件
  void logScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    _service.logEvent(
      ScreenViewEvent(screenName, screenParameters: parameters),
    );
  }

  /// 记录用户操作事件
  void logUserAction({
    required String action,
    String? category,
    String? label,
    int? value,
    Map<String, dynamic>? parameters,
  }) {
    _service.logEvent(
      UserActionEvent(
        action: action,
        category: category,
        label: label,
        value: value,
        extraParams: parameters,
      ),
    );
  }

  /// 记录错误事件
  void logError({
    required String errorType,
    required String message,
    String? stackTrace,
    bool isFatal = false,
  }) {
    _service.logEvent(
      ErrorEvent(
        errorType: errorType,
        message: message,
        stackTrace: stackTrace,
        isFatal: isFatal,
      ),
    );
  }

  /// 记录性能事件
  void logPerformance({
    required String name,
    required num value,
    String unit = 'ms',
    Map<String, dynamic>? parameters,
  }) {
    _service.logEvent(
      PerformanceEvent(
        metricName: name,
        value: value,
        unit: unit,
        extraParams: parameters,
      ),
    );
  }

  /// 设置用户属性
  void setUser({required String userId, Map<String, dynamic>? properties}) {
    _service.setUserProperties(userId: userId, properties: properties);
  }

  /// 重置用户
  void resetUser() {
    _service.resetUser();
  }

  /// 启用分析
  void enable() {
    _service.enable();
  }

  /// 禁用分析
  void disable() {
    _service.disable();
  }

  /// 检查分析功能是否已启用
  bool get isEnabled => _service.isEnabled;
}

/// 自动追踪屏幕浏览的 Widget
class AnalyticsScreenView extends StatefulWidget {
  final String screenName;
  final Map<String, dynamic>? parameters;
  final Widget child;

  const AnalyticsScreenView({
    super.key,
    required this.screenName,
    this.parameters,
    required this.child,
  });

  @override
  State<AnalyticsScreenView> createState() => _AnalyticsScreenViewState();
}

class _AnalyticsScreenViewState extends State<AnalyticsScreenView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ProviderScope.containerOf(
        context,
      ).read(analyticsProvider);
      analytics.logScreenView(widget.screenName, parameters: widget.parameters);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
