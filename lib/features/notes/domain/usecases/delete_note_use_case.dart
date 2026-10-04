import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';

/// 删除笔记。
///
/// 裁决点（CONFLICT-10）：本实现走 [NoteRepository.delete]，其语义由
/// ARCHITECTURE-DESIGN.md §5.4 / ADR-7 判定的**硬删除**。
/// 若裁决改为软删除：删除列 + 全部查询的 `deleted_at IS NULL` 过滤 +
/// listTrashed / restore / purge + 回收站页面必须**在同一个 commit 里**加，
/// 禁止只加列不加页面（无页面的软删除 = 用户数据静默消失，比硬删除更糟）。
// TODO(CONFLICT-10): 删除语义待裁决，裁决后删掉本注释块并同步 ARCHITECTURE-DESIGN §5.4。
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
