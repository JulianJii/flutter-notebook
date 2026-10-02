/// 与框架无关的数据层日志工具
///
/// 这使得数据层可以保持独立于 Flutter 框架
/// 同时仍提供日志记录能力。
abstract class Logger {
  /// 记录一条 debug 日志
  static void debug(String message) {
    // 在生产环境中，这里可以替换为合适的日志服务
    // ignore: avoid_print
    print('[DEBUG] $message');
  }

  /// 记录一条 info 日志
  static void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  /// 记录一条 warning 日志
  static void warning(String message) {
    // ignore: avoid_print
    print('[WARNING] $message');
  }

  /// 记录一条 error 日志
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) {
      // ignore: avoid_print
      print('Error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
    }
  }
}
