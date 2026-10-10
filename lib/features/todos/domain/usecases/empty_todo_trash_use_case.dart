import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 清空回收站里的**待办**：物理删除全部已软删的行。
///
/// ⚠️ 回收站的「清空」按钮跨三种实体，但它们分属不同 feature，domain 不能互相
/// import —— 调用方（回收站屏）依次调本用例、笔记的 `EmptyTrashUseCase`、
/// 文件夹的 `EmptyFolderTrashUseCase`。
class EmptyTodoTrashUseCase {
  const EmptyTodoTrashUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.purgeAllTrashed();
}