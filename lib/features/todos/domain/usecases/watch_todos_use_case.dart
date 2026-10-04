import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';

/// 订阅全量待办。**唯一的 P2 列表数据入口**。
///
/// ⛔ 不返回 `Either`；⛔ 不做二次排序（`created_at DESC` 在 `TodoDao` 的 SQL 里）；
/// ⛔ 不继承 `UseCase` 基类，只复用它的 [NoParams]。
class WatchTodosUseCase {
  const WatchTodosUseCase(this._repository);

  final TodoRepository _repository;

  Stream<List<Todo>> call(NoParams params) => _repository.watchAll();
}
