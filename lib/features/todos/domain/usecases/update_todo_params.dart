import 'package:equatable/equatable.dart';
import 'package:mynote/features/todos/domain/entities/todo_priority.dart';
import 'package:mynote/features/todos/domain/entities/todo_recurrence.dart';

/// `UpdateTodoUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class UpdateTodoParams extends Equatable {
  const UpdateTodoParams({
    required this.todoId,
    required this.title,
    required this.isDone,
    required this.reminderAt,
    required this.priority,
    required this.recurrence,
    required this.linkedNoteId,
  });

  final String todoId;

  final String title;

  final bool isDone;

  /// 提醒时刻。⛔ **required** —— 强制调用方表态（传 `null` = 清除提醒），
  /// 因为 datasource 的 update 是全字段覆盖，漏了它「没传」会被读成「清空」。
  final DateTime? reminderAt;

  /// 优先级。同上：**required**，且非空 —— 漏传会让「改个标题」把优先级
  /// 静默重置成「普通」。这是一个不会报错、只会在几天后被用户发现的 bug，
  /// 用 required 把它挪到编译期。
  final TodoPriority priority;

  /// 重复规则。`null` = 清除重复。同 [priority]，required 是为了强制表态。
  final TodoRecurrence? recurrence;

  /// 挂接的笔记 id。`null` = 解除挂接。同 [priority]，required 是为了强制表态
  /// —— 漏传会被全字段覆盖写成「解除挂接」。
  final String? linkedNoteId;

  @override
  List<Object?> get props => [
    todoId,
    title,
    isDone,
    reminderAt,
    priority,
    recurrence,
    linkedNoteId,
  ];
}
