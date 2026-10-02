import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../error/failures.dart';
import '../../utils/logger.dart' as core_logger;
import 'webhook_signature.dart';

part 'webhook_sender.g.dart';

/// 成功发送出站 webhook 的结果。
class WebhookDeliveryResult {
  const WebhookDeliveryResult({
    required this.statusCode,
    required this.body,
    required this.signature,
  });

  final int statusCode;
  final dynamic body;

  /// 发送的 `sha256=<digest>` 签名，以便 UI/日志可以显示
  /// 接收方应验证的内容。
  final String signature;
}

/// 发送出站 webhook：一个纯 HTTP POST，其主体使用 HMAC-SHA256 签名，
/// 以便接收端点可以验证真实性，遵循 Stripe/GitHub/Shopify 使用的相同约定。
///
/// 这是"你有事件，其他服务器想了解它们"模式的一半；
/// [WebhookSignature] 持有共享的签名逻辑，
/// `local_webhook_receiver.dart` 展示了用于本地开发/测试的接收端。
class WebhookSender {
  WebhookSender(this._dio);

  final Dio _dio;

  Future<Either<Failure, WebhookDeliveryResult>> send({
    required String url,
    required Map<String, dynamic> payload,
    required String secret,
    Map<String, String>? extraHeaders,
  }) async {
    final body = jsonEncode(payload);
    final signature =
        'sha256=${WebhookSignature.sign(secret: secret, payload: body)}';

    try {
      final response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Webhook-Signature': signature,
            'X-Webhook-Timestamp': DateTime.now().toUtc().toIso8601String(),
            ...?extraHeaders,
          },
        ),
      );
      core_logger.Logger.info(
        'Webhook delivered to $url (status ${response.statusCode})',
      );
      return Right(
        WebhookDeliveryResult(
          statusCode: response.statusCode ?? 0,
          body: response.data,
          signature: signature,
        ),
      );
    } on DioException catch (e) {
      core_logger.Logger.error('Webhook delivery failed', e);
      return Left(
        ServerFailure(
          message: e.response != null
              ? 'Receiver returned ${e.response?.statusCode}'
              : (e.message ?? 'Webhook delivery failed'),
        ),
      );
    }
  }
}

@riverpod
WebhookSender webhookSender(Ref ref) => WebhookSender(Dio());
