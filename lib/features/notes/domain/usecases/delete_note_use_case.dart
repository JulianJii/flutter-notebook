import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 删除笔记（**软删除**：移进「最近删除」，可恢复）。
///
/// 原 CONFLICT-10 的硬删除裁决已翻转为软删除，四件套（`deleted_at` 列 +
/// 查询过滤 + restore/purge + 回收站页面）已随本 commit 落地，见
/// `notes_table.dart` 头注。恢复走 `RestoreNoteUseCase`，永久删除走
/// `PurgeNoteUseCase`。
///
/// ⛔ **不预检存在性**：预检让「检查」与「删除」之间出现竞态窗口，且多一次查询。
/// 找不到由 Repository 返回 `Left(CacheFailure(...))`。
/// ⛔ **不加二次确认**：`AppDialog` 无稿（Q13 / Q34），那是 UI 层的事。
/// ⛔ 不建 `Restore` / `Purge`（`USECASE-MAP.md` §4 已判定不建，空壳方法就是负债）。
class DeleteNoteUseCase {
  const DeleteNoteUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Unit>> call(String noteId) {
    if (noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.delete(noteId);
  }
}
