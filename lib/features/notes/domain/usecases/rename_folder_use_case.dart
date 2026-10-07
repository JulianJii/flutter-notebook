import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:mynote/features/notes/domain/usecases/rename_folder_params.dart';

/// 重命名文件夹。业务规则：`folderId` 非空、名称 trim 后非空且 ≤ 40。
///
/// ⛔ **不建 `UpdateFolderUseCase`**：单层文件夹只有 `name` 一个可变字段，
/// 「编辑」与「重命名」是同一个动作（`USECASE-MAP.md` §1.7）。
/// 重名的判定同样在 schema 层（UNIQUE 约束），不在这里预查。
class RenameFolderUseCase {
  const RenameFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, NoteFolder>> call(RenameFolderParams params) {
    if (params.folderId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'folderId must not be empty')),
      );
    }
    final name = params.name.trim();
    if (name.isEmpty || name.length > 40) {
      return Future.value(
        const Left(
          InputFailure(message: 'Folder name must be 1..40 characters'),
        ),
      );
    }
    return _repository.rename(params.folderId, name);
  }
}
