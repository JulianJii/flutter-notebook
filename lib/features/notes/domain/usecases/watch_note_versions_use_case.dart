import 'package:mynote/features/notes/domain/entities/note_version.dart';
import 'package:mynote/features/notes/domain/repositories/note_version_repository.dart';

/// 订阅一篇笔记的版本历史（新→旧）。⛔ 不返回 Either（流有成败用
/// `AsyncValue` 表达），约定同 `WatchNotesUseCase`。
class WatchNoteVersionsUseCase {
  const WatchNoteVersionsUseCase(this._repository);

  final NoteVersionRepository _repository;

  Stream<List<NoteVersion>> call(String noteId) =>
      _repository.watchVersions(noteId);
}
