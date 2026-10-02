import 'local_webhook_receiver_stub.dart'
    if (dart.library.io) 'local_webhook_receiver_io.dart'
    as platform;

/// [LocalWebhookReceiver] 接受的单个请求。
class ReceivedWebhook {
  const ReceivedWebhook({
    required this.receivedAt,
    required this.method,
    required this.headers,
    required this.body,
    required this.signatureVerified,
  });

  final DateTime receivedAt;
  final String method;
  final Map<String, String> headers;
  final String body;

  /// 未配置验证密钥时为 null；否则表示
  /// `X-Webhook-Signature` header 是否与请求体匹配。
  final bool? signatureVerified;
}

/// 一个用于在开发期间测试 webhook 发送方/签名验证的本地 HTTP 监听器。
///
/// 重要：此监听器仅绑定到 `127.0.0.1`。它是一个开发/测试辅助工具
///——例如将你自己的 [WebhookSender] 指向它，或使用 `ngrok` 或
/// `stripe listen` 等工具将真实提供商的 webhook 转发到它，
/// 在桌面/移动设备上进行开发。移动应用不能作为公共 webhook 端点；
/// 生产 webhook 接收器运行在你控制的服务器上，而不是在客户端应用内。
/// 在 Web 上不可用——[start] 会抛出异常，因为它需要 `dart:io` 的 `HttpServer`。
abstract class LocalWebhookReceiver {
  factory LocalWebhookReceiver() = platform.LocalWebhookReceiverImpl;

  /// 每个接受的请求到达时发出。
  Stream<ReceivedWebhook> get events;

  bool get isRunning;

  /// 在回环地址上开始监听并返回绑定的 URL
  ///（例如 `http://127.0.0.1:54231/webhook`）。如果提供了 [secret]，
  /// 传入的请求会对其进行验证（参见 [ReceivedWebhook.signatureVerified]）。
  Future<Uri> start({int port = 0, String? secret});

  Future<void> stop();
}
