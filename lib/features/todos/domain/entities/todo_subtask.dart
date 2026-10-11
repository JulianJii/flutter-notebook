import 'package:equatable/equatable.dart';

/// 一条待办下的子项。
///
/// ⛔ **没有回收站**：它是待办的从属数据，「单独找回一个子项」没有用户场景
/// （见 `todo_subtasks_table.dart` 的类注释）。
/// ⛔ **没有排序位**：子项按 `created_at ASC` 展示即用户加入的顺序；要拖拽排序
/// 得给待办也加一套，那是另一个需求。
class TodoSubtask extends Equatable {
  const TodoSubtask({
    required this.id,
    required this.todoId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isDone = false,
  });

  final String id;

  /// 所属待办。
  final String todoId;

  final String title;

  final bool isDone;

  final DateTime createdAt;

  /// 勾选会刷新它 —— 这是跨设备合并子项勾选状态的唯一依据。
  final DateTime updatedAt;

  TodoSubtask copyWith({
    String? title,
    bool? isDone,
    DateTime? updatedAt,
  }) {
    return TodoSubtask(
      id: id,
      todoId: todoId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, todoId, title, isDone, createdAt, updatedAt];
}