import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';

/// 回收站的「永久删除」：**物理**删一个文件夹行（不可恢复、不跨设备传播）。
///
/// ⚠️ 物理删除不留痕，所以别端下次同步会把它带回来 —— 这是「并集合并」的固有
/// 结果，见 `docs/FEATURES.md`「已知限制」。
/// 二次确认是 UI 层的事，UseCase 不管。
class PurgeFolderUseCase {
  const PurgeFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, Unit>> call(String folderId) {
    if (folderId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'folderId must not be empty')),
      );
    }
    return _repository.purge(folderId);
  }
}