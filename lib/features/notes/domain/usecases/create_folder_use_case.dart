import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/domain/usecases/create_folder_params.dart';

/// 新建文件夹。业务规则：名称非空（trim 后）、长度 ≤ 40。
///
/// 校验用 `trim()`，**存回 trim 后的值**：文件夹名两端的空格没有意义
/// （D4 里它是分类标签，不是正文）。
///
/// ⚠️ **重名不在这里判**：不预查文件夹列表，依赖 `note_folders.name` 的 UNIQUE
/// 约束 —— 预查 + 插入 = 两次查询 + 一个竞态窗口（两个并发 create 都能通过预查）。
/// 冲突由 Repository 映射成 `Left(InputFailure)` 原样透传。
/// ⛔ **不用 `characters` 包**做长度校验：D4 是短中文名，40 的上限离 emoji 边界
/// 很远；真要支持超长 emoji 时换成 `characters` 是一行的事。
class CreateFolderUseCase {
  const CreateFolderUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, NoteFolder>> call(CreateFolderParams params) {
    final name = params.name.trim();
    if (name.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Folder name must not be empty')),
      );
    }
    if (name.length > 40) {
      return Future.value(
        const Left(
          InputFailure(message: 'Folder name must be at most 40 characters'),
        ),
      );
    }
    final now = DateTime.now();
    return _repository.create(
      NoteFolder(id: '', name: name, createdAt: now, updatedAt: now),
    );
  }
}
