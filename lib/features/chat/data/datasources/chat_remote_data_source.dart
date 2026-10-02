import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:init/features/chat/data/models/message_model.dart';
import 'package:init/core/utils/logger.dart';

abstract class ChatRemoteDataSource {
  Stream<MessageModel> get messages;
  Future<void> connect();
  Future<void> sendMessage(String message);
  void disconnect();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  WebSocketChannel? _channel;
  final StreamController<MessageModel> _messageController =
      StreamController<MessageModel>.broadcast();

  // 如果 echo.websocket.org 不可用，可改用 postman-echo 等类似服务
  // wss://echo.websocket.org 通常不稳定。
  // 使用 wss://echo.websocket.events/.ws
  static const String _socketUrl = 'wss://echo.websocket.events/.ws';

  @override
  Stream<MessageModel> get messages => _messageController.stream;

  @override
  Future<void> connect() async {
    try {
      if (_channel != null) return;

      final uri = Uri.parse(_socketUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          Logger.debug('WebSocket received: $data');
          // 该服务器会返回简单的文本回显
          if (data is String) {
            _messageController.add(MessageModel.fromText(data));
          }
        },
        onError: (error) {
          Logger.error('WebSocket error', error);
          // 重连逻辑可放在这里
        },
        onDone: () {
          Logger.info('WebSocket closed');
          _channel = null;
        },
      );
    } catch (e) {
      Logger.error('WebSocket Connection Failed', e);
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(String message) async {
    if (_channel == null) {
      await connect();
    }
    _channel?.sink.add(message);
  }

  @override
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _messageController.close();
  }
}
