import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 读单条笔记。笔记详情打开时用它初始化草稿。
///
/// 「找不到」由 Repository 返回 `Left(CacheFailure(message: 'Note not found: $id'))`
/// —— **不在这里预检**：预检会让「检查」与「使用」之间出现竞态窗口，
/// 而且「存不存在」不是本层的业务规则。
class GetNoteUseCase {
  const GetNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Note>> call(String noteId) {
    if (noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.getById(noteId);
  }
}
