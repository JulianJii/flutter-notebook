import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:mynote/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';
import 'package:mynote/features/todos/domain/usecases/create_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/delete_completed_todos_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/delete_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/empty_todo_trash_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/purge_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/restore_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/toggle_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/update_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/watch_todos_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/watch_trashed_todos_use_case.dart';
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

// ---- 回收站 ----
// 用例在 todos feature 装配，但共用 `/notes/trash` 这一页（页面本身在 notes）——
// 所以屏从 `features/todos/providers` 导入它们，这是允许的：presentation 可以
// 依赖任意 domain/DI provider，反向（domain → presentation）才禁止。

@riverpod
WatchTrashedTodosUseCase watchTrashedTodosUseCase(Ref ref) {
  return WatchTrashedTodosUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
RestoreTodoUseCase restoreTodoUseCase(Ref ref) {
  return RestoreTodoUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
PurgeTodoUseCase purgeTodoUseCase(Ref ref) {
  return PurgeTodoUseCase(ref.watch(todoRepositoryProvider));
}

@riverpod
EmptyTodoTrashUseCase emptyTodoTrashUseCase(Ref ref) {
  return EmptyTodoTrashUseCase(ref.watch(todoRepositoryProvider));
}
