import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/note_folders_table.dart';
import '../tables/notes_table.dart';

part 'note_dao.g.dart';

/// 排序。core 侧的 4 个值与 domain 的 `NoteSort` 一一对应；重复 4 个枚举值
/// 比让 core 反向 import domain 便宜。映射在 `TASK-021` 的 datasource 集中做。
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
/// ⛔ 本类**不得** import `package:init/features/**`（`REPOSITORY-MAP.md` §5.3
/// 的 R1）。参数用原始类型，返回 drift 行对象（`NoteRow`）。行 → `Note` 的
/// 转换在 `features/notes/data/datasources/note_local_data_source.dart`；
/// `NoteQuery` 三态 → 下列参数的翻译也在那里。
@DriftAccessor(tables: [Notes, NoteFolders])
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

    if (uncategorizedOnly) {
      query.where((t) => t.folderId.isNull());
    } else if (folderId != null) {
      query.where((t) => t.folderId.equals(folderId));
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      final pattern = _likePattern(searchTerm);
      query.where(
        (t) =>
            t.title.like(pattern, escapeChar: r'\') |
            t.content.like(pattern, escapeChar: r'\'),
      );
    }

    query.orderBy(<OrderClauseGenerator<$NotesTable>>[_ordering(order)]);
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
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy(<OrderClauseGenerator<$NotesTable>>[
            (t) => OrderingTerm.desc(t.deletedAt),
          ]))
        .watch();
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

  /// 恢复（`deleted_at` 置回 null）。返回是否命中行。
  Future<bool> restoreById(String noteId) {
    return (super.update(notes)..where((t) => t.id.equals(noteId)))
        .write(const NotesCompanion(deletedAt: Value(null)))
        .then((count) => count > 0);
  }

  /// 只写 `background` 列（null = 无背景），**不刷 `updated_at`** ——
  /// 换背景只改外观，不算一次编辑（列表 `editedDesc` 排序与卡片日期不受影响）。
  /// 返回是否命中行。
  Future<bool> updateBackgroundById(String noteId, String? background) {
    return (super.update(notes)..where((t) => t.id.equals(noteId)))
        .write(NotesCompanion(background: Value(background)))
        .then((count) => count > 0);
  }

  /// 删除，返回受影响行数。**物理删除**：只用于回收站的「永久删除」。
  ///
  /// ⚠️ 名字带 `ById`：同上，`delete<T>(TableInfo<T, D>)` 与 `delete(String)`
  /// 不能同名。
  Future<int> deleteById(String noteId) {
    return (super.delete(notes)..where((t) => t.id.equals(noteId))).go();
  }

  /// 清空回收站：物理删除全部 `deleted_at IS NOT NULL` 的行。
  /// 返回受影响行数。
  Future<int> deleteAllDeleted() {
    return (super
            .delete(notes)
          ..where((t) => t.deletedAt.isNotNull()))
        .go();
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
/// 取 2^31-1 已远超任何真实笔记数（§5.7：155 条不分页）。
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
