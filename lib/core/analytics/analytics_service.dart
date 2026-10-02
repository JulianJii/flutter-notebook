import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:init/core/analytics/analytics_event.dart';

/// 分析服务实现接口
abstract class AnalyticsService {
  /// 初始化分析服务
  FutureOr<void> init();

  /// 记录分析事件
  void logEvent(AnalyticsEvent event);

  /// 设置用户级别的分析用户属性
  void setUserProperties({
    required String userId,
    Map<String, dynamic>? properties,
  });

  /// 清除所有用户属性和标识符
  void resetUser();

  /// 启用分析数据采集
  void enable();

  /// 禁用分析数据采集
  void disable();

  /// 检查分析数据采集是否已启用
  bool get isEnabled;
}

/// 将事件记录到多个分析 provider 的服务
class CompositeAnalyticsService implements AnalyticsService {
  final List<AnalyticsService> _services;

  CompositeAnalyticsService(this._services);

  @override
  FutureOr<void> init() async {
    for (final service in _services) {
      await service.init();
    }
  }

  @override
  void logEvent(AnalyticsEvent event) {
    for (final service in _services) {
      service.logEvent(event);
    }
  }

  @override
  void setUserProperties({
    required String userId,
    Map<String, dynamic>? properties,
  }) {
    for (final service in _services) {
      service.setUserProperties(userId: userId, properties: properties);
    }
  }

  @override
  void resetUser() {
    for (final service in _services) {
      service.resetUser();
    }
  }

  @override
  void enable() {
    for (final service in _services) {
      service.enable();
    }
  }

  @override
  void disable() {
    for (final service in _services) {
      service.disable();
    }
  }

  @override
  bool get isEnabled =>
      _services.isNotEmpty ? _services.first.isEnabled : false;
}

/// 将分析事件记录到调试控制台的服务
class DebugAnalyticsService implements AnalyticsService {
  bool _enabled = true;

  @override
  FutureOr<void> init() {
    debugPrint('🔍 DebugAnalyticsService initialized');
  }

  @override
  void logEvent(AnalyticsEvent event) {
    if (!_enabled) return;
    debugPrint('📊 Analytics Event: ${event.name}');
    debugPrint('📊 Parameters: ${event.parameters}');
  }

  @override
  void setUserProperties({
    required String userId,
    Map<String, dynamic>? properties,
  }) {
    if (!_enabled) return;
    debugPrint('👤 User identified: $userId');
    if (properties != null) {
      debugPrint('👤 User properties: $properties');
    }
  }

  @override
  void resetUser() {
    if (!_enabled) return;
    debugPrint('👤 User reset');
  }

  @override
  void enable() {
    _enabled = true;
    debugPrint('📊 Analytics enabled');
  }

  @override
  void disable() {
    _enabled = false;
    debugPrint('📊 Analytics disabled');
  }

  @override
  bool get isEnabled => _enabled;
}
