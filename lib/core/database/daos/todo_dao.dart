import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/todos_table.dart';

part 'todo_dao.g.dart';

/// 待办的 SQL 与 watch 查询。
  ///
  /// ⛔ 不得 import `package:init/features/**`（`REPOSITORY-MAP.md` §5.3 的 R1）。
  /// 返回 `TodoRow`，不接收 `Todo` —— 转换在 `features/todos/data/datasources/`。
  /// ⚠️ **不 import `note_dao.dart` / `folder_dao.dart`** —— `todos` 表与它们
  /// 无任何关系，耦合只会让三个 DAO 互相牵制。
  @DriftAccessor(tables: [Todos])
  class TodoDao extends DatabaseAccessor<AppDatabase> with _$TodoDaoMixin {
  TodoDao(super.db);

  /// 全量订阅，未完成置顶、同组内 `createdAt DESC`。**不含回收站里的**。
  ///
  /// `isDone ASC` 让已完成沉到列表底部（待办的「已完成 N」折叠分组靠这条顺序免费
  /// 得到「已完成在后」，Screen 只切分不重排）。**不加 `limit` / 搜索 / 排序参数**
  /// —— 排序规则只有一种，给它开参数是纯仪式。
  ///
  /// ⚠️ `deleted_at IS NULL` 过滤**不可省**：漏了它，用户删掉的待办会继续留在
  /// 列表里（行还在库里，只是标了删除）。回收站走 [watchTrashed]。
  ///
  /// 三个「不」：**不加排序参数**、**不加 `limit` / `offset` / 搜索 / 筛选**。
  ///
  /// ⚠️ 不加索引：百级数据全表扫与现状同量级。若将来数据量让用户抱怨，
  /// **先加 `is_done, created_at` 复合索引再加排序入口**。
  Stream<List<TodoRow>> watchAll() {
    return (select(todos)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.isDone),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// 回收站列表：`deleted_at IS NOT NULL`，按删除时间倒序（与笔记回收站同序）。
  Stream<List<TodoRow>> watchTrashed() {
    return (select(todos)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.deletedAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// 插入。用 Companion 而非行对象：`is_done` 有默认值（false），Companion 天然
  /// 表达「哪些字段由数据库填默认值」。时间戳由调用方传入（DAO 不取时钟）。
  Future<TodoRow> insert(TodosCompanion row) {
    return into(todos).insertReturning(row);
  }

  /// 按 id **局部写入**，返回是否命中行。这是乐观更新与失败回滚的唯一入口
  /// （勾选 = 写目标 `isDone`；回滚 = 再写一次旧值）。
  ///
  /// ⛔ **不用 `replace()` 整行更新**：调用方得先读出完整行再写回，回滚还要再读
  /// 一次，且并发下会用旧快照覆盖别人的改动。
  /// ⛔ **不在 DAO 里翻转 `isDone`** —— 只写调用方给的目标值，避免重试时二次翻转。
  Future<bool> updateById(TodosCompanion row) {
    final id = row.id;
    if (!id.present) {
      throw ArgumentError('updateById 需要 Companion 里带 id');
    }
    return (super.update(todos)..where((t) => t.id.equals(id.value)))
        .write(row)
        .then((affected) => affected > 0);
  }

  /// 取一行。回收站「永久删除」要先确认它在回收站里。
  Future<TodoRow?> getById(String todoId) {
    return (select(todos)..where((t) => t.id.equals(todoId))).getSingleOrNull();
  }

  /// 软删除：写 `deleted_at`。**不刷 `updated_at`**（删除不是编辑），
  /// 传播靠 `max(updatedAt, deletedAt)`。
  Future<bool> markTrashed(String todoId, DateTime deletedAt) {
    return (super.update(todos)..where((t) => t.id.equals(todoId)))
        .write(TodosCompanion(deletedAt: Value(deletedAt)))
        .then((affected) => affected > 0);
  }

  /// 恢复：`deleted_at` 置 null + **刷 `updated_at`**。
  ///
  /// ⚠️ 必须刷，理由同 `NoteDao.restoreById`：合并比较键是
  /// `max(updatedAt, deletedAt)`，不刷的话恢复的 version 退回旧 `updatedAt`，
  /// 比远端的 `deletedAt` 还早 → 下次同步远端胜出，待办自己滚回回收站。
  /// 副作用：恢复的待办在 `createdAt DESC` 排序下位置不变（不刷 `createdAt`），
  /// 但它的 `updatedAt` 变新了 —— 这正是我们要的。
  Future<bool> markRestored(String todoId, DateTime restoredAt) {
    return (super.update(todos)..where((t) => t.id.equals(todoId))).write(
      TodosCompanion(deletedAt: const Value(null), updatedAt: Value(restoredAt)),
    ).then((affected) => affected > 0);
  }

  /// 物理删除，返回受影响行数。
  ///
  /// ⛔ **只由回收站的「永久删除」发起**：普通删除走 [markTrashed]，
  /// 否则删除不留痕、无法跨设备传播。
  Future<int> deleteById(String todoId) {
    return (super.delete(todos)..where((t) => t.id.equals(todoId))).go();
  }

  /// 清空回收站：物理删掉全部 `deleted_at IS NOT NULL` 的行，返回受影响行数。
  ///
  /// 单条 DELETE 而不是 N 次 [deleteById]：循环中途失败会留下删一半的
  /// 不可解释状态。命中 0 行**不抛**（= 已清空）。
  Future<int> deleteAllTrashed() {
    return (super
            .delete(todos)
          ..where((t) => t.deletedAt.isNotNull()))
        .go();
  }

  /// 批量**软删除**全部已完成，返回受影响行数。**单条 SQL**。
  ///
  /// 与 [deleteById] 的「命中 0 行 = 不存在」不同：这里 0 行就是「没有可清的项」
  /// （⛔ 不抛），上层据此决定要不要报错。
  ///
  /// ⚠️ `deleted_at IS NULL` 是必需的：`is_done = 1` 会连带命中**回收站里**的
  /// 已完成待办，不加这个条件会把它们的时间戳改写成「又删了一次」，
  /// 它们就会在回收站里「越来越新」，且再次同步时被当作刚删的。
  Future<int> trashCompleted(DateTime deletedAt) {
    return (super.update(
      todos,
    )..where((t) => t.isDone.equals(true) & t.deletedAt.isNull())).write(
      TodosCompanion(deletedAt: Value(deletedAt)),
    ).then((affected) => affected);
  }
}
