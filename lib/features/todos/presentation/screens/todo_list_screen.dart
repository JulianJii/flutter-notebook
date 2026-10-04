import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/logging/logger_provider.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/todo.dart';
import '../providers/todo_list_provider.dart';
import '../widgets/todo_card.dart';

/// P2 待办列表（D2）。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// 与 P1（`NoteListScreen`）结构同构，两处**故意**不同：
/// 1. 顶栏右侧**只有 1 个** `settings` 图标 —— D2 上没有 `folder`，说明「顶栏按钮集
///    随页面变化，非全局固定」（`UI-IMPLEMENTATION-SPEC.md` §4 P2）。⛔ 别照抄 P1 的 2 个。
/// 2. 本页**无分类 chip / 无搜索 / 无排序入口** —— D2 明确「本页无」。
///
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次（`TASK-008`）。
/// 本 Screen 只为 FAB 定位引用 `kBottomNavContentHeight`。
/// ⛔ **不直接 watch Repository / UseCase**：数据链路固定为
/// Screen → `todoListProvider` → UseCase → Repository。
class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 乐观覆盖层由 `applyTodoOverrides` 叠加 —— Screen 与测试共用同一份纯函数，
    // 不在这里复刻一遍 `switch`（`TASK-040` 的契约）。
    // TODO(Q32): Loading 视觉无稿（首屏读库）。
    // TODO(Q33): Error 视觉无稿（读库失败）—— 只落日志，UI 保持空白。
    final todos = applyTodoOverrides(
      ref.watch(todoListProvider).value ?? const <Todo>[],
      ref.watch(todoOverridesProvider),
    );

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                AppTopBar(
                  actions: <Widget>[
                    AppIconButton(
                      icon: AppIcons.settings,
                      // tooltip 传 l10n：`AppIconButton` 的 tooltip 是无障碍必需，
                      // 不是装饰（D1~D5 稿上都没有文字标签）。
                      tooltip: AppLocalizations.of(context).settings,
                      onPressed: () => context.go(AppRoutes.settings),
                    ),
                  ],
                ),
                // `textScale: 1` —— P2 **不接** P5 的「文字大小」：D2 上没有这一行
                // 的消费方（`ARCHITECTURE-DESIGN.md` §4 的取值来源表只列了 P1
                // 卡片与 P3 正文）。跟着放大会改动 P2 的 golden 基线。
                AppLargeTitle(
                  text: AppLocalizations.of(context).todos,
                  textScale: 1,
                ),
                Expanded(
                  child: _TodoList(
                    todos: todos,
                    onChanged: (todo, value) => _toggle(ref, todo, value),
                  ),
                ),
              ],
            ),
            // FAB 用 `Stack` + `Positioned` 而**不是** `Scaffold.floatingActionButton`：
            // 后者的 z 序在 `bottomNavigationBar` 之下，而 D2 里 FAB 明确叠在
            // 底部导航之上；且 Material 默认 margin 是 16dp，与稿的 12dp 不符。
            Positioned(
              right: AppSpacing.pageH,
              bottom: kBottomNavContentHeight + AppSpacing.pageH,
              child: AppFab(
                onPressed: () {
                  // TODO(Q7): P2 的「新建待办」如何输入无稿（独立页 / 底部弹层 /
                  // 对话框三选一未答）。现在只记日志，不凭空造落地页。
                  ref
                      .read(taggedLoggerProvider('todos'))
                      .i('fab tapped, Q7 unresolved');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 勾选回写。**只调 provider**：回滚逻辑是 `todoOverridesProvider` 的事
  /// （`ARCHITECTURE-DESIGN.md` §6.2 P2），Screen 不重复实现、也不自己改列表。
  Future<void> _toggle(WidgetRef ref, Todo todo, bool value) async {
    // TODO(Q34): 失败反馈无稿（Snackbar / Toast / Dialog 整类缺失）。落库失败时
    // provider 已自动回滚，这里只记日志，不提示用户。
    if (!await ref.read(todoOverridesProvider.notifier).toggle(todo, value)) {
      ref.read(taggedLoggerProvider('todos')).w('todo toggle failed');
    }
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({required this.todos, required this.onChanged});

  final List<Todo> todos;

  final void Function(Todo todo, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    // TODO(Q31): 空状态无设计稿，不建视觉（与 P1 / P3 一致）。
    if (todos.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      // 行间距沿用 D1 的 `gridRow`(12dp) —— D2 只有 1 张卡，间距无稿，但同 App
      // 统一间距比另开一个只被一处用的值便宜。
      padding: _padding(context),
      itemCount: todos.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.gridRow),
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoCard(
          // key 不含 isDone → 勾选后卡片不因 key 变化而整体重建（视觉上只有复选框变）。
          key: ValueKey<String>(todo.id),
          title: todo.title,
          checked: todo.isDone,
          onChanged: (value) => onChanged(todo, value),
        );
      },
    );
  }

  /// 底部留白 = 底部导航高 + 12dp + 安全区，与 P1 / P3 同一约定（D1 实测卡片
  /// 曾被底栏直接裁切）。D2 只有 1 张卡看不出裁切，但 FAB 会压住空区域 ——
  /// 不为「看不到」而省掉。
  EdgeInsets _padding(BuildContext context) => EdgeInsets.fromLTRB(
    AppSpacing.pageH,
    0,
    AppSpacing.pageH,
    kBottomNavContentHeight +
        AppSpacing.pageH +
        MediaQuery.of(context).padding.bottom,
  );
}
