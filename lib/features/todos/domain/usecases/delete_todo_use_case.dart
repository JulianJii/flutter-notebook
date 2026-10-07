import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 删除待办。业务规则：`todoId` 非空。
///
/// ⛔ 不预检存在性。**二次确认已在 UI 层补上**（`todo_list_screen._confirmDelete`），
/// 本use case 只表达「落库意图」。
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
