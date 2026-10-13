import 'package:mynote/core/utils/app_clock.dart';
import 'package:drift/drift.dart' show DriftWrappedException, Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/note_dao.dart';
import 'package:mynote/core/database/daos/note_tag_dao.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';

/// 笔记的本地数据源。**SQL 的唯一调用方是 [NoteDao]**，本类只做
/// 「`NoteQuery` → DAO 参数」的翻译与「drift 行 → 实体」的转换。
///
/// 职责边界：
/// ✅ 调 DAO、转换行、`SqliteException → CacheException`、翻译 `NoteQuery`
/// ❌ Exception → Failure（Repository 的活）· 输入校验（UseCase 的活）
/// ❌ uuid 生成（Repository 的活）· 二次排序（SQL 已排完）
abstract class NoteLocalDataSource {
  /// 订阅笔记列表。查询非法（`limit < 0`）时**原样透传**给 DAO，
  /// 由 UseCase 判并返回空流。
  ///
  /// 错误传播：drift 的 watch 不会在流里抛同步异常；真正的读库失败以
  /// `Stream.error(CacheException)` 出现，Repository 与 UI 各司其职，
  /// UI 侧只会看到 `CacheFailure`。
  Stream<List<Note>> watch(NoteQuery query);

  /// 读单条。**找不到时抛 [CacheException]**（不是 Failure，也不是 `null`）。
  Future<Note> getById(String noteId);

  /// 插入。[Note.id] 必须已由 Repository 填好 uuid —— 本类不生成 id。
  Future<Note> insert(Note note);

  /// 整行更新（**不碰 `background` 列** —— 换背景走 [updateBackground]，
  /// 免得自动保存把背景覆盖回旧值）。命中 0 行 → 抛 [CacheException]。
  Future<Note> update(Note note);

  /// 只写背景列（null = 无背景），**不刷新 `updated_at`**。
  /// 命中 0 行 → 抛 [CacheException]。
  Future<void> updateBackground(String noteId, NoteBackground? background);

  /// 只写编辑器字体列（`core/fonts` 目录里的 id，null = 系统默认），
  /// **不刷新 `updated_at`** —— 与 [updateBackground] 同一条约定。
  /// 命中 0 行 → 抛 [CacheException]。
  Future<void> updateEditorFont(String noteId, String? fontId);

  /// 只写置顶 / 收藏两列（`null` = 不动这一列），**不刷 `updated_at`**。
  /// 命中 0 行抛 [CacheException]。
  Future<void> updateFlags(
    String noteId, {
    bool? isPinned,
    bool? isFavorite,
  });

  /// 删除（软删除：写 `deleted_at`）。命中 0 行 → 抛 [CacheException]。
  Future<void> delete(String noteId);

  /// 批量软删除，返回实际命中的行数。空列表直接返回 0（不碰 DAO）。
  Future<int> deleteMany(List<String> noteIds);

  /// 批量移动到文件夹（null = 未分类），返回实际命中的行数。
  /// 实现内部刷 `updated_at`（归属变更必须跨设备传播，见 `NoteDao`）。
  Future<int> moveToFolderMany(List<String> noteIds, String? folderId);

  /// 批量置顶 / 收藏（`null` = 不动这一列），返回实际命中的行数。
  Future<int> updateFlagsMany(
    List<String> noteIds, {
    bool? isPinned,
    bool? isFavorite,
  });

  /// 订阅「最近删除」（`deleted_at IS NOT NULL`，按删除时间倒序）。
  /// 错误传播约定同 [watch]。
  Stream<List<Note>> watchDeleted();

  /// 恢复（`deleted_at` 置回 null）。命中 0 行 → 抛 [CacheException]。
  Future<void> restore(String noteId);

  /// 永久删除（物理 DELETE）。命中 0 行 → 抛 [CacheException]。
  Future<void> purge(String noteId);

