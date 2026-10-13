import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:mynote/features/notes/data/datasources/note_local_data_source.dart';
import 'package:mynote/features/notes/data/datasources/note_version_local_data_source.dart';
import 'package:mynote/features/notes/data/datasources/tag_local_data_source.dart';
import 'package:mynote/features/notes/data/repositories/folder_repository_impl.dart';
import 'package:mynote/features/notes/data/repositories/note_image_repository_impl.dart';
import 'package:mynote/features/notes/data/repositories/note_repository_impl.dart';
import 'package:mynote/features/notes/data/repositories/note_version_repository_impl.dart';
import 'package:mynote/features/notes/data/repositories/tag_repository_impl.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:mynote/features/notes/domain/repositories/note_image_repository.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/repositories/note_version_repository.dart';
import 'package:mynote/features/notes/domain/repositories/tag_repository.dart';
import 'package:mynote/features/notes/domain/usecases/batch_delete_notes_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/batch_move_notes_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/batch_update_note_flags_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/delete_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/delete_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/empty_folder_trash_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/empty_trash_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/get_note_tags_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/pick_note_image_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/purge_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/purge_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/restore_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/restore_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/rename_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/reorder_folders_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/restore_note_version_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/save_note_version_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/manage_tag_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/set_note_tags_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_background_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_editor_font_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_flags_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_deleted_notes_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_folder_counts_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_note_versions_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_notes_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_tags_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_trashed_folders_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notes_providers.g.dart';

// ⛔ provider 体**只做装配**：无 `if`、无业务逻辑、无 `print`、无 try/catch。
// ⛔ 不建 `uuidProvider`：Repository 构造函数的默认参数已经给了 `const Uuid()`，
// 一个默认值不值得一个 provider（测试要固定 id 时在 Repository 单测里传 Mock）。
// ⛔ UseCase provider 不 keepAlive：UseCase 是无状态薄壳，自动 dispose 无副作用。

// ---- data source ----
@riverpod
NoteLocalDataSource noteLocalDataSource(Ref ref) {
  return NoteLocalDataSourceImpl(ref.watch(appDatabaseProvider));
}

@riverpod
FolderLocalDataSource folderLocalDataSource(Ref ref) {
  return FolderLocalDataSourceImpl(ref.watch(appDatabaseProvider));
}

// ---- repository ----
@riverpod
NoteRepository noteRepository(Ref ref) {
  return NoteRepositoryImpl(ref.watch(noteLocalDataSourceProvider));
}

@riverpod
FolderRepository folderRepository(Ref ref) {
  return FolderRepositoryImpl(ref.watch(folderLocalDataSourceProvider));
}

// ---- 标签 ----
@riverpod
TagLocalDataSource tagLocalDataSource(Ref ref) {
  return TagLocalDataSourceImpl(ref.watch(appDatabaseProvider));
}

@riverpod
TagRepository tagRepository(Ref ref) {
  return TagRepositoryImpl(ref.watch(tagLocalDataSourceProvider));
}

// ---- 单篇版本历史 ----
@riverpod
NoteVersionLocalDataSource noteVersionLocalDataSource(Ref ref) {
  return NoteVersionLocalDataSourceImpl(ref.watch(appDatabaseProvider));
}

@riverpod
NoteVersionRepository noteVersionRepository(Ref ref) {
  return NoteVersionRepositoryImpl(
    ref.watch(noteVersionLocalDataSourceProvider),
  );
}

