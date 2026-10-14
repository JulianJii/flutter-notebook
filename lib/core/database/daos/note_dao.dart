import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_folders_table.dart';
import '../tables/note_tag_links_table.dart';
import '../tables/notes_table.dart';

part 'note_dao.g.dart';

/// 排序。core 侧的 4 个值与 domain 的 `NoteSort` 一一对应；重复 4 个枚举值
/// 比让 core 反向 import domain 便宜。翻译工作集中在 datasource 层做。
///
/// ⚠️ 放库级而非 `NoteDao` 内：仓库里的 `riverpod_generator` 遇到「类内 enum」
/// 会直接崩（`Enums can't be declared inside classes`），生成链断掉。
enum NoteDaoOrder {
  /// `updated_at DESC` —— 默认（设置「按编辑日期」）。
  editedDesc,

  /// `updated_at ASC`。
  editedAsc,

  /// `created_at DESC`。
  createdDesc,

  /// `title ASC`。
  titleAsc,
}

/// 笔记的 SQL 与 watch 查询。
///
/// ⛔ 本类**不得** import `package:init/features/**` —— core 不准依赖 features。
/// 参数用原始类型，返回 drift 行对象（`NoteRow`）。行 → `Note` 的
/// 转换在 `features/notes/data/datasources/note_local_data_source.dart`；
/// `NoteQuery` 三态 → 下列参数的翻译也在那里。
@DriftAccessor(tables: [Notes, NoteFolders, NoteTagLinks])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  NoteDao(super.db);

  /// 订阅笔记列表。
  ///
  /// [folderId] null + [uncategorizedOnly] false = 不过滤（全部）；
  /// [uncategorizedOnly] true = `folder_id IS NULL`；否则 `folder_id = ?`。
  ///
  /// ⚠️ **无二级排序键**：155 条数据排序不稳定不构成问题。若用户抱怨「同一时刻
  /// 编辑的笔记顺序乱跳」，**先加索引再加二级键**。
  ///
  /// ⚠️ 搜索走参数化 `LIKE`，**不是 FTS5**。FTS5 落地时
  /// 只改本方法内部，`NoteQuery` 接口与上层零改动。
  Stream<List<NoteRow>> watch({
    String? folderId,
    bool uncategorizedOnly = false,
    String? searchTerm,
    String? tagId,
    NoteDaoOrder order = NoteDaoOrder.editedDesc,
    int? limit,
    int offset = 0,
  }) {
    // domain 的 sealed 三态让这个组合不可表达；DAO 收原始类型，故 1 行守卫。
    if (folderId != null && uncategorizedOnly) {
      throw ArgumentError('folderId 与 uncategorizedOnly 不能同时给');
    }

    final query = select(notes);

    // 软删除过滤：列表永远是「未删除」视图，回收站走 [watchDeleted]。
    query.where((t) => t.deletedAt.isNull());
    // 墓碑过滤：已「永久删除」的行**在物理清扫之前仍在表里**（那正是删除能跨设备
    // 传播的原因）。它们既不在列表里，也不在回收站里 —— 只在同步链路里存活。
    query.where((t) => t.purgedAt.isNull());

    if (uncategorizedOnly) {
      query.where((t) => t.folderId.isNull());
    } else if (folderId != null) {
      query.where((t) => t.folderId.equals(folderId));
    }

    // 标签筛选：`EXISTS` 语义经 `isInQuery` 表达 —— 挂接墓碑（摘除）不算数。
    // 子查询只投 noteId 一列，SQLite 走 idx_note_tag_links_tag_id。
    if (tagId != null) {
      final subquery = selectOnly(noteTagLinks)
        ..addColumns([noteTagLinks.noteId])
        ..where(
          noteTagLinks.tagId.equals(tagId) & noteTagLinks.deletedAt.isNull(),
        );
      query.where((t) => t.id.isInQuery(subquery));
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      final pattern = _likePattern(searchTerm);
      query.where(
        (t) =>
            t.title.like(pattern, escapeChar: r'\') |
            t.content.like(pattern, escapeChar: r'\'),
      );
    }

    // 置顶恒在最前，且**优先于任何排序方式** —— 置顶的语义就是「无视排序规则排最前」。
    // 放在 `_ordering` 之前，否则按标题排序时它会被字母表重新排散。
    //
    // ⚠️ 两条子句必须写在**同一次** `orderBy` 里：drift 的 `orderBy` 是赋值不是追加
    // （`orderByExpr = OrderBy(...)`），分两次调时后一次会把置顶列整个覆盖掉 ——
    // 那就是「置顶了但列表纹丝不动」的成因。
    query.orderBy(<OrderClauseGenerator<$NotesTable>>[
      (t) => OrderingTerm.desc(t.isPinned),
      _ordering(order),
    ]);
    if (limit != null || offset > 0) {
      // drift 的 offset 只能经 limit 传入；null limit 时给一个足够大的上限。
      query.limit(limit ?? _noLimit, offset: offset);
    }

    return query.watch();
  }

  /// 读单条。不存在返回 `null`（**不抛异常**）—— 是「转成什么」由 datasource 决定。
  ///
  /// ⚠️ 不过滤 `deleted_at`：回收站里的笔记仍可按 id 读到（详情数据源一致）。
  Future<NoteRow?> getById(String noteId) {
    return (select(notes)..where((t) => t.id.equals(noteId))).getSingleOrNull();
  }

  /// 订阅「最近删除」：`deleted_at IS NOT NULL`，按删除时间倒序。
  /// 回收站页面的唯一查询入口。
  Stream<List<NoteRow>> watchDeleted() {
    return (select(notes)
          ..where((t) => t.deletedAt.isNotNull() & t.purgedAt.isNull())
          ..orderBy(<OrderClauseGenerator<$NotesTable>>[
            (t) => OrderingTerm.desc(t.deletedAt),
          ]))
        .watch();
  }

  /// **永久删除 = 写墓碑，不是物理 DELETE。**
  ///
  /// ⚠️ 这是 v7 的语义翻转，之前这里是 `deleteById`。原因：同步合并是**并集**，
  /// 物理删掉的行在远端「不存在」，对端会认为「本地这条更新的」而把它带回来 ——
  /// A 机永久删的笔记会在 B 机下次同步时复活。行必须留在快照里，并带着一个
  /// 比任何编辑都新的 `purged_at`，删除才真正跨设备传播。
  ///
  /// 真正的物理删除由 [purgeExpiredTombstones] 在保留期到期后做。
  /// ⚠️ WHERE 带 `purged_at IS NULL`：重复 purge 返回 0 而不是再打一次，
  /// datasource 因此会报「找不到」—— 与「行不存在」同一种失败，用户不该被
  /// 区别对待，而幂等的重入对 UI 没有价值（打上墓碑后行已不在回收站列表里）。
  Future<int> purgeById(String noteId, DateTime purgedAt) {
    return (super.update(notes)
          ..where((t) => t.id.equals(noteId) & t.purgedAt.isNull()))
        .write(
          NotesCompanion(
            purgedAt: Value(purgedAt),
            // ⛔ **不刷 `updated_at`**：墓碑自己就是比较键（`BackupNote.version`
            // 取三者较晚者），刷了会让墓碑看起来像一次编辑。
          ),
        )
        .then((affected) => affected);
  }

  /// 清空回收站：给全部 `deleted_at IS NOT NULL` 的行打墓碑。
  ///
  /// ⚠️ 与 [purgeById] 同一条 UPDATE：**不刷 `updated_at`**，墓碑时刻自身就是键。
  /// 已打过墓碑的行被 `purged_at IS NULL` 排除，重复调用是幂等的。
  Future<int> purgeAllTrashed(DateTime purgedAt) {
    return (super.update(notes)
          ..where((t) => t.deletedAt.isNotNull() & t.purgedAt.isNull()))
        .write(NotesCompanion(purgedAt: Value(purgedAt)))
        .then((affected) => affected);
  }

  /// 保留期清扫：物理删掉墓碑已超过 [before] 的行，返回条数。
  ///
  /// 这是 `purged_at` 存在的意义 —— 它让「永久删除」先是可传播的逻辑删除，
  /// 过了保留期（默认 30 天）才真正占磁盘的消失。保留期必须**长于**最长可能
  /// 的「设备离线时长」，否则一台离线一个月的设备重新上线时会把自己早已
  /// 清扫掉的行重新带回来。30 天是刻意的保守取值。
  Future<int> purgeExpiredTombstones(DateTime before) {
    return (super.delete(notes)..where(
          (t) => t.purgedAt.isNotNull() & t.purgedAt.isSmallerThanValue(before),
        ))
        .go();
  }

  /// 插入。用 Companion 而非行对象：`title` / `content` 有默认值、主键无自增，
  /// Companion 天然表达「哪些字段由调用方给」。
  Future<NoteRow> insert(NotesCompanion row) {
    return into(notes).insertReturning(row);
  }

  /// 更新，返回是否命中行。不做「先查后写」的存在性检查 —— 一次 UPDATE 足够。
  ///
  /// ⚠️ 名字带 `ById`：`DatabaseConnectionUser` 继承来的
  /// `update<Tbl, R>(TableInfo<Tbl, R>)` 与 `update(NotesCompanion)` 签名不兼容，
  /// 同名会被判成非法 override（编译错误），故加后缀区分。
  /// Companion 的 `id` 既是定位条件也会被写回，故**必须**由调用方给出。
  Future<bool> updateById(NotesCompanion row) {
    final id = row.id;
    if (!id.present) {
      throw ArgumentError('updateById 需要 Companion 里带 id');
    }
    return (super.update(notes)..where((t) => t.id.equals(id.value)))
        .write(row)
        .then((count) => count > 0);
  }

  /// 软删除：写 `deleted_at`（**不**刷新 `updated_at` —— 删除不是编辑）。
  /// 返回是否命中行。
  Future<bool> softDeleteById(String noteId, DateTime deletedAt) {
    return (super.update(notes)..where((t) => t.id.equals(noteId)))
        .write(NotesCompanion(deletedAt: Value(deletedAt)))
        .then((count) => count > 0);
  }

  /// 批量软删除。单条 UPDATE（`IN`）本身就是原子的，**不需要**包事务。
  /// 语义与 [softDeleteById] 逐列一致（只写 `deleted_at`）。
  Future<int> softDeleteByIds(List<String> noteIds, DateTime deletedAt) {
    return (super.update(notes)..where((t) => t.id.isIn(noteIds)))
        .write(NotesCompanion(deletedAt: Value(deletedAt)));
  }

  /// 批量移动到文件夹（null = 未分类）。**必须刷 `updated_at`**：
  /// 归属是用户数据，不刷的话合并比较键退回旧值，远端会把这次移动原样
  /// 滚回去 —— 与 [restoreById] 刷时间戳是同一条同步铁律。
  Future<int> moveToFolderByIds(
    List<String> noteIds,
    String? folderId,
    DateTime updatedAt,
  ) {
    return (super.update(notes)..where((t) => t.id.isIn(noteIds)))
        .write(
          NotesCompanion(folderId: Value(folderId), updatedAt: Value(updatedAt)),
        );
  }

  /// 恢复（`deleted_at` 置回 null）**并刷新 `updated_at`**。返回是否命中行。
  ///
  /// ⚠️ `updated_at` 必须一起刷，否则恢复**同步不过去**：合并比较键是
  /// `max(updatedAt, deletedAt)`（`BackupNote.version`），只置回 `deleted_at`
  /// 会让 version 退回旧 `updatedAt`，比远端的 `deletedAt` 早 → 远端胜出，
  /// 笔记在下一轮同步里自己滚回回收站。
  /// 副作用：恢复的笔记在「按编辑日期」排序下会置顶 —— 恢复本就是最近一次改动。
  Future<bool> restoreById(String noteId, DateTime restoredAt) {
    return (super.update(notes)..where((t) => t.id.equals(noteId))).write(
      NotesCompanion(deletedAt: const Value(null), updatedAt: Value(restoredAt)),
    ).then((count) => count > 0);
  }

  /// 只写 `background` 列（null = 无背景），**不刷 `updated_at`** ——
  /// 换背景只改外观，不算一次编辑（列表 `editedDesc` 排序与卡片日期不受影响）。
  /// 返回是否命中行。
  Future<bool> updateBackgroundById(String noteId, String? background) {
    return (super.update(notes)..where((t) => t.id.equals(noteId)))
        .write(NotesCompanion(background: Value(background)))
        .then((count) => count > 0);
  }

  /// 只写置顶 / 收藏两列，**不刷 `updated_at`** —— 理由同 [updateBackgroundById]：
  /// 它们是视图状态而非内容，一次「点收藏」不该让笔记的编辑日期跳到今天，
  /// 也不该在同步时被当成一次内容编辑而产生无意义写库。
  Future<bool> updateFlagsById(
    String noteId, {
    bool? isPinned,
    bool? isFavorite,
  }) {
    return (super.update(notes)..where((t) => t.id.equals(noteId)))
        .write(NotesCompanion(
          isPinned: isPinned == null
              ? const Value.absent()
              : Value(isPinned),
          isFavorite: isFavorite == null
              ? const Value.absent()
              : Value(isFavorite),
        ))
        .then((count) => count > 0);
  }

  /// 批量置顶 / 收藏，列语义与 [updateFlagsById] 完全一致（含不刷
  /// `updated_at` 的既有裁决 —— 批量是同一动作的 n 次，不另立语义）。
  Future<int> updateFlagsByIds(
    List<String> noteIds, {
    bool? isPinned,
    bool? isFavorite,
  }) {
    return (super.update(notes)..where((t) => t.id.isIn(noteIds)))
        .write(NotesCompanion(
          isPinned: isPinned == null
              ? const Value.absent()
              : Value(isPinned),
          isFavorite: isFavorite == null
              ? const Value.absent()
              : Value(isFavorite),
        ));
  }

  /// 穷尽 4 个枚举值，无 `default` —— 新增枚举值时编译失败。
  ///
  /// 返回 `(Notes) => OrderingTerm`（`orderBy` 要的是 `OrderClauseGenerator`
  /// 函数列表，不是 `OrderingTerm` 本身）。
  OrderingTerm Function($NotesTable t) _ordering(NoteDaoOrder order) {
    switch (order) {
      case NoteDaoOrder.editedDesc:
        return (t) => OrderingTerm.desc(t.updatedAt);
      case NoteDaoOrder.editedAsc:
        return (t) => OrderingTerm.asc(t.updatedAt);
      case NoteDaoOrder.createdDesc:
        return (t) => OrderingTerm.desc(t.createdAt);
      case NoteDaoOrder.titleAsc:
        return (t) => OrderingTerm.asc(t.title);
    }
  }
}

/// `limit == null` 但 `offset > 0` 时的占位上限。SQLite 的 `LIMIT` 上限是 2^63-1，
/// 取 2^31-1 已远超任何真实笔记数（百量级不分页）。
const int _noLimit = 0x7FFFFFFF;

/// 把用户输入转成 `LIKE` 的 pattern，并对 `%` `_` `\` 三个元字符做转义。
///
/// 不转义的话，用户搜 `100%` 会匹配到所有含 `100` 的笔记（`LIKE` 里 `%` 是通配符），
/// 搜 `a_b` 会匹配 `axb`。这是输入边界上的正确性处理，不是过度设计。
String _likePattern(String term) {
  final escaped = term
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return '%$escaped%';
}
