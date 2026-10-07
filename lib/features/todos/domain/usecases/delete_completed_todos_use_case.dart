import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 批量清除全部已完成待办，返回删除行数。
///
/// ⛔ **无参数、无预检**：筛选条件只有一个（`is_done = 1`），由 SQL 表达。
/// 二次确认在 UI 层（`todo_list_screen._clearCompleted`）。
/// 0 行是合法结果 —— 本批已完成的就是「已经清空」。
class DeleteCompletedTodosUseCase {
  const DeleteCompletedTodosUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, int>> call() {
    return _repository.deleteCompleted();
  }
}
