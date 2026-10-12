import 'package:drift/drift.dart';

import 'note_folders_table.dart';

/// 笔记表。实体见 `features/notes/domain/entities/note.dart`。
///
/// ⚠️ 删除语义（原 CONFLICT-10 裁决已翻转为软删除，本 commit 一次性落地全部四条）：
///  1. `deleted_at` 列 + `schemaVersion` 1 → 2 + `MigrationStrategy`（`app_database.dart`）；
///  2. `NoteDao.watch` 与 `FolderDao.watchWithCounts` / `watchUncategorizedCount`
///     全部加 `deleted_at IS NULL`；
///  3. `NoteDao.watchDeleted` / `softDeleteById` / `restoreById` +
///     Repository 的 `watchDeleted` / `restore` / `purge`；
///  4. 回收站页面（`RecentlyDeletedScreen`，入口在设置）。
/// 漏掉任何一条都会造成「删了还在列表里」或「最近删除看不到」的数据不一致。
///
/// ⚠️ `PRAGMA foreign_keys = ON` **必须在 `AppDatabase.beforeOpen` 里执行**
/// 才生效（SQLite 默认关闭外键强制）。本文件只声明 `ON DELETE SET NULL` 规则，
/// 开关在 `TASK-016`。
///
/// ⚠️ 本文件**没有** `part 'notes_table.g.dart'`：drift 2.35 默认是
/// monolithic shared-part 模式，行类（`NoteRow`）与 companion（`NotesCompanion`）
/// 由 `build_runner` 生成进**数据库文件**的 `app_database.g.dart`。要拿到
/// `NoteRow` 需 `import 'package:mynote/core/database/app_database.dart';`。
/// 表名 / 列 getter（`notes` / `Notes.id` …）则直接从本文件取。
@DataClassName('NoteRow')
@TableIndex(name: 'idx_notes_folder_id', columns: {#folderId})
@TableIndex(name: 'idx_notes_updated_at', columns: {#updatedAt})
class Notes extends Table {
  @override
  String get tableName => 'notes';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  TextColumn get title => text().withDefault(const Constant(''))();

  TextColumn get content => text().withDefault(const Constant(''))();

  /// null = 「未分类」系统视图（`ARCHITECTURE-DESIGN.md` §5.3），不占文件夹表行。
  /// 删除文件夹时由外键置 null，其下笔记自动落入未分类。
  TextColumn get folderId => text().nullable().references(
    NoteFolders,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get createdAt => dateTime()();

  /// 默认排序键（设置「按编辑日期」）。
  DateTimeColumn get updatedAt => dateTime()();

  /// 软删除时刻。null = 正常笔记；非 null = 已进「最近删除」。
  /// 恢复即置回 null，永久删除才物理 DELETE（`NoteDao.deleteById`）。
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// 纸张背景的稳定 id（`NoteBackground.id`）。null = 无背景（白底）。
  /// 存 id 而非下标：资源列表顺序变化不会让老数据错位，未知值降级为「无背景」。
  /// 只由 `NoteDao.updateBackgroundById` 写，整行 `update` 不碰这一列。
  TextColumn get background => text().nullable()();

  /// 这篇笔记的编辑器字体 id（`core/fonts` 目录里的 id）。null = 系统默认。
  ///
  /// ⚠️ 与 [background] 同类：**每篇笔记独立**的视觉属性。存 id 而非族名（族名由
  /// 字体目录现算）。只由 `NoteDao.updateEditorFontById` 写，整行 `update` 不碰这一列。
  TextColumn get editorFontId => text().nullable()();

  /// 置顶。列表排序时排在未置顶之前（`NoteDao.watch`），置顶笔记不改变创建时间。
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();

  /// 收藏。与置顶是**两个正交维度**：置顶管「最近要看的在前面」，收藏管「重要的
  /// 找得到」，一条笔记可以只收藏不置顶。
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// **永久删除的墓碑时刻**。null = 没被永久删除过。
  ///
  /// ⚠️ 「永久删除」写的是这一列而**不是**物理 DELETE：合并是并集，物理删掉的行
  /// 在远端「不存在」，对端因此判定「本地这条更新的」而把它原样带回来 ——
  /// A 机永久删的笔记会在 B 机下次同步时复活。要让删除真正跨设备传播，
  /// 被删的行必须**留在快照里**并带着一个比任何编辑都新的时刻。
  ///
  /// 真正的物理删除由保留期清扫（`BackupLocalDataSource.purgeExpired`）在
  /// [purgedAt] 超过保留期后做，那时它对所有设备都已过期。
  DateTimeColumn get purgedAt => dateTime().nullable()();
}
