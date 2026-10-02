import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/chat/domain/entities/message_entity.dart';
import 'package:init/features/chat/providers/chat_providers.dart';

/// 表现层状态管理
/// 本文件只包含与 UI 相关的 state providers

// --- 状态管理 ---
class ChatState {
  final List<MessageEntity> messages;
  final bool isConnected;

  const ChatState({this.messages = const [], this.isConnected = false});

  ChatState copyWith({List<MessageEntity>? messages, bool? isConnected}) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    // 自动连接并监听
    _listenToMessages();

    return const ChatState(isConnected: true);
  }

  void _listenToMessages() {
    // 真实应用中需谨慎管理订阅
    final observeMessages = ref.read(observeMessagesUseCaseProvider);
    observeMessages().listen((message) {
      state = state.copyWith(messages: [...state.messages, message]);
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;

    // 乐观更新：立即添加我的消息
    final myMessage = MessageEntity(
      id: DateTime.now().toIso8601String(),
      text: text,
      sender: 'Me',
      timestamp: DateTime.now(),
      isMe: true,
    );

    state = state.copyWith(messages: [...state.messages, myMessage]);

    // 发送到服务器
    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
    await sendMessageUseCase(text);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