// ---- use case ----
@riverpod
WatchNotesUseCase watchNotesUseCase(Ref ref) {
  return WatchNotesUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
GetNoteUseCase getNoteUseCase(Ref ref) {
  return GetNoteUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
CreateNoteUseCase createNoteUseCase(Ref ref) {
  return CreateNoteUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
UpdateNoteUseCase updateNoteUseCase(Ref ref) {
  return UpdateNoteUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
UpdateNoteBackgroundUseCase updateNoteBackgroundUseCase(Ref ref) {
  return UpdateNoteBackgroundUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
UpdateNoteEditorFontUseCase updateNoteEditorFontUseCase(Ref ref) {
  return UpdateNoteEditorFontUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
UpdateNoteFlagsUseCase updateNoteFlagsUseCase(Ref ref) {
  return UpdateNoteFlagsUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
DeleteNoteUseCase deleteNoteUseCase(Ref ref) {
  return DeleteNoteUseCase(ref.watch(noteRepositoryProvider));
}

// ---- 批量操作（长按多选）----
@riverpod
BatchDeleteNotesUseCase batchDeleteNotesUseCase(Ref ref) {
  return BatchDeleteNotesUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
BatchMoveNotesUseCase batchMoveNotesUseCase(Ref ref) {
  return BatchMoveNotesUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
BatchUpdateNoteFlagsUseCase batchUpdateNoteFlagsUseCase(Ref ref) {
  return BatchUpdateNoteFlagsUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
WatchFolderCountsUseCase watchFolderCountsUseCase(Ref ref) {
  return WatchFolderCountsUseCase(ref.watch(folderRepositoryProvider));
}

// ---- 标签用例 ----
@riverpod
WatchTagsUseCase watchTagsUseCase(Ref ref) {
  return WatchTagsUseCase(ref.watch(tagRepositoryProvider));
}

@riverpod
GetNoteTagsUseCase getNoteTagsUseCase(Ref ref) {
  return GetNoteTagsUseCase(ref.watch(tagRepositoryProvider));
}

@riverpod
SetNoteTagsUseCase setNoteTagsUseCase(Ref ref) {
  return SetNoteTagsUseCase(ref.watch(tagRepositoryProvider));
}

@riverpod
RenameTagUseCase renameTagUseCase(Ref ref) {
  return RenameTagUseCase(ref.watch(tagRepositoryProvider));
}

@riverpod
DeleteTagUseCase deleteTagUseCase(Ref ref) {
  return DeleteTagUseCase(ref.watch(tagRepositoryProvider));
}

// ---- 版本历史用例 ----
@riverpod
SaveNoteVersionUseCase saveNoteVersionUseCase(Ref ref) {
  return SaveNoteVersionUseCase(ref.watch(noteVersionRepositoryProvider));
}

@riverpod
WatchNoteVersionsUseCase watchNoteVersionsUseCase(Ref ref) {
  return WatchNoteVersionsUseCase(ref.watch(noteVersionRepositoryProvider));
}

@riverpod
RestoreNoteVersionUseCase restoreNoteVersionUseCase(Ref ref) {
  return RestoreNoteVersionUseCase(
    ref.watch(noteVersionRepositoryProvider),
    ref.watch(noteRepositoryProvider),
  );
}

@riverpod
CreateFolderUseCase createFolderUseCase(Ref ref) {
  return CreateFolderUseCase(ref.watch(folderRepositoryProvider));
}

@riverpod
RenameFolderUseCase renameFolderUseCase(Ref ref) {
  return RenameFolderUseCase(ref.watch(folderRepositoryProvider));
}

@riverpod
DeleteFolderUseCase deleteFolderUseCase(Ref ref) {
  return DeleteFolderUseCase(ref.watch(folderRepositoryProvider));
}

@riverpod
ReorderFoldersUseCase reorderFoldersUseCase(Ref ref) {
  return ReorderFoldersUseCase(ref.watch(folderRepositoryProvider));
}

// ---- 回收站（最近删除）----
@riverpod
WatchDeletedNotesUseCase watchDeletedNotesUseCase(Ref ref) {
  return WatchDeletedNotesUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
RestoreNoteUseCase restoreNoteUseCase(Ref ref) {
  return RestoreNoteUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
PurgeNoteUseCase purgeNoteUseCase(Ref ref) {
  return PurgeNoteUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
EmptyTrashUseCase emptyTrashUseCase(Ref ref) {
  return EmptyTrashUseCase(ref.watch(noteRepositoryProvider));
}

// 文件夹 / 待办的回收站入口在**各自 feature** 的屏里，但它们共用 `/notes/trash`
// 这一页 —— 所以用例的 DI 也在各自 feature 装配，只在这一处并列登记。
@riverpod
WatchTrashedFoldersUseCase watchTrashedFoldersUseCase(Ref ref) {
  return WatchTrashedFoldersUseCase(ref.watch(folderRepositoryProvider));
}

@riverpod
RestoreFolderUseCase restoreFolderUseCase(Ref ref) {
  return RestoreFolderUseCase(ref.watch(folderRepositoryProvider));
}

@riverpod
PurgeFolderUseCase purgeFolderUseCase(Ref ref) {
  return PurgeFolderUseCase(ref.watch(folderRepositoryProvider));
}

@riverpod
EmptyFolderTrashUseCase emptyFolderTrashUseCase(Ref ref) {
  return EmptyFolderTrashUseCase(ref.watch(folderRepositoryProvider));
}

// ---- 图片 ----
// ⛔ 不要 keepAlive：`NoteImageRepositoryImpl` 无状态（每次都新开选择器），
// 常驻只为省一次 new，收益为零。
@riverpod
NoteImageRepository noteImageRepository(Ref ref) {
  return NoteImageRepositoryImpl();
}

@riverpod
PickNoteImageUseCase pickNoteImageUseCase(Ref ref) {
  return PickNoteImageUseCase(ref.watch(noteImageRepositoryProvider));
}
