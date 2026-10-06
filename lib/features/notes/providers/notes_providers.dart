import 'package:init/core/providers/database_providers.dart';
import 'package:init/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:init/features/notes/data/datasources/note_local_data_source.dart';
import 'package:init/features/notes/data/repositories/folder_repository_impl.dart';
import 'package:init/features/notes/data/repositories/note_repository_impl.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';
import 'package:init/features/notes/domain/usecases/create_folder_use_case.dart';
import 'package:init/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/delete_folder_use_case.dart';
import 'package:init/features/notes/domain/usecases/delete_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/empty_trash_use_case.dart';
import 'package:init/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/purge_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/restore_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/rename_folder_use_case.dart';
import 'package:init/features/notes/domain/usecases/update_note_background_use_case.dart';
import 'package:init/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/watch_deleted_notes_use_case.dart';
import 'package:init/features/notes/domain/usecases/watch_folder_counts_use_case.dart';
import 'package:init/features/notes/domain/usecases/watch_notes_use_case.dart';
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
DeleteNoteUseCase deleteNoteUseCase(Ref ref) {
  return DeleteNoteUseCase(ref.watch(noteRepositoryProvider));
}

@riverpod
WatchFolderCountsUseCase watchFolderCountsUseCase(Ref ref) {
  return WatchFolderCountsUseCase(ref.watch(folderRepositoryProvider));
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
