
/// 应用中所有分析事件的基础类
abstract class AnalyticsEvent {
  /// 事件名称，将按此上报给分析服务
  String get name;

  /// 与此事件关联的参数
  Map<String, dynamic> get parameters => {};

  @override
  String toString() => 'AnalyticsEvent(name: $name, parameters: $parameters)';
}

/// 追踪屏幕浏览的事件
class ScreenViewEvent extends AnalyticsEvent {
  final String screenName;
  final Map<String, dynamic>? screenParameters;

  ScreenViewEvent(this.screenName, {this.screenParameters});

  @override
  String get name => 'screen_view';

  @override
  Map<String, dynamic> get parameters => {
    'screen_name': screenName,
    ...?screenParameters,
  };
}

/// 追踪用户操作（如按钮点击）的事件
class UserActionEvent extends AnalyticsEvent {
  final String action;
  final String? category;
  final String? label;
  final int? value;
  final Map<String, dynamic>? extraParams;

  UserActionEvent({
    required this.action,
    this.category,
    this.label,
    this.value,
    this.extraParams,
  });

  @override
  String get name => 'user_action';

  @override
  Map<String, dynamic> get parameters => {
    'action': action,
    if (category != null) 'category': category,
    if (label != null) 'label': label,
    if (value != null) 'value': value,
    ...?extraParams,
  };
}

/// 追踪错误或异常的事件
class ErrorEvent extends AnalyticsEvent {
  final String errorType;
  final String message;
  final String? stackTrace;
  final bool isFatal;

  ErrorEvent({
    required this.errorType,
    required this.message,
    this.stackTrace,
    this.isFatal = false,
  });

  @override
  String get name => 'app_error';

  @override
  Map<String, dynamic> get parameters => {
    'error_type': errorType,
    'message': message,
    'is_fatal': isFatal,
    if (stackTrace != null) 'stack_trace': stackTrace,
  };
}

/// 追踪性能相关指标的事件
class PerformanceEvent extends AnalyticsEvent {
  final String metricName;
  final num value;
  final String unit;
  final Map<String, dynamic>? extraParams;

  PerformanceEvent({
    required this.metricName,
    required this.value,
    this.unit = 'ms',
    this.extraParams,
  });

  @override
  String get name => 'performance';

  @override
  Map<String, dynamic> get parameters => {
    'metric_name': metricName,
    'value': value,
    'unit': unit,
    ...?extraParams,
  };
}
