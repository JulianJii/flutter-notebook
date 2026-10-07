import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';

/// 删除文件夹。其下笔记的 `folderId` 落 null（「未分类」）。
///
/// ⛔ **事务不在这一层**：它由 datasource 的 `db.transaction()` 包住
/// 「删文件夹行 + 其下笔记 `folderId` 置 NULL」（`REPOSITORY-MAP.md` §2.2）。
/// UseCase 碰 `db` 就等于让 domain 依赖 drift。
/// ⛔ 不预检存在性；不加二次确认（弹窗无稿）。
class DeleteFolderUseCase {
  const DeleteFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, Unit>> call(String folderId) {
    if (folderId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'folderId must not be empty')),
      );
    }
    return _repository.delete(folderId);
  }
}
