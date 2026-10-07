import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_background_params.dart';

/// 只改笔记的纸张背景（null = 清除）。
///
/// 业务规则一条：`noteId` 非空。
///
/// ⛔ **不复用 `UpdateNoteUseCase`**：那条链路会刷新 `updatedAt`（列表排序键与
/// 卡片日期都会跳变），而换背景不是编辑。窄通道让「只写背景列」在类型上可见。
class UpdateNoteBackgroundUseCase {
  const UpdateNoteBackgroundUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Unit>> call(UpdateNoteBackgroundParams params) {
    if (params.noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.updateBackground(params.noteId, params.background);
  }
}
