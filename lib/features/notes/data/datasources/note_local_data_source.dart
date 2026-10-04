import 'package:drift/drift.dart' show DriftWrappedException, Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:init/core/database/app_database.dart';
import 'package:init/core/database/daos/note_dao.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';

/// 笔记的本地数据源。**SQL 的唯一调用方是 [NoteDao]**，本类只做
/// 「`NoteQuery` → DAO 参数」的翻译与「drift 行 → 实体」的转换。
///
/// 职责边界（`REPOSITORY-MAP.md` §2.1）：
/// ✅ 调 DAO、转换行、`SqliteException → CacheException`、翻译 `NoteQuery`
/// ❌ Exception → Failure（Repository 的活）· 输入校验（UseCase 的活）
/// ❌ uuid 生成（Repository 的活）· 二次排序（SQL 已排完）
abstract class NoteLocalDataSource {
  /// 订阅笔记列表。查询非法（`limit < 0`）时**原样透传**给 DAO，
  /// 由 UseCase 判并返回空流（`USECASE-MAP.md` §1.1）。
  ///
  /// 错误传播：drift 的 watch 不会在流里抛同步异常；真正的读库失败以
  /// `Stream.error(CacheException)` 出现，Repository 与 UI 各司其职
  /// （`ARCHITECTURE-DESIGN.md` §6.4：UI 侧只会看到 `CacheFailure`）。
  Stream<List<Note>> watch(NoteQuery query);

  /// 读单条。**找不到时抛 [CacheException]**（不是 Failure，也不是 `null`）。
  Future<Note> getById(String noteId);

  /// 插入。[Note.id] 必须已由 Repository 填好 uuid —— 本类不生成 id。
  Future<Note> insert(Note note);

  /// 整行更新。命中 0 行 → 抛 [CacheException]。
  Future<Note> update(Note note);

  /// 删除。命中 0 行 → 抛 [CacheException]。
  Future<void> delete(String noteId);
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  /// [dao] 是可选命名参数：测试可注入 mock DAO 断言「翻译是否正确」，
  /// 生产由 [NoteDao] 自己从 [db] 构造（装配在 `TASK-023`）。
  NoteLocalDataSourceImpl(AppDatabase db, {NoteDao? dao})
    : _dao = dao ?? NoteDao(db);

  final NoteDao _dao;

  @override
  Stream<List<Note>> watch(NoteQuery query) {
    final args = _toArgs(query.folder);
    return _dao
        .watch(
          folderId: args.folderId,
          uncategorizedOnly: args.uncategorizedOnly,
          searchTerm: _normalizeTerm(query.searchTerm),
          order: _toOrder(query.sort),
          limit: query.limit,
          offset: query.offset,
        )
        .map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Note> getById(String noteId) => _guard(() async {
    final row = await _dao.getById(noteId);
    if (row == null) {
      throw CacheException(message: 'Note not found: $noteId');
    }
    return _toEntity(row);
  });

  @override
  Future<Note> insert(Note note) => _guard(() async {
    final row = await _dao.insert(
      NotesCompanion.insert(
        id: note.id,
        title: Value(note.title),
        content: Value(note.content),
        folderId: Value(note.folderId),
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      ),
    );
    return _toEntity(row);
  });

  @override
  Future<Note> update(Note note) => _guard(() async {
    // ⛔ createdAt **不写**：Companion 省略即「不更新该列」，所以库里的
    // 「首次保存时刻」不会被自动保存覆盖（ARCHITECTURE-DESIGN §5.2）。
    final hit = await _dao.updateById(
      NotesCompanion(
        id: Value(note.id),
        title: Value(note.title),
        content: Value(note.content),
        folderId: Value(note.folderId),
        updatedAt: Value(note.updatedAt),
      ),
    );
    if (!hit) {
      throw CacheException(message: 'Note not found: ${note.id}');
    }
    // 回读：入参的 createdAt 是调用方给的（UseCase 传 now()），不是库里的值。
    // 回读让「保留库里的 createdAt」这条契约对调用方**可观察**，而不是只存在于
    // 「我没写这一列」这种需要读者自己推的地方。
    final row = await _dao.getById(note.id);
    if (row == null) {
      throw CacheException(message: 'Note not found: ${note.id}');
    }
    return _toEntity(row);
  });

  @override
  Future<void> delete(String noteId) => _guard(() async {
    final removed = await _dao.deleteById(noteId);
    if (removed == 0) {
      throw CacheException(message: 'Note not found: $noteId');
    }
  });
}

/// `NoteQuery` 的 sealed 三态 → DAO 的两个原始参数。
///
/// 翻译只在这里做一处（`REPOSITORY-MAP.md` §5.3 的 R1：core 不 import domain）。
/// 三个分支穷尽 `sealed` 子类型 —— 新增子类型时**编译失败**，这正是 sealed
/// 最大的价值。2 个值的临时结构用具名 record，不建 `NoteQueryArgs` 类。
({String? folderId, bool uncategorizedOnly}) _toArgs(NoteFolderFilter filter) {
  return switch (filter) {
    AllFolders() => (folderId: null, uncategorizedOnly: false),
    UncategorizedNotes() => (folderId: null, uncategorizedOnly: true),
    SingleFolder(:final folderId) => (
      folderId: folderId,
      uncategorizedOnly: false,
    ),
  };
}

/// `''` 归一为 `null`（`TASK-014` 的约定）。`LIKE '%%'` 语义上等于全匹配，
/// 但会让「两个等价的 `NoteQuery` 产生不同 SQL」，参数的不可预测性比省一行
/// 判断更贵。
String? _normalizeTerm(String? term) => (term?.isEmpty ?? true) ? null : term;

/// 4 分支穷尽 `NoteSort`，无 `default` —— 新增枚举值时编译失败。
/// 集中一处，不散落在调用点。
NoteDaoOrder _toOrder(NoteSort sort) {
  return switch (sort) {
    NoteSort.editedDesc => NoteDaoOrder.editedDesc,
    NoteSort.editedAsc => NoteDaoOrder.editedAsc,
    NoteSort.createdDesc => NoteDaoOrder.createdDesc,
    NoteSort.titleAsc => NoteDaoOrder.titleAsc,
  };
}

/// drift 行 → 领域实体的**直连**。⛔ 不截断 `content`、不算 `wordCount`、
/// 不 trim 标题 —— 派生值由 UI 现算（`REPOSITORY-MAP.md` §0：不建 Model 层）。
///
/// 时间字段不做时区转换（§5.7「本期本地时钟、无时区转换」）。
Note _toEntity(NoteRow row) {
  return Note(
    id: row.id,
    title: row.title,
    content: row.content,
    folderId: row.folderId,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

/// 读库失败的统一边界：`SqliteException` / `DriftWrappedException` → `CacheException`。
///
/// - `CacheException` 走 `rethrow`，不二次包装；
/// - **不**转成 `Failure`（那是 Repository 的活），也**不**把原始 `SqliteException`
///   透出去（UI 永不接触原始 Exception）。
Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on CacheException {
    rethrow;
  } on SqliteException catch (e) {
    throw CacheException(message: e.message);
  } on DriftWrappedException catch (e) {
    throw CacheException(message: e.message);
  } on Exception catch (e) {
    throw CacheException(message: e.toString());
  }
}
