import 'package:equatable/equatable.dart';

/// `UpdateTodoUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class UpdateTodoParams extends Equatable {
  const UpdateTodoParams({
    required this.todoId,
    required this.title,
    required this.isDone,
  });

  final String todoId;

  final String title;

  final bool isDone;

  @override
  List<Object?> get props => [todoId, title, isDone];
}
