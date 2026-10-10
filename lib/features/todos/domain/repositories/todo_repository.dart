import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';

/// 待办的领域抽象。实现在 data 层（`TASK-022`）。
abstract class TodoRepository {
  /// 无筛选、无搜索、无分页（待办稿就是一张平铺列表）。**不含回收站里的**。
  ///
  /// 流错误：Repository 实现负责把 `CacheException` 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<Todo>> watchAll();

  /// [Todo.id] 为空 → 实现内部生成 uuid v4。
  Future<Either<Failure, Todo>> create(Todo todo);

  /// 更新。勾选切换复用本方法（传目标 `isDone`），故支持乐观更新后的失败回滚。
  Future<Either<Failure, Todo>> update(Todo todo);

  /// **软删除**（进回收站）。删除要能跨设备传播，故不物理删。
  Future<Either<Failure, Unit>> delete(String todoId);

  /// 从回收站恢复。实现内部会刷 `updatedAt` —— 合并比较键是
  /// `max(updatedAt, deletedAt)`，不刷则恢复同步不过去。
  Future<Either<Failure, Unit>> restore(String todoId);

  /// 回收站里的待办，按删除时间倒序。
  Stream<List<Todo>> watchTrashed();

  /// 回收站的「永久删除」：**物理**删行。只由回收站 UI 发起。
  Future<Either<Failure, Unit>> purge(String todoId);

  /// 清空回收站：**物理**删掉全部 `deleted_at IS NOT NULL` 的待办。
  ///
  /// ⛔ 单条 SQL 而不是在 UI 里循环 [purge]：循环中途失败会留下删一半的
  /// 不可解释状态。命中 0 行**不抛**（没有可清的项就是已清空）。
  Future<Either<Failure, Unit>> purgeAllTrashed();

  /// 批量**软删除**全部已完成，返回行数。0 行是合法结果（已经清空），不是失败。
  Future<Either<Failure, int>> deleteCompleted();
}
