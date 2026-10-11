import 'package:mynote/core/logging/logger_provider.dart';
import 'package:mynote/features/todos/domain/entities/todo_subtask.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_subtask_provider.g.dart';

/// 订阅某条待办的子项。
///
/// ⛔ 不按 todoId 做 `autoDispose`：编辑弹窗开着时页面可能重建，让流断掉会让
/// 弹窗里的清单闪一下。子项列表是弹窗的局部状态，它的生命周期跟着弹窗走就够了。
@riverpod
Stream<List<TodoSubtask>> todoSubtasks(Ref ref, String todoId) {
  return ref.watch(todoSubtaskRepositoryProvider).watchByTodo(todoId);
}

/// 子项的增删改。
///
/// **没有乐观更新**：勾一个子项的代价是一次 SQLite 写（亚毫秒），而乐观层要处理
/// 「流回来的值比用户下一次点击更慢」这一类交错。笔记与待办的乐观层是为了扛住
/// 每次按键的全量序列化，子项没有这个量级 —— 给它加一层是把简单的事做复杂。
/// 失败信号走 [lastFailure] + 日志，与 `todoOverridesProvider` 同形。
@riverpod
class TodoSubtaskController extends _$TodoSubtaskController {
  @override
  TodoSubtaskState build() => const TodoSubtaskState();

  Future<void> add(String todoId, String title) async {
    await _run(() async {
      await ref
          .read(todoSubtaskRepositoryProvider)
          .create(
            TodoSubtask(
              // id / 时间戳由 Repository 生成（uuid + AppClock），
              // 这里只给必填的两个。
              id: '',
              todoId: todoId,
              title: title,
              isDone: false,
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
    });
  }

  Future<void> toggle(TodoSubtask subtask) => _run(() async {
    await ref
        .read(todoSubtaskRepositoryProvider)
        .update(subtask.copyWith(isDone: !subtask.isDone));
  });

  Future<void> remove(String subtaskId) => _run(() async {
    await ref.read(todoSubtaskRepositoryProvider).delete(subtaskId);
  });

  /// 统一的「跑一次 + 记失败」外壳。
  ///
  /// ⛔ **失败只落日志 + state，不弹 Snackbar**：勾子项是个高频小动作，在它失败时
  /// 弹一个 Snackbar 会被连续操作刷屏，而它马上就会因为用户重试或同步而被覆盖。
  Future<void> _run(Future<void> Function() body) async {
    try {
      await body();
      if (state.lastFailure != null) {
        state = const TodoSubtaskState();
      }
    } on Object catch (e) {
      ref.read(taggedLoggerProvider('todos')).w('subtask op failed', error: e);
      state = TodoSubtaskState(lastFailure: e);
    }
  }
}

/// 子项控制器状态。⛔ 只承载「最近一次失败」，够 UI 读。
class TodoSubtaskState {
  const TodoSubtaskState({this.lastFailure});

  final Object? lastFailure;
}