import 'package:drift/drift.dart';

import 'todos_table.dart';

/// 待办的子项（一条待办下的勾选清单）。
///
/// ## 为什么是独立表而不是 todos 上的一个数组列
///
/// SQLite 没有数组列。塞进 `todos.title` 之类的文本列意味着每次勾一个子项
/// 都要读出整条、改、再写回 —— 并发下会用旧快照覆盖别人的改动，而且子项
/// 自己没有 id，勾选状态就没法跨设备合并。
///
/// ## 删除语义
///
/// - 待办**软删除**（进回收站）：子项**跟着隐藏**，不单独写 `deleted_at`。
///   它们在快照里照常出现（父待办的 `deletedAt` 已经说明了整条的状态），
///   恢复时自然一起回来 —— 不需要第二套状态。
/// - 待办**物理清扫**（墓碑过期）：`ON DELETE CASCADE` 连带删掉子项。
///   那时子项早已无人问津 30 天以上。
/// - 子项**没有回收站** ⛔：它是待办的从属数据，没有「单独找回一个子项」
///   这个用户场景。为它做回收站要新增一整段 UI，收益为零。
///
/// ⚠️ **子项必须进同步快照**（`BackupTodoSubtask`）：不同步的话，A 机勾掉的
/// 子项会在 B 机同步后变回没勾 —— 那是「丢数据」，而本 App 的第一原则是永不
/// 丢数据。
@DataClassName('TodoSubtaskRow')
@TableIndex(name: 'idx_todo_subtasks_todo_id', columns: {#todoId})
class TodoSubtasks extends Table {
  @override
  String get tableName => 'todo_subtasks';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  /// 所属待办。`ON DELETE CASCADE` 只在父待办**物理删除**时触发（软删除不触发，
  /// 符合「子项跟着父待办隐藏、恢复时一起回来」的语义）。
  TextColumn get todoId => text().references(Todos, #id, onDelete: KeyAction.cascade)();

  TextColumn get title => text()();

  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  /// **合并比较键**用的时间戳。勾选是一次变更，必须刷 —— 不刷的话 A 机勾完
  /// 同步过去，B 机那条 `updatedAt` 更老，会被判成本地胜出并把勾选抹掉。
  DateTimeColumn get updatedAt => dateTime()();
}