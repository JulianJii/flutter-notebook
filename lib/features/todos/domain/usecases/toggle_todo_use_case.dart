import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';
import 'package:init/features/todos/domain/usecases/toggle_todo_params.dart';

/// 勾选 / 取消勾选。传**目标值**（[ToggleTodoParams.isDone]）而不是「翻转」。
///
/// ⚠️ 为什么不是翻转：P2 的勾选是**乐观更新**的 —— UI 先改本地状态再落库，
/// 失败要回滚（再写一次旧值）。翻转语义下「重试」会二次翻转，最终状态是反的。
///
/// ⛔ **回滚不在这一层**：回滚是 UI 的时间概念（`ARCHITECTURE-DESIGN.md` §6.2），
/// domain 只表达「落库意图」。
/// ⛔ 不建 `TodoRepository.toggle()`（`REPOSITORY-MAP.md` §1.3）—— 为一个字段
/// 扩接口会让 `update` 与 `toggle` 两个入口双写不一致。
class ToggleTodoUseCase {
  const ToggleTodoUseCase(this._repository);

  final TodoRepository _repository;

  Future<Either<Failure, Todo>> call(ToggleTodoParams params) {
    if (params.todoId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'todoId must not be empty')),
      );
    }
    final now = DateTime.now();
    return _repository.update(
      Todo(
        id: params.todoId,
        title: params.title,
        isDone: params.isDone,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
