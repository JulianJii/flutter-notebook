import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_editor_font_params.dart';

/// 只改一篇笔记的编辑器字体（null = 系统默认字体）。
///
/// 业务规则一条：`noteId` 非空。
///
/// ⛔ **不复用 `UpdateNoteUseCase`**：那条链路会刷新 `updatedAt`（列表排序键与
/// 卡片日期都会跳变），而换字体不是编辑。窄通道让「只写字体列」在类型上可见
/// —— 与 `UpdateNoteBackgroundUseCase` 同一形状。
class UpdateNoteEditorFontUseCase {
  const UpdateNoteEditorFontUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Unit>> call(UpdateNoteEditorFontParams params) {
    if (params.noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.updateEditorFont(params.noteId, params.fontId);
  }
}
