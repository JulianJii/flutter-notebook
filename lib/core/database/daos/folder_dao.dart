import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_folders_table.dart';
import '../tables/notes_table.dart';

part 'folder_dao.g.dart';

/// 文件夹的 SQL 与 watch 查询。
///
/// ⛔ 不得 import `package:init/features/**`（`REPOSITORY-MAP.md` §5.3 的 R1）。
/// 返回行对象与标量；`FolderWithCount` 的组装在 datasource（`TASK-021`）。
/// ⚠️ **不 import `note_dao.dart`** —— 两个 DAO 之间不耦合，文件夹管理的改动不能影响笔记列表。
@DriftAccessor(tables: [NoteFolders, Notes])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db);

  /// 文件夹 + 其下笔记数，一条 `LEFT JOIN + GROUP BY`（**不是** N+1）。
  ///
  /// ⚠️ **必须 LEFT OUTER**：0 条笔记的文件夹在 INNER JOIN 下会整行消失 ——
  /// 用户新建的文件夹在列表里看不到，极难排查。故 [TypedResult.read] 的
  /// `?? 0` 兜底不可省。
  ///
  /// ⚠️ 结果里**不含**「全部」与「未分类」两行（§5.3：不是表里的行）；
  /// 「未分类」是筛选哨兵（`kFolderFilterUncategorized`），不是系统行。
  ///
  /// ⚠️ 分类 tab 的顺序真相源就在下面的 `ORDER BY`：全部恒首位、未分类恒最后，
  /// 中间的文件夹按 `sortIndex / createdAt` 排。改顺序只改这里。
  ///
  /// 排序 `sortIndex ASC, createdAt ASC`（文件夹管理拖拽排序；`createdAt` 只作同值兜底，
  /// 让迁移后全是默认 0 的老数据保持原顺序）。
  Stream<List<FolderWithCountRow>> watchWithCounts() {
    final count = notes.id.count();
    final query =
        select(noteFolders).join([
            // 软删除过滤：回收站里的笔记不计入文件夹数（与列表同一视图）。
            leftOuterJoin(
              notes,
              Expression.and([
                notes.folderId.equalsExp(noteFolders.id),
                notes.deletedAt.isNull(),
              ]),
            ),
          ])
          ..addColumns([count])
          ..groupBy([noteFolders.id])
          // ⚠️ 回收站里的文件夹要**整行消失**，所以过滤加在左表（outer select）
          // 上，**不能**塞进上面 join 的 `Expression.and` —— LEFT JOIN 的谓词只
          // 作用于右表，把条件放那儿只会把 count 置空，文件夹行照样显示。
          // 这个位置写错不会报错、不会崩，只是静默地继续显示已删文件夹。
          ..where(noteFolders.deletedAt.isNull())
          ..orderBy([
            OrderingTerm.asc(noteFolders.sortIndex),
            OrderingTerm.asc(noteFolders.createdAt),
          ]);

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

  /// 「未分类」计数（`folder_id IS NULL`）。文件夹管理稿的「未分类 154」就是它。
  ///
  /// ⛔ **不提供 `watchTotalCount()`**：`全部 = sum(各文件夹) + 未分类` 是恒等式，
  /// 文件夹管理的 provider 里 1 行求和即可，多发一条 SQL 换可推导的值是纯浪费。
  Stream<int> watchUncategorizedCount() {
    final count = notes.id.count();
    return (selectOnly(notes)
          ..addColumns([count])
          ..where(notes.folderId.isNull())
          ..where(notes.deletedAt.isNull()))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// 插入。时间戳由调用方通过 Companion 传入（DAO 不取时钟）。
  ///
  /// `sort_index` 由本方法填成 `MAX+1` → 新文件夹**永远排末尾**，调用方不用管
  /// 排位。读 + 写不在一个事务里：并发新建拿到同一个值时，`createdAt` 兜底
  /// 仍给出确定顺序（单用户 App，不为它开事务）。
  Future<NoteFolderRow> insert(NoteFoldersCompanion row) async {
    final maxIndex = noteFolders.sortIndex.max();
    final current = await (selectOnly(
      noteFolders,
    )..addColumns([maxIndex])).map((r) => r.read(maxIndex)).getSingle();
    return into(
      noteFolders,
    ).insertReturning(row.copyWith(sortIndex: Value((current ?? -1) + 1)));
  }

  /// 按给定顺序整表重排：把每个 id 的 `sort_index` 写成 `0..n-1`。
  ///
  /// 顺序的**真相**是这一条命令（`orderedIds` 就是 UI 上的最终顺序），
  /// 不用增量交换 —— 一次 `batch`，不会留下半新半旧的顺序。
  /// 未知 id 静默跳过（`batch` 里 update 命中 0 行不是错误）。
  Future<void> updateSortIndexes(List<String> orderedIds) async {
    if (orderedIds.isEmpty) {
      return;
    }
    await batch((b) {
      for (var i = 0; i < orderedIds.length; i++) {
        b.update(
          noteFolders,
          NoteFoldersCompanion(sortIndex: Value(i)),
          where: (t) => t.id.equals(orderedIds[i]),
        );
      }
    });
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

  /// 删文件夹行（**物理**），返回受影响行数。
///
/// ⛔ **只由回收站的「永久删除」发起**：普通删除走 [markTrashed]（软删除），
/// 否则删除不留痕、无法跨设备传播。
///
/// ⚠️ 与 [nullOutFolder] 一起放进同一个 `db.transaction()`，事务在
/// `TASK-021` 的 datasource 包（`REPOSITORY-MAP.md` §2.2）。DAO 内部**不开**
/// 事务 —— 边界散落在 DAO 里，上层无法推理。
Future<int> deleteById(String folderId) {
    return (super.delete(
      noteFolders,
    )..where((t) => t.id.equals(folderId))).go();
  }

  /// 清空回收站：物理删掉全部 `deleted_at IS NOT NULL` 的行，返回受影响行数。
  ///
  /// 单条 DELETE 而不是 N 次 [deleteById]：循环中途失败会留下删一半的
  /// 不可解释状态。命中 0 行**不抛**（= 已清空）。
  Future<int> deleteAllTrashed() {
    return (super
            .delete(noteFolders)
          ..where((t) => t.deletedAt.isNotNull()))
        .go();
  }

  /// 取一行。软删除流程要先读出当前 `name` 才能算出让出版，所以需要它。
  Future<NoteFolderRow?> getById(String folderId) {
    return (select(
      noteFolders,
    )..where((t) => t.id.equals(folderId))).getSingleOrNull();
  }

  /// 回收站列表：`deleted_at IS NOT NULL`，按删除时间倒序（与笔记回收站同序）。
  ///
  /// ⛔ **没有**「把活文件夹也列进来」的变体：列表视图有且只有两态，
  /// 混在一起会让「文件夹管理」和「回收站」互相漏数据。
  Stream<List<NoteFolderRow>> watchTrashed() {
    return (select(noteFolders)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.deletedAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// 软删除写入：**改名让出原名** + 写 `deleted_at`。
  ///
  /// ⚠️ `name` 由调用方用 [trashedFolderName] 算好传进来，DAO **不读行、不取
  /// 时钟** —— 读-改-写的事务边界在 datasource（与 [deleteById] 同一约定）。
  /// ⚠️ 不刷 `updated_at`：删除不是编辑，靠 `max(updatedAt, deletedAt)` 传播。
  Future<bool> markTrashed(
    String folderId,
    String trashedName,
    DateTime deletedAt,
  ) {
    return (super.update(noteFolders)..where((t) => t.id.equals(folderId)))
        .write(
          NoteFoldersCompanion(
            name: Value(trashedName),
            deletedAt: Value(deletedAt),
          ),
        )
        .then((affected) => affected > 0);
  }

  /// 恢复：`name` 改回原名 + `deleted_at` 置 null + **刷 `updated_at`**。
  ///
  /// ⚠️ 必须刷 `updated_at`，理由与 `NoteDao.restoreById` 完全一样：合并比较键是
  /// `max(updatedAt, deletedAt)`，不刷的话恢复的 version 退回旧 `updatedAt`，
  /// 比远端的 `deletedAt` 还早 → 下次同步远端胜出，文件夹自己滚回回收站。
  Future<bool> markRestored(
    String folderId,
    String restoredName,
    DateTime restoredAt,
  ) {
    return (super.update(noteFolders)..where((t) => t.id.equals(folderId)))
        .write(
          NoteFoldersCompanion(
            name: Value(restoredName),
            deletedAt: const Value(null),
            updatedAt: Value(restoredAt),
          ),
        )
        .then((affected) => affected > 0);
  }

  /// 把某文件夹下全部笔记的 `folder_id` 置 NULL。
  ///
  /// 删文件夹时笔记落进「未分类」。**软删除下外键 `ON DELETE SET NULL` 不触发**
  /// （行还在），所以必须显式调它 —— 与硬删除时的 FK 规则冗余但**不**可省。
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
