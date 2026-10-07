import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_params.dart';

/// 新建笔记。
///
/// 业务规则：**标题与正文不能同时为空**（trim 后）。只有内容没标题**放行**
/// ——笔记列表稿的卡片就是一行标题 + 正文，草稿可能只有正文。
///
/// ⛔ **不生成 uuid**：传空串给 Repository，由它在 `create` 里生成
/// （`REPOSITORY-MAP.md` §2.1）。测试要固定 id 时注入 Mock Uuid，而不是在这里 mock。
class CreateNoteUseCase {
  const CreateNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Note>> call(CreateNoteParams params) {
    if (params.title.trim().isEmpty && params.content.trim().isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Note must have a title or content')),
      );
    }
    final now = DateTime.now();
    return _repository.create(
      Note(
        id: '',
        title: params.title,
        content: params.content,
        folderId: params.folderId,
        background: params.background,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
