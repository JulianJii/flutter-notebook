import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';

/// 按用户拖拽后的顺序重排文件夹（P4 的拖动图标）。
///
/// ⛔ **不校验顺序的合法性**（是否覆盖全部 id）：唯一的调用方是 P4，它给的就是
/// `folderProvider` 当前那一列的完整顺序。在这里查一遍列表 = 多发一次查询换一个
/// 上层本就成立的前提。
/// ⛔ **不做「顺序没变就不写」的短路**：`n` 是两位数的文件夹数，一次 `batch` 比
/// 一次「先读再比」更便宜，也少一个分支。
/// ⛔ **事务不在这一层**：整表写成 `0..n-1` 由 datasource / DAO 的 `batch` 保证。
class ReorderFoldersUseCase {
  const ReorderFoldersUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, Unit>> call(List<String> orderedFolderIds) {
    return _repository.reorder(orderedFolderIds);
  }
}
