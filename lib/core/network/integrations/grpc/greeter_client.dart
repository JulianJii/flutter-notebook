import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'greeter_client_stub.dart'
    if (dart.library.io) 'greeter_client_io.dart'
    as platform;

/// 对生成的 `GreeterClient` gRPC 存根（`greeter.pbgrpc.dart`）的轻量封装，
/// 演示两种 RPC 风格：
/// - [sayHello]：一元调用，一个请求，一个响应。
/// - [sayHelloStream]：服务端流式，一个请求，多个响应。
///
/// `helloworld.Greeter/SayHello` 是标准的 gRPC "hello world" 契约，
/// 因此 [connect] 默认连接公共的 `grpcb.in:9000` 测试服务器，
/// 一元调用无需配置即可工作。`SayHelloStream` 是模板特定的扩展；
/// 在本地运行 `tool/grpc_demo_server.dart`（参见其头部注释）
/// 并连接到 `localhost:50051` 以进行端到端测试。
///
/// 在 Web 上不可用：真实 gRPC 需要 HTTP/2 套接字（`dart:io`），
/// 而 grpc-web 需要在服务器前端部署翻译代理，
/// 此演示的目标服务器未提供此功能。
abstract class GrpcGreeterClient {
  factory GrpcGreeterClient() = platform.GrpcGreeterClientImpl;

  bool get isConnected;

  void connect({required String host, required int port, bool useTls = false});

  Future<String> sayHello(String name);

  Stream<String> sayHelloStream(String name);

  Future<void> disconnect();
}

/// 每个订阅者一个新客户端，不再被观察时自动断开连接。
final grpcGreeterClientProvider = Provider.autoDispose<GrpcGreeterClient>((
  ref,
) {
  final client = GrpcGreeterClient();
  ref.onDispose(client.disconnect);
  return client;
});
