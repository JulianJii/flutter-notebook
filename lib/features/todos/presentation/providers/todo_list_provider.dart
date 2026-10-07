import 'package:mynote/core/logging/logger_provider.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/usecases/toggle_todo_params.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
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
      ToggleTodoParams(
        todoId: todo.id,
        title: todo.title,
        isDone: value,
        // 提醒不属于勾选语义，但 update 是全字段写入 —— 不传就没了。
        reminderAt: todo.reminderAt,
      ),
    );
    if (result.isLeft()) {
      // 回滚：草稿（乐观值）丢弃，UI 立即回到 stream 的权威值。
      state = previous;
      // 失败提示落在 Screen 层（`todo_list_screen._toggle` 收到 false 弹 Snackbar），
      // **不改本 provider** —— 它不碰 BuildContext。
      // ⚠️ 日志不记 todo 的 title（隐私，`DEVELOPMENT-GUIDELINES.md` §4）。
      ref
          .read(taggedLoggerProvider('todos'))
          .w('toggle todo failed', error: result);
      return false;
    }
    return true;
  }
}

/// 「已完成 N」折叠分组的展开态。默认折叠 —— 已完成项是低频内容，不该默认占屏。
///
/// 折叠态是**纯 UI 状态**，与列表数据无关，故不进 `TodoOverrides`，也不需要 invalidate。
@riverpod
class TodoDoneSection extends _$TodoDoneSection {
  @override
  bool build() => false;

  void toggle() => state = !state;

  /// 清除已完成后调用：已空的分隔行不该留在展开态。
  void collapse() => state = false;
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

// ⛔ 不排序：排序键 `is_done ASC, created_at DESC` 已在 `TodoDao` 的 SQL 里排完
// （`DEVELOPMENT-GUIDELINES.md` §4「DAO 排 SQL」）。折叠分组只做保序切分、不重排。
// ⛔ 本 provider 不管 create：写操作只有 toggle 需要乐观覆盖（它能失败并回滚），
// create 直接由 Screen 调 `createTodoUseCaseProvider`，新行同样由下面的 stream 推出。
// Q21 已接线：编辑 / 删除同样不进覆盖层 —— 它们没有「乐观」可言（弹窗关掉就没有
// 乐观态可回滚），失败走 Snackbar 即可。
