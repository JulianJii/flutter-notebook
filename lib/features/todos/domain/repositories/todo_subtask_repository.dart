import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/entities/todo_subtask.dart';

/// 子项的领域抽象。实现在 data 层。
abstract class TodoSubtaskRepository {
  /// 订阅某条待办的子项。⛔ 不过滤父待办的删除态（见数据源注释）。
  Stream<List<TodoSubtask>> watchByTodo(String todoId);

  /// 新增一条子项。id 由 Repository 生成（uuid v4）。
  Future<Either<Failure, TodoSubtask>> create(TodoSubtask subtask);

  /// 更新（勾选 / 改标题）。实现内部**必须**刷 `updated_at` —— 它是合并键。
  Future<Either<Failure, Unit>> update(TodoSubtask subtask);

  /// 删除一条子项。命中 0 行 → `Left(CacheFailure)`。
  Future<Either<Failure, Unit>> delete(String subtaskId);
}