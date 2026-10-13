import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/tag_repository.dart';

/// 重命名标签。改名跨设备传播由数据层刷 `updated_at` 保证。
class RenameTagUseCase {
  const RenameTagUseCase(this._repository);

  final TagRepository _repository;

  Future<Either<Failure, Unit>> call(String tagId, String name) {
    if (tagId.isEmpty || name.trim().isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'tagId 与 name 均不可为空')),
      );
    }
    return _repository.rename(tagId, name.trim());
  }
}

/// 删除标签：墓碑 + 全部挂接级联摘除（从所有笔记上拿掉这个标签）。
class DeleteTagUseCase {
  const DeleteTagUseCase(this._repository);

  final TagRepository _repository;

  Future<Either<Failure, Unit>> call(String tagId) {
    if (tagId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'tagId must not be empty')),
      );
    }
    return _repository.delete(tagId);
  }
}
