import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/todos/domain/entities/todo.dart';

/// 待办的领域抽象。实现在 data 层（`TASK-022`）。
abstract class TodoRepository {
  /// 无筛选、无搜索、无分页（D2 就是一张平铺列表）。
  ///
  /// 流错误：Repository 实现负责把 `CacheException` 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<Todo>> watchAll();

  /// [Todo.id] 为空 → 实现内部生成 uuid v4。
  Future<Either<Failure, Todo>> create(Todo todo);

  /// 更新。勾选切换复用本方法（传目标 `isDone`），故支持乐观更新后的失败回滚。
  Future<Either<Failure, Todo>> update(Todo todo);

  /// 删除。
  Future<Either<Failure, Unit>> delete(String todoId);

  /// 批量清除已完成，返回删除行数。0 行是合法结果（已经清空），不是失败。
  Future<Either<Failure, int>> deleteCompleted();
}
