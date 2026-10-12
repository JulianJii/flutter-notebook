import 'package:equatable/equatable.dart';
import 'package:mynote/features/todos/domain/entities/todo_priority.dart';
import 'package:mynote/features/todos/domain/entities/todo_recurrence.dart';

/// 一条待办（待办稿的一行）。
///
/// ⛔ **不加** `dueDate`：待办稿明确否掉了「截止日」。
/// ⚠️ **`reminderAt` 是提醒的时刻，不是截止日期** —— 命名上刻意避开 `dueAt`，
/// 免得被当成待办稿明确否掉的「截止日」重新长回实体里。
/// ✅ **加了** `priority` / `recurrence`：这两项是对「待办稿那版只有标题和完成态」
/// 的后续补充（见 `TodoPriority` / `TodoRecurrence`）。
/// ⛔ **不加** `sortIndex`（排序固定，在 DAO 做）。
/// ⛔ **不加** `folderId`：待办与笔记无关联，待办稿没有任何「关联笔记」入口。
///
/// ## `deletedAt`：曾经明确不加，现在加
///
/// 曾经写过「`Todo` 同理不加（硬删除）」，该裁决已翻转 —— 删除必须能
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
    this.purgedAt,
    this.priority = TodoPriority.normal,
    this.recurrence,
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

  /// 永久删除墓碑时刻。**UI 与业务逻辑都不看它** —— 只活在数据层与同步链路里，
  /// 让「永久删除」能跨设备传播。与 [deletedAt] 同样不参与 [copyWith]。
  final DateTime? purgedAt;

  /// 优先级。列表排序里在「未完成 / 已完成」**之内**再按它分层。
  ///
  /// ⚠️ 优先级**不参与** [copyWith]：它与 [deletedAt] 一样只由
  /// `TodoLocalDataSource` 直连 DAO 写（要连带写 `updated_at`，而勾选/删除
  /// 路径不该顺带改优先级），没有「先在内存里改实体再落库」的路径。
  final TodoPriority priority;

  /// 重复提醒规则。null = 不重复。
  ///
  /// ⚠️ 同 [priority]：不参与 [copyWith]。
  final TodoRecurrence? recurrence;

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
      purgedAt: purgedAt,
      priority: priority,
      recurrence: recurrence,
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
    purgedAt,
    priority,
    recurrence,
  ];
}

/// [Todo.copyWith] 的哨兵：`copyWith(reminderAt: null)` 必须**真的**清掉提醒。
const Object reminderUnset = Object();
