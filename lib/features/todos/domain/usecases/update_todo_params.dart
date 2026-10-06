import 'package:equatable/equatable.dart';

/// `UpdateTodoUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class UpdateTodoParams extends Equatable {
  const UpdateTodoParams({
    required this.todoId,
    required this.title,
    required this.isDone,
    required this.reminderAt,
  });

  final String todoId;

  final String title;

  final bool isDone;

  /// 提醒时刻。⚠️ `required` 而非可选：datasource 的 update 是全字段写入，
  /// 漏传会把用户已经设好的提醒抹掉（传 `null` = 明确清除）。
  final DateTime? reminderAt;

  @override
  List<Object?> get props => [todoId, title, isDone, reminderAt];
}
