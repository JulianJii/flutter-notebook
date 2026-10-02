import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/integrations/grpc/greeter_client.dart';

/// 演示通过可复用的 [GrpcGreeterClient] 进行一元调用和服务端流式 gRPC 调用：
/// - 一元 `SayHello` 默认使用公共的 `grpcb.in:9000` 测试服务器
///   （经典的 helloworld.Greeter 示例），无需设置即可工作。
/// - 服务端流式 `SayHelloStream` 需要本地运行 `tool/grpc_demo_server.dart`
///   （`dart run tool/grpc_demo_server.dart`）；默认主机设置为 `localhost:50051`。
///
/// 将 `core/network/integrations/grpc/` 复制到真实的功能模块中，
/// 并将 `greeter.proto` 替换为你自己的服务契约以复用此模式。
class GrpcExampleScreen extends ConsumerStatefulWidget {
  const GrpcExampleScreen({super.key});

  @override
  ConsumerState<GrpcExampleScreen> createState() => _GrpcExampleScreenState();
}

class _GrpcExampleScreenState extends ConsumerState<GrpcExampleScreen> {
  final _hostController = TextEditingController(text: 'grpcb.in');
  final _portController = TextEditingController(text: '9000');
  final _nameController = TextEditingController(text: 'World');

  bool _busy = false;
  String? _unaryResult;
  final _streamResults = <String>[];
  Object? _error;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _connect(GrpcGreeterClient client) {
    client.connect(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 9000,
    );
  }

  Future<void> _callUnary(GrpcGreeterClient client) async {
    setState(() {
      _busy = true;
      _error = null;
      _unaryResult = null;
    });
    try {
      _connect(client);
      final reply = await client.sayHello(_nameController.text);
      setState(() => _unaryResult = reply);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _callStream(GrpcGreeterClient client) async {
    setState(() {
      _busy = true;
      _error = null;
      _streamResults.clear();
    });
    try {
      _connect(client);
      await for (final reply in client.sayHelloStream(_nameController.text)) {
        if (!mounted) return;
        setState(() => _streamResults.add(reply));
      }
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(grpcGreeterClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('gRPC example')),
      body: kIsWeb
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'gRPC over a raw HTTP/2 socket is not available on web. '
                'Run this demo on desktop or mobile, or add a grpc-web '
                'proxy in front of your server.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _callUnary(client),
                      icon: const Icon(Icons.call_made),
                      label: const Text('Call SayHello (unary)'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _callStream(client),
                      icon: const Icon(Icons.stream),
                      label: const Text(
                        'Call SayHelloStream (needs local server)',
                      ),
                    ),
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Call failed: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (_unaryResult != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(_unaryResult!),
                    ),
                  ),
                ],
                if (_streamResults.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Streamed replies:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final reply in _streamResults)
                    ListTile(dense: true, title: Text(reply)),
                ],
              ],
            ),
    );
  }
}
