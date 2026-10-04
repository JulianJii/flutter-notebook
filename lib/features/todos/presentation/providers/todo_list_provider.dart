import 'package:init/core/logging/logger_provider.dart';
import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:init/features/todos/domain/usecases/toggle_todo_params.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_list_provider.g.dart';

/// 订阅待办列表。**零逻辑**：一个 `ref.watch` + 一个 `call()`。
///
/// `AsyncValue` 天然覆盖 loading / ready / error，`empty` 是 `value.isEmpty` 的
/// **派生**而非状态字段（`ARCHITECTURE-DESIGN.md` §6.2 P2 + §11 ADR 3）。
/// ⛔ 不加 `ref.invalidate` 手动刷新：drift watch 变了自动推（§8.4）。
@riverpod
Stream<List<Todo>> todoList(Ref ref) {
  return ref.watch(watchTodosUseCaseProvider)(NoParams());
}

/// 乐观覆盖层：仅在 `toggle` 与落库结果不一致期间生效。
///
/// **为什么不自持列表**（照抄 `TasksNotifier.toggleTask` 的写法）：它把列表 copy
/// 进 Notifier state，与 ADR 4「数据不进 Notifier，列表由 data 层 stream 持有」
/// 冲突，同一份数据两处写必然不一致；且 P1 的 `noteListProvider` 已确立
/// 「StreamProvider + AsyncValue」范式，P2 必须与之一致。
///
/// 核心洞察：**覆盖值等于 stream 值时覆盖就是无效的**（视觉完全一致），一旦不等
/// 它就是权威的。于是「何时清除覆盖」这个问题自动消失 —— 不需要 timer、不需要
/// listener、不需要等 stream 回调。
///
/// ponytail: map 只在 toggle 期间非空，条目为待办 uuid 字符串；155 条规模下
/// 累积上限 = 用户点击次数，可忽略。待办量到万级再考虑清理。
@riverpod
class TodoOverrides extends _$TodoOverrides {
  @override
  Map<String, bool> build() => const <String, bool>{};

  /// 勾选 / 取消勾选。返回落库是否成功。
  Future<bool> toggle(Todo todo, bool value) async {
    final previous = state;
    state = <String, bool>{...state, todo.id: value};
    final result = await ref.read(toggleTodoUseCaseProvider)(
      ToggleTodoParams(todoId: todo.id, title: todo.title, isDone: value),
    );
    if (result.isLeft()) {
      // 回滚：草稿（乐观值）丢弃，UI 立即回到 stream 的权威值。
      state = previous;
      // TODO(Q34): 失败反馈无稿（Snackbar / Toast / Dialog 整类缺失）。现阶段
      // 只回滚 + 记日志，返回 false 供调用方判断；Q34 补稿后落点是 Screen 层
      // `ref.listen` 提示，**不改本 provider**。
      // ⚠️ 日志不记 todo 的 title（隐私，`DEVELOPMENT-GUIDELINES.md` §4）。
      ref
          .read(taggedLoggerProvider('todos'))
          .w('toggle todo failed', error: result);
      return false;
    }
    return true;
  }
}

/// 把覆盖层叠加到 stream 的权威列表上。Screen 与测试共用这一份实现。
///
/// 覆盖值与 stream 值相等时 `when` 条件不成立 → 覆盖不再生效 → 视觉零变化。
List<Todo> applyTodoOverrides(
  List<Todo> todos,
  Map<String, bool> overrides,
) => <Todo>[
  for (final todo in todos)
    switch (overrides[todo.id]) {
      final value? when value != todo.isDone => todo.copyWith(isDone: value),
      _ => todo,
    },
];

// ⛔ 不排序：排序键 `created_at DESC` 已在 `TodoDao` 的 SQL 里排完
// （`DEVELOPMENT-GUIDELINES.md` §4「DAO 排 SQL」）。「已完成排到后面」无稿（Q21）。
// ⛔ 不实现 create / update / delete：
// TODO(Q7): D2 无新建落地页（FAB 新建待办如何输入无稿）。
// TODO(Q21): D2 无编辑 / 删除入口。
// Q7 / Q21 答了之后在**本文件**补齐，与已实现的 toggle 共用同一个 stream。
