/// 日志的严重程度级别
enum LogLevel {
  /// 用于详细调试的详细日志
  verbose,

  /// 用于常规调试目的的调试日志
  debug,

  /// 关于正常应用流程的信息性消息
  info,

  /// 关于潜在问题的警告消息
  warning,

  /// 关于需要关注的问题的错误消息
  error,

  /// 可能导致应用失败的关键错误
  critical,

  /// 关于性能指标的消息
  performance,
}

/// 日志操作接口
abstract class Logger {
  /// 在 verbose 级别记录消息
  void v(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 在 debug 级别记录消息
  void d(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 在 info 级别记录消息
  void i(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 在 warning 级别记录消息
  void w(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 在 error 级别记录消息
  void e(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 在 critical 级别记录消息
  void c(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 记录性能指标
  void p(String message, {Map<String, dynamic>? data, Duration? duration});

  /// 以指定级别记录消息
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  });

  /// 设置最低日志级别
  void setLogLevel(LogLevel level);

  /// 获取当前日志级别
  LogLevel getLogLevel();

  /// 创建带特定标签的子日志记录器
  Logger child(String tag);
}
