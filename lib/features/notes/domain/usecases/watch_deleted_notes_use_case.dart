import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 订阅「最近删除」列表（软删除的笔记，按删除时间倒序）。
///
/// 与 `WatchNotesUseCase` 同约定：返回 `Stream` 而非 `Either`，流错误由
/// UI 侧的 `AsyncValue.error` 表达。
class WatchDeletedNotesUseCase {
  const WatchDeletedNotesUseCase(this._repository);

  final NoteRepository _repository;

  Stream<List<Note>> call() => _repository.watchDeleted();
}
