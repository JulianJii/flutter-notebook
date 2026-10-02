import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../utils/logger.dart';

/// [WebSocketClient] 连接的生命周期状态。
enum WebSocketConnectionState { disconnected, connecting, connected, error }

/// 一个轻量、可复用的 WebSocket 客户端。
///
/// 它被设计为通用的（不绑定到任何单一功能），以便在任何功能需要
/// 实时双向连接时复制/适配——实时聊天、在线状态、价格行情、
/// 协作编辑、服务器推送等。聊天功能（`features/chat`）展示了一个具体用例；
/// 此类展示了底层的可复用原语，包含重连机制和类型化的连接状态流。
class WebSocketClient {
  WebSocketClient({
    this.autoReconnect = true,
    this.reconnectDelay = const Duration(seconds: 2),
  });

  /// 是否在意外关闭后自动尝试重连。
  final bool autoReconnect;

  /// 每次重连尝试前的延迟。
  final Duration reconnectDelay;

  WebSocketChannel? _channel;
  Uri? _uri;
  StreamSubscription? _channelSubscription;
  Timer? _reconnectTimer;
  bool _manuallyClosed = false;

  final StreamController<dynamic> _messageController =
      StreamController<dynamic>.broadcast();
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  /// 从服务器接收的每条消息，保持原始格式
  ///（文本帧为 `String`，二进制帧为 `List<int>`）。
  Stream<dynamic> get messages => _messageController.stream;

  /// 连接生命周期变化。
  Stream<WebSocketConnectionState> get connectionState =>
      _stateController.stream;

  WebSocketConnectionState get state => _state;

  /// 打开到 [uri] 的连接。在 [disconnect] 后可以安全地再次调用；
  /// 如果已连接/正在连接到同一 uri，则为空操作。
  Future<void> connect(Uri uri) async {
    if (_channel != null && _uri == uri) return;

    _manuallyClosed = false;
    _uri = uri;
    _reconnectTimer?.cancel();
    _setState(WebSocketConnectionState.connecting);

    try {
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;
      _setState(WebSocketConnectionState.connected);

      _channelSubscription = channel.stream.listen(
        (data) {
          Logger.debug('WebSocket message: $data');
          _messageController.add(data);
        },
        onError: (Object error) {
          Logger.error('WebSocket stream error', error);
          _setState(WebSocketConnectionState.error);
          _scheduleReconnect();
        },
        onDone: () {
          Logger.info('WebSocket closed (code=${channel.closeCode})');
          _channel = null;
          if (!_manuallyClosed) {
            _setState(WebSocketConnectionState.disconnected);
            _scheduleReconnect();
          }
        },
      );
    } catch (e, st) {
      Logger.error('WebSocket connect failed', e, st);
      _setState(WebSocketConnectionState.error);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!autoReconnect || _manuallyClosed || _uri == null) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, () {
      if (!_manuallyClosed && _uri != null) connect(_uri!);
    });
  }

  /// 发送原始文本/二进制帧。
  void send(Object data) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('Cannot send: WebSocket is not connected.');
    }
    channel.sink.add(data);
  }

  /// 发送 JSON 可编码负载的便捷方法。
  void sendJson(Map<String, dynamic> data) => send(jsonEncode(data));

  /// 关闭连接并停止任何待处理的重连尝试。
  Future<void> disconnect() async {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    await _channelSubscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(WebSocketConnectionState.disconnected);
  }

  void _setState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// 释放所有资源。之后客户端无法重用。
  void dispose() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _channelSubscription?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _stateController.close();
  }
}

/// 每个订阅者一个新 [WebSocketClient]，不再被观察时自动释放。
final webSocketClientProvider = Provider.autoDispose<WebSocketClient>((ref) {
  final client = WebSocketClient();
  ref.onDispose(client.dispose);
  return client;
});