  /// 清空「最近删除」（物理删除全部已软删的行）。
  Future<void> purgeAll();
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  /// [dao] 是可选命名参数：测试可注入 mock DAO 断言「翻译是否正确」，
  /// 生产由 [NoteDao] 自己从 [db] 构造。
  NoteLocalDataSourceImpl(AppDatabase db, {NoteDao? dao, NoteTagDao? tagDao})
    : _dao = dao ?? NoteDao(db),
      _tagDao = tagDao ?? NoteTagDao(db);

  final NoteDao _dao;
  final NoteTagDao _tagDao;

  @override
  Stream<List<Note>> watch(NoteQuery query) {
    final args = _toArgs(query.folder);
    return _guardStream(
      _dao
          .watch(
            folderId: args.folderId,
            uncategorizedOnly: args.uncategorizedOnly,
            searchTerm: _normalizeTerm(query.searchTerm),
            tagId: query.tagId,
            order: _toOrder(query.sort),
            limit: query.limit,
            offset: query.offset,
          )
          // 两查合并装 [Note.tags]：主行流每次推流，跟着查一次「noteId → 标签名」
          // 映射（单条 JOIN，非 N+1）。不做双流 combine —— 那需要 rxdart 或
          // 手写缓冲，一次附加 SELECT 在本地库上便宜且足够一致。
          .asyncMap((rows) async {
            final tagNames = await _tagDao.tagNamesByNoteId();
            return <Note>[
              for (final row in rows)
                _toEntity(row, tagNames[row.id] ?? const <String>[]),
            ];
          }),
    );
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
        background: Value(note.background?.id),
        editorFontId: Value(note.editorFontId),
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      ),
    );
    return _toEntity(row);
  });

  @override
  Future<Note> update(Note note) => _guard(() async {
    // ⛔ createdAt **不写**：Companion 省略即「不更新该列」，所以库里的
    // 「首次保存时刻」不会被自动保存覆盖。
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
  Future<void> updateFlags(
    String noteId, {
    bool? isPinned,
    bool? isFavorite,
  }) => _guard(() async {
    final hit = await _dao.updateFlagsById(
      noteId,
      isPinned: isPinned,
      isFavorite: isFavorite,
    );
    if (!hit) {
      throw CacheException(message: 'Note not found: $noteId');
    }
  });

  @override
  Future<void> updateBackground(
    String noteId,
    NoteBackground? background,
  ) => _guard(() async {
    final hit = await _dao.updateBackgroundById(noteId, background?.id);
    if (!hit) {
      throw CacheException(message: 'Note not found: $noteId');
    }
  });

  @override
  Future<void> updateEditorFont(String noteId, String? fontId) =>
      _guard(() async {
        final hit = await _dao.updateEditorFontById(noteId, fontId);
        if (!hit) {
          throw CacheException(message: 'Note not found: $noteId');
        }
      });

  @override
  Future<void> delete(String noteId) => _guard(() async {
    // 软删除：写 `deleted_at`，不碰 `updated_at`（删除不是编辑）。
    final hit = await _dao.softDeleteById(noteId, AppClock.appNow());
    if (!hit) {
      throw CacheException(message: 'Note not found: $noteId');
    }
  });

  @override
  Future<int> deleteMany(List<String> noteIds) => _guard(() async {
    if (noteIds.isEmpty) return 0;
    return _dao.softDeleteByIds(noteIds, AppClock.appNow());
  });

  @override
  Future<int> moveToFolderMany(List<String> noteIds, String? folderId) =>
      _guard(() async {
        if (noteIds.isEmpty) return 0;
        // 与 restore 同一条铁律：归属变更必须刷 `updated_at` 才能跨设备传播。
        return _dao.moveToFolderByIds(noteIds, folderId, AppClock.appNow());
      });

  @override
  Future<int> updateFlagsMany(
    List<String> noteIds, {
    bool? isPinned,
    bool? isFavorite,
  }) => _guard(() async {
    if (noteIds.isEmpty) return 0;
    return _dao.updateFlagsByIds(
      noteIds,
      isPinned: isPinned,
      isFavorite: isFavorite,
    );
  });

  @override
  Stream<List<Note>> watchDeleted() {
    return _guardStream(
      _dao.watchDeleted().map((rows) => rows.map(_toEntity).toList()),
    );
  }

  @override
  Future<void> restore(String noteId) => _guard(() async {
    // ⚠️ 必须同时刷 `updated_at`：`BackupNote.version` 取 `max(updatedAt, deletedAt)`
    // 作为合并比较键。只置回 `deleted_at` 的话，恢复后的 version 会退回**旧**
    // `updatedAt`，比远端那条的 `deletedAt` 还早 → 下次同步远端胜出，笔记自己
    // 滚回回收站。恢复是一次变更，必须有比删除更晚的时间戳。
    final hit = await _dao.restoreById(noteId, AppClock.appNow());
    if (!hit) {
      throw CacheException(message: 'Note not found: $noteId');
    }
  });

  /// **永久删除 = 写墓碑**，不是物理 DELETE。理由见 `NoteDao.purgeById`。
  ///
  /// 行仍在表里（带 `purged_at`），但所有用户可见的列表都过滤掉了它 ——
  /// 用户看到的效果与物理删除完全一致，差别只在磁盘和同步链路。
  @override
  Future<void> purge(String noteId) => _guard(() async {
    final removed = await _dao.purgeById(noteId, AppClock.appNow());
    if (removed == 0) {
      throw CacheException(message: 'Note not found: $noteId');
    }
  });

  @override
  Future<void> purgeAll() => _guard(() async {
    await _dao.purgeAllTrashed(AppClock.appNow());
  });
}

/// `NoteQuery` 的 sealed 三态 → DAO 的两个原始参数。
///
/// 翻译只在这里做一处（core 不 import domain）。
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

/// `''` 归一为 `null`。`LIKE '%%'` 语义上等于全匹配，
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
/// 不 trim 标题 —— 派生值由 UI 现算。
///
/// 时间字段不做时区转换。[tags] 默认空：只有 `watch` 的两查合并会传真值，
/// `getById` / `update` 的回读不带标签（详情页标签单独走 `TagRepository`）。
Note _toEntity(NoteRow row, [List<String> tags = const <String>[]]) {
  return Note(
    id: row.id,
    title: row.title,
    content: row.content,
    folderId: row.folderId,
    background: NoteBackground.fromId(row.background),
    editorFontId: row.editorFontId,
    deletedAt: row.deletedAt,
    purgedAt: row.purgedAt,
    isPinned: row.isPinned,
    isFavorite: row.isFavorite,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    tags: tags,
  );
}

/// 读库失败的统一边界：`SqliteException` / `DriftWrappedException` → `CacheException`。
///
/// - `CacheException` 走 `rethrow`，不二次包装；
/// - **不**转成 `Failure`（那是 Repository 的活），也**不**把原始 `SqliteException`
///  透出去（UI 永不接触原始 Exception）。
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

/// 流版本的 [_guard]：drift 的 `watch` 只在**流里**报错，`try/catch` 抓不到，
/// 所以订阅型的读库失败要靠 `handleError` 兜。映射规则与 [_guard] 一致。
///
/// ⚠️ [Stream.handleError] 不恢复订阅：错误发出后流即关闭。读库失败是终态
/// （不是「重试一下就好」），不假装还能继续推数据。
Stream<T> _guardStream<T>(Stream<T> source) {
  return source.handleError((Object e) {
    if (e is CacheException) throw e;
    if (e is SqliteException) throw CacheException(message: e.message);
    if (e is DriftWrappedException) throw CacheException(message: e.message);
    throw CacheException(message: e.toString());
  });
}
