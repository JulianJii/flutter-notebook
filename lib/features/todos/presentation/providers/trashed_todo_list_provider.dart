import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trashed_todo_list_provider.g.dart';

/// 订阅回收站里的待办（软删除的，按删除时间倒序）。
///
/// 与 `todoListProvider` 同约定：drift watch 推流，恢复 / 永久删除后 UI 自动
/// 重建，调用方无需手动 invalidate。
///
/// ⛔ 放在 features/todos 而不是 notes：数据源是 `TodoRepository`，让 notes 的
/// 屏反向依赖 todos 的 provider 就成了 feature 之间的耦合。回收站屏**主动**
/// import 它（见 `RecentlyDeletedScreen`）—— 页面复用是允许的方向。
@riverpod
Stream<List<Todo>> trashedTodoList(Ref ref) {
  return ref.watch(watchTrashedTodosUseCaseProvider).call();
}