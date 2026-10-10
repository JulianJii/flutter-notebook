import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';

/// 清空回收站里的**文件夹**：物理删除全部已软删的行。
///
/// ⚠️ 回收站的「清空」按钮是跨三种实体的（笔记 / 文件夹 / 待办），但它们分属
/// 不同 feature，domain 之间不能互相 import —— 所以调用方（回收站屏）依次调
/// 本用例、笔记的 `EmptyTrashUseCase`、待办的 `EmptyTodoTrashUseCase`。
/// 单条 SQL 保证「全清或不清」，UI 循环调 [PurgeFolderUseCase] 则会中途失败留下
/// 删一半的状态。
class EmptyFolderTrashUseCase {
  const EmptyFolderTrashUseCase(this._repository);

  final FolderRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.purgeAllTrashed();
}