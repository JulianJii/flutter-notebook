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

  /// 全量订阅，`createdAt DESC` 固定排序（D2 是平铺列表，无排序入口）。
  ///
  /// 三个「不」：**不加 `WHERE`**（`todos` 无 `deleted_at`，硬删除，CONFLICT-10
  /// 方案 A）、**不加排序参数**、**不加 `limit` / `offset` / 搜索 / 筛选**。
  ///
  /// ⚠️ 不加二级排序键：155 条数据顺序不稳定不构成问题。若将来用户抱怨，
  /// **先加索引再加二级键**。
  Stream<List<TodoRow>> watchAll() {
    return (select(
      todos,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
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

  /// 删除，返回受影响行数。**硬删除**。
  ///
  /// ⚠️ D2 **无删除入口**（Q21），本方法先备好能力，UI 端不接线。
  Future<int> deleteById(String todoId) {
    return (super.delete(todos)..where((t) => t.id.equals(todoId))).go();
  }
}
