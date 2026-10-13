import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 批量移动笔记到文件夹。[folderId] 为 `null` = 移到「未分类」。
///
/// 实现内部刷 `updated_at`：归属是用户数据，必须跨设备传播（与
/// `RestoreNoteUseCase` 同一条同步铁律）。
class BatchMoveNotesUseCase {
  const BatchMoveNotesUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, int>> call(List<String> noteIds, String? folderId) {
    if (noteIds.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteIds must not be empty')),
      );
    }
    return _repository.moveToFolderMany(noteIds, folderId);
  }
}
