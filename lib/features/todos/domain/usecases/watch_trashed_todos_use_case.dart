import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';

/// 订阅回收站里的待办（`deleted_at IS NOT NULL`），按删除时间倒序。
///
/// 与 `WatchTodosUseCase` 同约定：返回 `Stream` 而非 `Either`，流错误由 UI 侧的
/// `AsyncValue.error` 表达。
class WatchTrashedTodosUseCase {
  const WatchTrashedTodosUseCase(this._repository);

  final TodoRepository _repository;

  Stream<List<Todo>> call() => _repository.watchTrashed();
}