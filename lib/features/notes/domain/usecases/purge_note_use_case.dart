import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';

/// 永久删除一条「最近删除」里的笔记（物理 DELETE，不可恢复）。
///
/// ⛔ 不预检存在性：找不到由 Repository 返回 `Left(CacheFailure(...))`。
/// 二次确认是 UI 层的事（回收站页面弹确认框），UseCase 不管。
class PurgeNoteUseCase {
  const PurgeNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Unit>> call(String noteId) {
    if (noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.purge(noteId);
  }
}
