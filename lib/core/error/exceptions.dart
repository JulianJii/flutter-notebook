// 基础异常
abstract class AppException implements Exception {
  final String message;
  final String? prefix;

  AppException({required this.message, this.prefix});

  @override
  String toString() {
    return '$prefix$message';
  }
}

// 网络相关异常
class NetworkException extends AppException {
  NetworkException({super.message = 'No internet connection'})
    : super(prefix: 'Network Error: ');
}

class TimeoutException extends AppException {
  TimeoutException({super.message = 'Connection timeout'})
    : super(prefix: 'Timeout Error: ');
}

// 服务器相关异常
class ServerException extends AppException {
  ServerException({super.message = 'Internal server error'})
    : super(prefix: 'Server Error: ');
}

class BadRequestException extends AppException {
  BadRequestException({String? message})
    : super(message: message ?? 'Bad request', prefix: 'Invalid Request: ');
}

class UnauthorizedException extends AppException {
  UnauthorizedException({String? message})
    : super(message: message ?? 'Unauthorized', prefix: 'Unauthorized: ');
}

class ForbiddenException extends AppException {
  ForbiddenException({String? message})
    : super(message: message ?? 'Forbidden', prefix: 'Forbidden: ');
}

class NotFoundException extends AppException {
  NotFoundException({String? message})
    : super(message: message ?? 'Not found', prefix: 'Not Found: ');
}

class RequestCancelledException extends AppException {
  RequestCancelledException({super.message = 'Request cancelled'})
    : super(prefix: 'Request Cancelled: ');
}

// 缓存相关异常
class CacheException extends AppException {
  CacheException({super.message = 'Cache error'})
    : super(prefix: 'Cache Error: ');
}

// 认证相关异常
class AuthenticationException extends AppException {
  AuthenticationException({super.message = 'Authentication failed'})
    : super(prefix: 'Authentication Error: ');
}
