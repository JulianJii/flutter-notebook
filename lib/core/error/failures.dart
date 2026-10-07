import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

// 网络失败
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.statusCode,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Server error occurred',
    super.statusCode,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Connection timeout',
    super.statusCode,
  });
}

// 数据失败
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache failure', super.statusCode});
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'Validation error',
    super.statusCode,
  });
}

// 认证失败
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
    super.statusCode,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Unauthorized access',
    super.statusCode,
  });
}

class InputFailure extends Failure {
  const InputFailure({super.message = 'Invalid input', super.statusCode});
}

/// 系统通知失败：没授予通知权限，或 `zonedSchedule` 被系统拒绝（如精确闹钟权限）。
class NotificationFailure extends Failure {
  const NotificationFailure({
    super.message = 'Notification failure',
    super.statusCode,
  });
}

/// 笔记图片失败：选出来的文件读不出字节，或压缩失败。
///
/// ⛔ message 要给**用户能看懂的原因**：失败传回 UI 后直接进 Snackbar 文案
/// （见 `NoteImage` 的处理链路），开发者日志不属于 Failure。
class ImageFailure extends Failure {
  const ImageFailure({super.message = 'Image failure', super.statusCode});
}
