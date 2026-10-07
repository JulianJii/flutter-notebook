import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_params.dart';

/// 更新笔记（笔记详情的自动保存入口）。
///
/// 业务规则两条：`noteId` 非空；标题与正文不能同时为空。
///
/// ⚠️ **并发**：笔记详情的自动保存 debounce 可能产生重叠落库，本方法**不加互斥锁**
/// —— 靠 `updatedAt` 单调刷新 + drift 的单写者队列保证顺序（`USECASE-MAP.md` §1.4）。
/// ⛔ **不做「内容没变就跳过写库」的短路**：`updatedAt` 每次刷新正是默认排序
/// `editedDesc` 所依赖的，省一次写入不值得引入一个分支。
class UpdateNoteUseCase {
  const UpdateNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Note>> call(UpdateNoteParams params) {
    if (params.noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    if (params.title.trim().isEmpty && params.content.trim().isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Note must have a title or content')),
      );
    }
    final now = DateTime.now();
    return _repository.update(
      Note(
        id: params.noteId,
        title: params.title,
        content: params.content,
        folderId: params.targetFolderId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
