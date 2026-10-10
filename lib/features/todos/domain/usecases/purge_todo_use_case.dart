import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 回收站的「永久删除」：**物理**删一个待办（不可恢复、不跨设备传播）。
///
/// ⚠️ 物理删除不留痕，别端下次同步会把它带回来 —— 见 `docs/FEATURES.md`
/// 「已知限制」。
/// 二次确认是 UI 层的事，UseCase 不管。
class PurgeTodoUseCase {
  const PurgeTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, Unit>> call(String todoId) {
    if (todoId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'todoId must not be empty')),
      );
    }
    return _repository.purge(todoId);
  }
}