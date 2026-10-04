import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';

/// 删除待办。业务规则：`todoId` 非空。
///
/// ⛔ 不预检存在性；⛔ 不加二次确认（D2 无删除入口，Q21 —— UseCase 先建，
/// UI 等补稿后再接，接线时**必须**先补二次确认）。
class DeleteTodoUseCase {
  const DeleteTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, Unit>> call(String todoId) {
    if (todoId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'todoId must not be empty')),
      );
    }
    return _repository.delete(todoId);
  }
}
