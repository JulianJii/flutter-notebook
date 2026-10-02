import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/logging/console_logger.dart';
import 'package:init/core/logging/logger.dart';

/// 全局日志记录器实例的 Provider
final loggerProvider = Provider<Logger>((ref) {
  // 创建根日志记录器实例
  return ConsoleLogger(
    logLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
    includeTimestamp: true,
    includeLogLevel: true,
  );
});

/// 带特定标签的日志记录器 Provider
final taggedLoggerProvider = Provider.family<Logger, String>((ref, tag) {
  final rootLogger = ref.watch(loggerProvider);
  return rootLogger.child(tag);
});

/// 用于自动计时操作的性能日志扩展方法
extension LoggerPerformanceExtension on Logger {
  /// 运行并计时一个同步操作
  T timeSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? data,
  }) {
    final stopwatch = Stopwatch()..start();
    try {
      return operation();
    } finally {
      stopwatch.stop();
      p('$operationName completed', data: data, duration: stopwatch.elapsed);
    }
  }

  /// 运行并计时一个异步操作
  Future<T> timeAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? data,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      stopwatch.stop();
      p('$operationName completed', data: data, duration: stopwatch.elapsed);
    }
  }
}

/// 为任意类添加日志记录能力的 Mixin
mixin LoggerMixin {
  Logger get logger => ConsoleLogger(tag: runtimeType.toString());

  void logVerbose(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.v(message, data: data, error: error, stackTrace: stackTrace);
  }

  void logDebug(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.d(message, data: data, error: error, stackTrace: stackTrace);
  }

  void logInfo(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.i(message, data: data, error: error, stackTrace: stackTrace);
  }

  void logWarning(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.w(message, data: data, error: error, stackTrace: stackTrace);
  }

  void logError(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.e(message, data: data, error: error, stackTrace: stackTrace);
  }

  void logCritical(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logger.c(message, data: data, error: error, stackTrace: stackTrace);
  }

  void logPerformance(
    String message, {
    Map<String, dynamic>? data,
    Duration? duration,
  }) {
    logger.p(message, data: data, duration: duration);
  }
}

/// 从 provider 获取日志记录器的 widget 专用日志 Mixin
mixin WidgetLoggerMixin on ConsumerStatefulWidget {
  String get logTag => runtimeType.toString();
}

/// 使用 providers 进行日志记录的 State mixin
mixin LoggerStateMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final Logger logger;

  @override
  void initState() {
    super.initState();
    if (widget is WidgetLoggerMixin) {
      final tag = (widget as WidgetLoggerMixin).logTag;
      logger = ref.read(taggedLoggerProvider(tag));
    } else {
      logger = ref.read(taggedLoggerProvider(widget.runtimeType.toString()));
    }
    logger.d('${widget.runtimeType} initialized');
  }

  @override
  void dispose() {
    logger.d('${widget.runtimeType} disposed');
    super.dispose();
  }
}
