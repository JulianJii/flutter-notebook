import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 从回收站恢复待办：`deleted_at` 置 null + 刷新 `updated_at`。
///
/// ⚠️ 恢复**不会**自动把已排的系统通知挂回去（`reminder_at` 一直留在行上，
/// 但系统侧那条通知在删除时已被撤掉）。要继续提醒得重新设一次。
class RestoreTodoUseCase {
  const RestoreTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, Unit>> call(String todoId) {
    if (todoId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'todoId must not be empty')),
      );
    }
    return _repository.restore(todoId);
  }
}