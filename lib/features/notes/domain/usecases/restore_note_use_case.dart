import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 从「最近删除」恢复笔记（`deleted_at` 置回 null）。
///
/// ⛔ 不预检存在性：找不到由 Repository 返回 `Left(CacheFailure(...))`。
class RestoreNoteUseCase {
  const RestoreNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Unit>> call(String noteId) {
    if (noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.restore(noteId);
  }
}
