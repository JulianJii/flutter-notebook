import 'package:equatable/equatable.dart';

/// 一条待办（待办稿的一行）。
///
/// ⛔ **不加** `dueDate` / `priority`：待办稿「无日期、无优先级」。
/// ⚠️ **`reminderAt` 是提醒的时刻，不是截止日期** —— 命名上刻意避开 `dueAt`，
/// 免得被当成待办稿明确否掉的「截止日」重新长回实体里。
/// ⛔ **不加** `sortIndex`（待办无排序入口，排序固定 `createdAt DESC`，在 DAO 做）。
/// ⛔ **不加** `folderId`：待办与笔记无关联，待办稿没有任何「关联笔记」入口。
///
/// ## `deletedAt`：曾经明确不加，现在加
///
/// §5.4 末行原写「`Todo` 同理不加（硬删除）」，该裁决已翻转 —— 删除必须能
/// **跨设备传播**，硬删除不留痕，A 机删掉的待办会在 B 机下次同步时原样回来。
/// 软删除与 `notes` 同形，是当时那轮「全支持删除传播」的唯一解。
class Todo extends Equatable {
  const Todo({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isDone = false,
    this.reminderAt,
    this.deletedAt,
  });

  final String id;

  final String title;

  /// 待办稿唯一的二元状态。
  final bool isDone;

  /// 提醒时刻，null = 没设提醒。
  final DateTime? reminderAt;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 软删除时刻。null = 正常待办；非 null = 在回收站里。
  ///
  /// ⛔ **不参与 [copyWith]**：回收站相关的写入全部由 `TodoLocalDataSource`
  /// 直连 DAO 完成，没有「先在内存里改实体再落库」的路径。加一个没人调用的
  /// 参数就是第二套真相源。
  final DateTime? deletedAt;

  /// [isDone] 是非空 bool，`?? this.isDone` 即可 —— 哨兵只用于「显式置 null」。
  ///
  /// [reminderAt] 反过来：它是可空的，`copyWith(reminderAt: null)` 必须真的把提醒
  /// 清掉（「清除提醒」按钮就靠这个），所以走 [reminderUnset] 哨兵 —— 与
  /// `AppSettings.copyWith(locale)` 同一套写法。
  Todo copyWith({
    String? title,
    bool? isDone,
    DateTime? updatedAt,
    Object? reminderAt = reminderUnset,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderAt: identical(reminderAt, reminderUnset)
          ? this.reminderAt
          : reminderAt as DateTime?,
      deletedAt: deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    isDone,
    reminderAt,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

/// [Todo.copyWith] 的哨兵：`copyWith(reminderAt: null)` 必须**真的**清掉提醒。
const Object reminderUnset = Object();
