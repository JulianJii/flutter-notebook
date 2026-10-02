import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/integrations/websocket_client.dart';

/// 演示可复用的 [WebSocketClient]：连接、发送、接收和自动重连，
/// 针对公共的回显服务器。
///
/// 将 `core/network/integrations/websocket_client.dart` 复制到你的功能模块中，
/// 并指向你自己的服务器以复用此模式（实时聊天、在线状态、通知、价格行情、协作编辑...）
class WebSocketExampleScreen extends ConsumerStatefulWidget {
  const WebSocketExampleScreen({super.key});

  static const _echoServerUrl = 'wss://echo.websocket.events/.ws';

  @override
  ConsumerState<WebSocketExampleScreen> createState() =>
      _WebSocketExampleScreenState();
}

class _WebSocketExampleScreenState
    extends ConsumerState<WebSocketExampleScreen> {
  final _controller = TextEditingController();
  final _log = <_LogEntry>[];
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _appendLog(String text, {required bool outgoing}) {
    setState(() => _log.add(_LogEntry(text, outgoing: outgoing)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(webSocketClientProvider);

    ref.listen<AsyncValue<dynamic>>(_incomingMessageProvider(client), (
      previous,
      next,
    ) {
      next.whenData((message) => _appendLog('$message', outgoing: false));
    });

    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket example')),
      body: Column(
        children: [
          _ConnectionBar(client: client),
          const Divider(height: 1),
          Expanded(
            child: _log.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _log.length,
                    itemBuilder: (context, index) {
                      final entry = _log[index];
                      return Align(
                        alignment: entry.outgoing
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: entry.outgoing
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(entry.text),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Message to send',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(client),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: client.state == WebSocketConnectionState.connected
                      ? () => _send(client)
                      : null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send(WebSocketClient client) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    client.send(text);
    _appendLog(text, outgoing: true);
    _controller.clear();
  }
}

/// 将客户端的连接状态流桥接到带有连接/断开控制的小型状态栏。
class _ConnectionBar extends StatelessWidget {
  const _ConnectionBar({required this.client});

  final WebSocketClient client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WebSocketConnectionState>(
      stream: client.connectionState,
      initialData: client.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? WebSocketConnectionState.disconnected;
        final isConnected = state == WebSocketConnectionState.connected;
        final isConnecting = state == WebSocketConnectionState.connecting;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _StatusChip(state: state),
              const Spacer(),
              if (isConnecting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                FilledButton.tonal(
                  onPressed: () {
                    if (isConnected) {
                      client.disconnect();
                    } else {
                      client.connect(
                        Uri.parse(WebSocketExampleScreen._echoServerUrl),
                      );
                    }
                  },
                  child: Text(isConnected ? 'Disconnect' : 'Connect'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.state});

  final WebSocketConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      WebSocketConnectionState.connected => ('Connected', Colors.green),
      WebSocketConnectionState.connecting => ('Connecting…', Colors.orange),
      WebSocketConnectionState.error => ('Error', Colors.red),
      WebSocketConnectionState.disconnected => ('Disconnected', Colors.grey),
    };
    return Chip(
      label: Text(label),
      avatar: CircleAvatar(backgroundColor: color),
    );
  }
}

class _LogEntry {
  _LogEntry(this.text, {required this.outgoing});
  final String text;
  final bool outgoing;
}

/// 将客户端的广播 [WebSocketClient.messages] 流适配为每个 widget 的 provider，
/// 这样 `ref.listen` 可以驱动日志，而无需屏幕管理自己的 StreamSubscription。
final _incomingMessageProvider = StreamProvider.autoDispose
    .family<dynamic, WebSocketClient>((ref, client) => client.messages);
