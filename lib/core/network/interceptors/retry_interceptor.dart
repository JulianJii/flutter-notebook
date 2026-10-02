import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 重试失败请求的拦截器
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      final attempt = err.requestOptions.headers['retry_attempt'] ?? 0;

      if (attempt < maxRetries && attempt < retryDelays.length) {
        final delay = retryDelays[attempt];
        debugPrint(
          '🔄 Retry attempt ${attempt + 1}/$maxRetries for ${err.requestOptions.path} after ${delay.inSeconds}s',
        );

        // 更新重试尝试次数
        err.requestOptions.headers['retry_attempt'] = attempt + 1;

        // 等待后重试
        await Future.delayed(delay);

        try {
          // 克隆请求并重试
          final options = Options(
            method: err.requestOptions.method,
            headers: err.requestOptions.headers,
            contentType: err.requestOptions.contentType,
            responseType: err.requestOptions.responseType,
            followRedirects: err.requestOptions.followRedirects,
            listFormat: err.requestOptions.listFormat,
            receiveTimeout: err.requestOptions.receiveTimeout,
            sendTimeout: err.requestOptions.sendTimeout,
            validateStatus: err.requestOptions.validateStatus,
            extra: err.requestOptions.extra,
          );

          final response = await dio.request(
            err.requestOptions.path,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
            cancelToken: err.requestOptions.cancelToken,
            options: options,
            onSendProgress: err.requestOptions.onSendProgress,
            onReceiveProgress: err.requestOptions.onReceiveProgress,
          );

          return handler.resolve(response);
        } catch (e) {
          // 如果重试失败，错误将由下一个错误处理器处理
          return super.onError(err, handler);
        }
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.type == DioExceptionType.unknown &&
            err.error != null &&
            err.error is SocketException);
  }
}
