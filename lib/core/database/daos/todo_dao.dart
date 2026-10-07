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

  /// 全量订阅，未完成置顶、同组内 `createdAt DESC`。
  ///
  /// `isDone ASC` 让已完成沉到列表底部（待办的「已完成 N」折叠分组靠这条顺序免费
  /// 得到「已完成在后」，Screen 只切分不重排）。**不加 `limit` / 搜索 / 排序参数**
  /// —— 排序规则只有一种，给它开参数是纯仪式。
  ///
  /// 三个「不」：**不加 `WHERE`**（`todos` 无 `deleted_at`，硬删除，CONFLICT-10
  /// 方案 A）、**不加排序参数**、**不加 `limit` / `offset` / 搜索 / 筛选**。
  ///
  /// ⚠️ 不加索引：百级数据全表扫与现状同量级。若将来数据量让用户抱怨，
  /// **先加 `is_done, created_at` 复合索引再加排序入口**。
  Stream<List<TodoRow>> watchAll() {
    return (select(todos)..orderBy([
          (t) => OrderingTerm.asc(t.isDone),
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

  /// 删除，返回受影响行数。**硬删除**。
  Future<int> deleteById(String todoId) {
    return (super.delete(todos)..where((t) => t.id.equals(todoId))).go();
  }

  /// 批量清除已完成，返回受影响行数。**单条 SQL / 单事务** —— 比 N 次单删快，
  /// 且不会像「循环调 [deleteById]」那样中途失败留下删一半的不可解释状态。
  ///
  /// ⛔ **不抛 0 行**：没有可清的项就是「已清空」，与 [deleteById] 的
  /// 「命中 0 行 = 该 todo 不存在」语义不同（上层据此决定要不要报错）。
  Future<int> deleteCompleted() {
    return (super.delete(todos)..where((t) => t.isDone.equals(true))).go();
  }
}
