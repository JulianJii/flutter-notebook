import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_folders_table.dart';
import '../tables/notes_table.dart';

part 'folder_dao.g.dart';

/// 文件夹的 SQL 与 watch 查询。
///
/// ⛔ 不得 import `package:init/features/**`（`REPOSITORY-MAP.md` §5.3 的 R1）。
/// 返回行对象与标量；`FolderWithCount` 的组装在 datasource（`TASK-021`）。
/// ⚠️ **不 import `note_dao.dart`** —— 两个 DAO 之间不耦合，P4 的改动不能影响 P1。
@DriftAccessor(tables: [NoteFolders, Notes])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db);

  /// 文件夹 + 其下笔记数，一条 `LEFT JOIN + GROUP BY`（**不是** N+1）。
  ///
  /// ⚠️ **必须 LEFT OUTER**：0 条笔记的文件夹在 INNER JOIN 下会整行消失 ——
  /// 用户新建的文件夹在列表里看不到，极难排查。故 [TypedResult.read] 的
  /// `?? 0` 兜底不可省。
  ///
  /// ⚠️ 结果里**不含**「全部」与「未分类」两行（§5.3：不是表里的行）。
  /// `// TODO(Q18): 若产品判定「未分类」是真实文件夹，插入一条系统行并在 UI
  /// 层映射，业务层不动。`
  ///
  /// 排序固定 `createdAt ASC`（设计稿无排序入口）。
  Stream<List<FolderWithCountRow>> watchWithCounts() {
    final count = notes.id.count();
    final query =
        select(noteFolders).join([
            leftOuterJoin(notes, notes.folderId.equalsExp(noteFolders.id)),
          ])
          ..addColumns([count])
          ..groupBy([noteFolders.id])
          ..orderBy([OrderingTerm.asc(noteFolders.createdAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => FolderWithCountRow(
              folder: row.readTable(noteFolders),
              count: row.read(count) ?? 0,
            ),
          )
          .toList(),
    );
  }

  /// 「未分类」计数（`folder_id IS NULL`）。D4 的「未分类 154」就是它。
  ///
  /// ⛔ **不提供 `watchTotalCount()`**：`全部 = sum(各文件夹) + 未分类` 是恒等式，
  /// P4 的 provider 里 1 行求和即可，多发一条 SQL 换可推导的值是纯浪费。
  Stream<int> watchUncategorizedCount() {
    final count = notes.id.count();
    return (selectOnly(notes)
          ..addColumns([count])
          ..where(notes.folderId.isNull()))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// 插入。时间戳由调用方通过 Companion 传入（DAO 不取时钟）。
  Future<NoteFolderRow> insert(NoteFoldersCompanion row) {
    return into(noteFolders).insertReturning(row);
  }

  /// 重命名，返回是否命中行。文件夹不存在时返回 `false`。
  ///
  /// **不预先 SELECT 查重**：一次 UPDATE 让 SQLite 的 UNIQUE 索引判重 ——
  /// 查重 + 更新 = 两次查询 + 一个竞态窗口。冲突时 drift 抛 `SqliteException`
  /// （原样透出，由 datasource / Repository 映射成 `Left(InputFailure)`）。
  ///
  /// ⚠️ `updatedAt` 由调用方放进 Companion，本方法**不**刷新它（与 `NoteDao` 同理：
  /// 刷新时间戳是业务语义，且测试要能注入固定时间）。
  Future<bool> rename(String folderId, NoteFoldersCompanion row) {
    return (super.update(noteFolders)..where((t) => t.id.equals(folderId)))
        .write(row)
        .then((affected) => affected > 0);
  }

  /// 删文件夹行，返回受影响行数。
  ///
  /// ⚠️ 与 [nullOutFolder] 一起放进同一个 `db.transaction()`，事务在
  /// `TASK-021` 的 datasource 包（`REPOSITORY-MAP.md` §2.2）。DAO 内部**不开**
  /// 事务 —— 边界散落在 DAO 里，上层无法推理。
  Future<int> deleteById(String folderId) {
    return (super.delete(
      noteFolders,
    )..where((t) => t.id.equals(folderId))).go();
  }

  /// 把某文件夹下全部笔记的 `folder_id` 置 NULL。
  ///
  /// 与 [deleteById] 的外键 `ON DELETE SET NULL` 冗余但**显式**：不把原子性寄托
  /// 在某个 drift / SQLite 版本的外键行为上（Q37 问的正是这个）。
  Future<int> nullOutFolder(String folderId) {
    return (super.update(notes)..where((t) => t.folderId.equals(folderId)))
        .write(const NotesCompanion(folderId: Value(null)))
        .then((affected) => affected);
  }
}

/// DAO 的行级输出：一个文件夹行 + 它的笔记数。**不是**数据库表。
///
/// 定义在 core（而非 domain 的 `FolderWithCount`）是因为它承载的是 drift 行
/// 对象 —— `NoteFolderRow`。domain → DAO 的转换在 datasource。
class FolderWithCountRow {
  const FolderWithCountRow({required this.folder, required this.count});

  final NoteFolderRow folder;

  final int count;

  @override
  String toString() => 'FolderWithCountRow(${folder.id}: $count)';
}
