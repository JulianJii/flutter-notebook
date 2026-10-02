import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:init/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:init/features/chat/domain/repositories/chat_repository.dart';
import 'package:init/features/chat/domain/usecases/observe_messages_use_case.dart';
import 'package:init/features/chat/domain/usecases/send_message_use_case.dart';

/// 数据层依赖注入 providers
/// 这些 providers 负责创建和管理数据层实例

// --- 数据源 ---
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl();
});

// --- 仓库 ---
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
});

// --- 用例 ---
final observeMessagesUseCaseProvider = Provider<ObserveMessagesUseCase>((ref) {
  return ObserveMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});
