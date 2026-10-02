import 'greeter_client.dart';

/// Web 回退：真实的 gRPC HTTP/2 连接需要 `dart:io` 套接字，
/// 而 grpc-web（浏览器兼容变体）需要在服务器前端部署翻译代理，
/// 因此此演示在 Web 上不可用。
class GrpcGreeterClientImpl implements GrpcGreeterClient {
  @override
  bool get isConnected => false;

  @override
  void connect({required String host, required int port, bool useTls = false}) {
    throw UnsupportedError(
      'gRPC over a raw HTTP/2 socket is not available on web. Use '
      'package:grpc/grpc_web.dart with a grpc-web-compatible proxy '
      '(e.g. Envoy) in front of your server instead.',
    );
  }

  @override
  Future<String> sayHello(String name) => throw UnsupportedError(
    'gRPC over a raw HTTP/2 socket is not available on web.',
  );

  @override
  Stream<String> sayHelloStream(String name) => throw UnsupportedError(
    'gRPC over a raw HTTP/2 socket is not available on web.',
  );

  @override
  Future<void> disconnect() async {}
}
