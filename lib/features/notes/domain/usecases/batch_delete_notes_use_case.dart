import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 批量删除笔记（**软删除**，与 [DeleteNoteUseCase] 同语义：进「最近删除」，
/// 可恢复）。批量删除不弹二次确认是 UI 层的裁决 —— 进了回收站就丢不了。
///
/// ⛔ 不逐条调 [NoteRepository.delete]：n 次单条 UPDATE 在中途失败会留下
/// 「删了一半」的状态，一条 `IN` 的 UPDATE 是原子的。
class BatchDeleteNotesUseCase {
  const BatchDeleteNotesUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, int>> call(List<String> noteIds) {
    if (noteIds.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteIds must not be empty')),
      );
    }
    return _repository.deleteMany(noteIds);
  }
}
