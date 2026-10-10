import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';

/// 从回收站恢复文件夹：`deleted_at` 置 null、改回原名、刷新 `updated_at`。
///
/// ⚠️ 原名可能已被重新占用（删了「工作」→ 新建了另一个「工作」→ 恢复旧的），
/// 撞 UNIQUE 时 Repository 返回 `Left(InputFailure)`。UI 要**如实报错**而不是
/// 悄悄改名 —— 用户要恢复的是原文件夹，不是一个同名的空壳。
class RestoreFolderUseCase {
  const RestoreFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, Unit>> call(String folderId) {
    if (folderId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'folderId must not be empty')),
      );
    }
    return _repository.restore(folderId);
  }
}