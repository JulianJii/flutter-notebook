import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';
import 'package:mynote/features/todos/domain/usecases/update_todo_params.dart';

/// 更新待办（改标题或勾选状态）。业务规则：`todoId` 非空、标题 trim 后非空。
///
/// 校验用 `trim()`，**存回 trim 后的值**。
/// ⛔ **不校验标题长度**（与 `CreateTodoUseCase` 同理，待办稿是单行卡片）。
class UpdateTodoUseCase {
  const UpdateTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, Todo>> call(UpdateTodoParams params) {
    if (params.todoId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'todoId must not be empty')),
      );
    }
    final title = params.title.trim();
    if (title.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'Todo title must not be empty')),
      );
    }
    final now = DateTime.now();
    return _repository.update(
      Todo(
        id: params.todoId,
        title: title,
        isDone: params.isDone,
        reminderAt: params.reminderAt,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
