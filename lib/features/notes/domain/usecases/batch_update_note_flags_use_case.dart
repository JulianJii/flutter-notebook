import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';

/// 批量置顶 / 收藏。`null` 字段 = 不动那一列，列语义与
/// [UpdateNoteFlagsUseCase] 完全一致（含不刷 `updatedAt` 的既有裁决 ——
/// 它们是视图状态而非内容，一次「点收藏」不该让编辑日期跳到今天）。
class BatchUpdateNoteFlagsUseCase {
  const BatchUpdateNoteFlagsUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, int>> call(
    List<String> noteIds, {
    bool? isPinned,
    bool? isFavorite,
  }) {
    if (noteIds.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteIds must not be empty')),
      );
    }
    return _repository.updateFlagsMany(
      noteIds,
      isPinned: isPinned,
      isFavorite: isFavorite,
    );
  }
}
