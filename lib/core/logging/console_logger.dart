import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:init/core/logging/logger.dart';

/// 输出到调试控制台的日志记录器实现
class ConsoleLogger implements Logger {
  /// 此记录器的标签
  final String _tag;

  /// 要显示的最低日志级别
  LogLevel _logLevel;

  /// 是否在日志消息中包含时间戳
  final bool _includeTimestamp;

  /// 是否在日志消息中包含日志级别
  final bool _includeLogLevel;

  /// 时间戳格式
  final DateFormat _timestampFormat;

  /// 创建新的控制台日志记录器
  ConsoleLogger({
    String tag = '',
    LogLevel logLevel = LogLevel.info,
    bool includeTimestamp = true,
    bool includeLogLevel = true,
  }) : _tag = tag,
       _logLevel = logLevel,
       _includeTimestamp = includeTimestamp,
       _includeLogLevel = includeLogLevel,
       _timestampFormat = DateFormat('HH:mm:ss.SSS');

  @override
  void v(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.verbose,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void d(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.debug,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void i(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.info,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void w(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.warning,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void e(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.error,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void c(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.critical,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void p(String message, {Map<String, dynamic>? data, Duration? duration}) {
    final perfData = <String, dynamic>{...?data};
    if (duration != null) {
      perfData['duration_ms'] = duration.inMicroseconds / 1000;
    }
    log(LogLevel.performance, message, data: perfData);
  }

  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _logLevel.index) return;

    final buffer = StringBuffer();

    // 如果请求则添加时间戳
    if (_includeTimestamp) {
      final timestamp = _timestampFormat.format(DateTime.now());
      buffer.write('[$timestamp] ');
    }

    // 如果请求则添加日志级别
    if (_includeLogLevel) {
      final levelStr = _getLevelString(level);
      buffer.write('$levelStr ');
    }

    // 如果有标签则添加标签
    if (_tag.isNotEmpty) {
      buffer.write('[$_tag] ');
    }

    // 添加消息
    buffer.write(message);

    // 如果存在数据则添加数据
    if (data != null && data.isNotEmpty) {
      buffer.write(' - ${_formatData(data)}');
    }

    // 打印日志消息
    debugPrint(buffer.toString());

    // 如果存在错误和堆栈跟踪则打印
    if (error != null) {
      debugPrint('Error: $error');
      final trace = stackTrace ?? StackTrace.current;
      debugPrint('Stack trace:\n$trace');
    }
  }

  @override
  void setLogLevel(LogLevel level) {
    _logLevel = level;
  }

  @override
  LogLevel getLogLevel() {
    return _logLevel;
  }

  @override
  Logger child(String tag) {
    final newTag = _tag.isEmpty ? tag : '$_tag:$tag';
    return ConsoleLogger(
      tag: newTag,
      logLevel: _logLevel,
      includeTimestamp: _includeTimestamp,
      includeLogLevel: _includeLogLevel,
    );
  }

  /// 将日志级别转换为带颜色的字符串表示
  String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return '[VERB]';
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
      case LogLevel.critical:
        return '[CRIT]';
      case LogLevel.performance:
        return '[PERF]';
    }
  }

  /// 格式化用于日志记录的数据映射
  String _formatData(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }
}
