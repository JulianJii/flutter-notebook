import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deleted_note_list_provider.g.dart';

/// 订阅「最近删除」列表（软删除的笔记，按删除时间倒序）。
///
/// 与 `noteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
/// UI 自动重建，调用方无需手动 invalidate。
@riverpod
Stream<List<Note>> deletedNoteList(Ref ref) {
  return ref.watch(watchDeletedNotesUseCaseProvider).call();
}
