import 'package:init/core/providers/database_providers.dart';
import 'package:init/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:init/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';
import 'package:init/features/todos/domain/usecases/create_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/delete_completed_todos_use_case.dart';
import 'package:init/features/todos/domain/usecases/delete_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/toggle_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/update_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/watch_todos_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todos_providers.g.dart';

// ⛔ **零 import `features/notes`**：features 之间不互相依赖（`FEATURE-DEPENDENCIES.md`
// R2）。⛔ provider 体只做装配。

// ---- data source ----
@riverpod
TodoLocalDataSource todoLocalDataSource(Ref ref) {
  return TodoLocalDataSourceImpl(ref.watch(appDatabaseProvider));
}

// ---- repository ----
@riverpod
TodoRepository todoRepository(Ref ref) {
  return TodoRepositoryImpl(ref.watch(todoLocalDataSourceProvider));
}

// ---- use case ----
@riverpod
WatchTodosUseCase watchTodosUseCase(Ref ref) {
  return WatchTodosUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
CreateTodoUseCase createTodoUseCase(Ref ref) {
  return CreateTodoUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
ToggleTodoUseCase toggleTodoUseCase(Ref ref) {
  return ToggleTodoUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
UpdateTodoUseCase updateTodoUseCase(Ref ref) {
  return UpdateTodoUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
DeleteTodoUseCase deleteTodoUseCase(Ref ref) {
  return DeleteTodoUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
DeleteCompletedTodosUseCase deleteCompletedTodosUseCase(Ref ref) {
  return DeleteCompletedTodosUseCase(ref.watch(todoRepositoryProvider));
}
