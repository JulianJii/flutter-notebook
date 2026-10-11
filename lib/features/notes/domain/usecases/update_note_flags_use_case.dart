import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_flags_params.dart';

/// 改置顶 / 收藏。`null` 字段 = 不动那一列。
///
/// ⛔ **不与 `UpdateNoteUseCase` 合并**：整行更新会刷 `updatedAt`，而置顶与收藏
/// 是**视图状态**不是内容 —— 点一下收藏不该让笔记的「编辑于」跳到今天，也不该
/// 在同步时被当成一次内容编辑而产生无意义写库。
class UpdateNoteFlagsUseCase {
  const UpdateNoteFlagsUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Unit>> call(UpdateNoteFlagsParams params) {
    if (params.noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.updateFlags(
      params.noteId,
      isPinned: params.isPinned,
      isFavorite: params.isFavorite,
    );
  }
}