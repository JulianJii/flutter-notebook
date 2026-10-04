import 'package:equatable/equatable.dart';

/// 一条待办（D2 的一行）。
///
/// ⛔ **不加** `dueDate` / `priority` / `reminderAt`：D2「无日期、无优先级」，
/// 「强提醒」是 `AppSettings` 的全局开关，**不是待办字段**。
/// ⛔ **不加** `sortIndex`（P2 无排序入口，排序固定 `createdAt DESC`，在 DAO 做）。
/// ⛔ **不加** `folderId`：待办与笔记无关联，D2 没有任何「关联笔记」入口。
/// ⛔ **不加** `deletedAt`（§5.4 末行「`Todo` 同理不加」）。
class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isDone = false,
  });

  final String id;

  final String title;

  /// D2 唯一的二元状态。
  final bool isDone;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// [isDone] 是非空 bool，`?? this.isDone` 即可 —— 哨兵只用于「显式置 null」。
  Todo copyWith({String? title, bool? isDone, DateTime? updatedAt}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, isDone, createdAt, updatedAt];
}
