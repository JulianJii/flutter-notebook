import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/todo_subtasks_table.dart';

part 'todo_subtask_dao.g.dart';

/// 子任务的 SQL 与 watch 查询。
///
/// ⚠️ **不 import `todo_dao.dart`** —— 两张表是「父 → 从属」，但没有查询上的
/// 互相依赖，耦合只会让两个 DAO 互相牵制（与 `folder_dao` / `note_dao` 同一约定）。
@DriftAccessor(tables: [TodoSubtasks])
class TodoSubtaskDao extends DatabaseAccessor<AppDatabase>
    with _$TodoSubtaskDaoMixin {
  TodoSubtaskDao(super.db);

  /// 某条待办的全部子项，按**加入顺序**（`created_at ASC`）。
  ///
  /// ⛔ **不过滤待办的 `deleted_at`**：软删除的待办它的子项也要能查到 ——
  /// 回收站里的待办恢复后，子项必须原样回来（见 `todo_subtasks_table.dart`）。
  /// 「跟着父待办隐藏」是 UI 层的决定（父不可见就不渲染子项），不是数据层的。
  Stream<List<TodoSubtaskRow>> watchByTodo(String todoId) {
    return (select(todoSubtasks)
          ..where((t) => t.todoId.equals(todoId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// 全量读（**同步用**）。⛔ 不加任何过滤 —— 子项必须跟着墓碑一起进快照，
  /// 否则 B 机同步后子项会凭空消失，那和「A 机勾掉的勾又被抹掉」是同一类丢数据。
  Future<List<TodoSubtaskRow>> selectAll() => select(todoSubtasks).get();

  Future<TodoSubtaskRow?> getById(String subtaskId) {
    return (select(
      todoSubtasks,
    )..where((t) => t.id.equals(subtaskId))).getSingleOrNull();
  }

  Future<TodoSubtaskRow> insert(TodoSubtasksCompanion row) {
    return into(todoSubtasks).insertReturning(row);
  }

  /// 按 id **局部写入**，返回是否命中行。勾选子项走这里。
  Future<bool> updateById(TodoSubtasksCompanion row) {
    final id = row.id;
    if (!id.present) {
      throw ArgumentError('updateById 需要 Companion 里带 id');
    }
    return (super.update(todoSubtasks)..where((t) => t.id.equals(id.value)))
        .write(row)
        .then((affected) => affected > 0);
  }

  /// 物理删除子项。**没有软删除** —— 子项没有回收站（见表的类注释）。
  Future<int> deleteById(String subtaskId) {
    return (super.delete(todoSubtasks)..where((t) => t.id.equals(subtaskId)))
        .go();
  }

  /// 删掉某条待办的全部子项。父待办**物理清扫**时由外键 CASCADE 处理，这条
  /// 给的是「删子项」这个独立入口（编辑弹窗里删掉某一条）。
  Future<int> deleteByTodo(String todoId) {
    return (super
            .delete(todoSubtasks)
          ..where((t) => t.todoId.equals(todoId)))
        .go();
  }
}