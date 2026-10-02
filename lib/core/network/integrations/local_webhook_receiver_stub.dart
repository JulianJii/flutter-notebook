import 'local_webhook_receiver.dart';

/// Web 回退：`dart:io` 的 `HttpServer` 在浏览器中不存在，
/// 因此本地接收器在 Web 上不可用。
class LocalWebhookReceiverImpl implements LocalWebhookReceiver {
  @override
  Stream<ReceivedWebhook> get events => const Stream.empty();

  @override
  bool get isRunning => false;

  @override
  Future<Uri> start({int port = 0, String? secret}) {
    throw UnsupportedError(
      'The local webhook receiver uses dart:io HttpServer and is not '
      'available on web. Run this demo on a desktop or mobile debug build.',
    );
  }

  @override
  Future<void> stop() async {}
}
