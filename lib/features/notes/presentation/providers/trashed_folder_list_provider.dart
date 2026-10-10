import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trashed_folder_list_provider.g.dart';

/// 订阅回收站里的文件夹（软删除的，按删除时间倒序）。
///
/// 与 `deletedNoteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
/// UI 自动重建，调用方无需手动 invalidate。
@riverpod
Stream<List<NoteFolder>> trashedFolderList(Ref ref) {
  return ref.watch(watchTrashedFoldersUseCaseProvider).call();
}