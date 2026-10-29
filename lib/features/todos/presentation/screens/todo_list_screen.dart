import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';

import '../../domain/entities/todo.dart';
import '../../domain/entities/todo_priority.dart';
import '../../domain/entities/todo_recurrence.dart';
import '../../domain/usecases/update_todo_params.dart';
import '../../providers/todos_providers.dart';
import '../providers/todo_list_provider.dart';
import '../widgets/note_picker_sheet.dart';
import '../widgets/todo_card.dart';
import '../widgets/todo_edit_controls.dart';
import '../widgets/todo_reminder_sheet.dart';

/// 待办列表。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// 与笔记列表（`NoteListScreen`）结构同构，两处**故意**不同：
/// 1. 顶栏右侧**只有 1 个** `settings` 图标 ——待办稿上没有 `folder`，说明「顶栏按钮集
///   随页面变化，非全局固定」。⛔ 别照抄笔记列表的 2 个。
/// 2. 本页**无分类 chip / 无搜索 / 无排序入口** ——待办稿明确「本页无」。
///
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次。
/// 本 Screen 只为 FAB 定位引用 `kBottomNavContentHeight`。
/// ⛔ **不直接 watch Repository / UseCase**：数据链路固定为
/// Screen → `todoListProvider` → UseCase → Repository。
class TodoListScreen extends ConsumerWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // 乐观覆盖层由 `applyTodoOverrides` 叠加 —— Screen 与测试共用同一份纯函数，
    // 不在这里复刻一遍 `switch`。
    final all = applyTodoOverrides(
      ref.watch(todoListProvider).value ?? const <Todo>[],
      ref.watch(todoOverridesProvider),
    );
    // 顺序由 `TodoDao.watchAll` 的 `is_done ASC, created_at DESC` 提供，这里只
    // 保序切分、不重排。切分点在覆盖层**之后** —— 乐观勾选/回滚实时改变分组归属。
    final active = all.where((t) => !t.isDone).toList(growable: false);
    final done = all.where((t) => t.isDone).toList(growable: false);
    final expanded = ref.watch(todoDoneSectionProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        bottom: false,
        // 宽屏内容限宽 720 居中：待办是单列行，拉满 1400dp 时标题与复选框会
        // 隔着一整屏。窄屏上 `AppPageBody` 是零视觉变化的包装。
        // ⚠️ FAB 放在这层**之内**，因此它跟随内容列贴右，而不是贴到窗口右边缘。
        child: AppPageBody(
          maxWidth: 720,
          // 外层 `SafeArea(bottom: false)` 已经处理过安全区；这里再避一次底部
          // 会在手机上多出一条 home indicator 的留白。
          bottom: false,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  AppTopBar(
                    showDivider: false,
                    // 页面标题在顶栏内（与笔记列表一致）：标题与右侧图标同处一行。
                    title: Text(
                      l10n.todos,
                      style: context.textStyles.displayTitle.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    actions: <Widget>[
                      // 清空入口只在有已完成项时可用 —— 空分组上弹「确定清空吗」是噪音。
                      AppIconButton(
                        icon: AppIcons.trash,
                        tooltip: l10n.clearCompletedTodos,
                        onPressed: done.isEmpty
                            ? null
                            : () => _clearCompleted(context, ref, done),
                      ),
                      AppIconButton(
                        icon: AppIcons.settings,
                        // tooltip 传 l10n：`AppIconButton` 的 tooltip 是无障碍必需，
                        // 不是装饰（笔记列表稿~设置稿上都没有文字标签）。
                        tooltip: l10n.settings,
                        onPressed: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _TodoList(
                      active: active,
                      done: done,
                      expanded: expanded,
                      onToggleSection: () =>
                          ref.read(todoDoneSectionProvider.notifier).toggle(),
                      onChanged: (todo, value) =>
                          _toggle(context, ref, todo, value),
                      onEdit: (todo) => _openSheet(context, ref, todo),
                    ),
                  ),
                ],
              ),
              // FAB 用 `Stack` + `Positioned` 而**不是** `Scaffold.floatingActionButton`：
              // 后者的 z 序在 `bottomNavigationBar` 之下，而待办稿里 FAB 明确叠在
              // 底部导航之上；且 Material 默认 margin 是 16dp，与稿的 12dp 不符。
              Positioned(
                // 相对页面边距再往左下各挪 `sm`（8dp），下方向额外再下移 10dp。
                right: AppSpacing.pageH + AppSpacing.sm,
                // 窄屏压住底栏、宽屏贴内容区右下角（同笔记列表）。
                bottom: fabBottomInsetOf(context),
                child: AppFab(onPressed: () => _create(context, ref)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 新建待办。**弹窗视觉无稿**：与文件夹管理「新建文件夹」同一套
  /// `showDialog` + Material 默认样式，⛔ 不建 `AppDialog` / `AppBottomSheet`；
  /// 失败提示沿用 `AppUtils.showSnackBar`。
  ///
  /// 空标题校验在 `CreateTodoUseCase`（返回 `InputFailure`），页面不重复判断。
  /// 成功不需要 `ref.invalidate`：drift watch 推新行，`todoListProvider` 自建。
  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final outcome = await _titleDialog(
      context,
      ref: ref,
      titleText: l10n.createTodo,
    );
    final title = outcome?.title;
    if (title == null || title.trim().isEmpty) return;

    // ⛔ **不传 recurrence**：新建时 `reminderAt` 必为 null（提醒只能在待办落库
    // 之后、拿到真实 id 才能设），而「没提醒就重复」是无意义状态 —— 弹窗里已经
    // 用提示拦掉了，这里再兜一道是因为它不依赖 UI。
    final result = await ref
        .read(createTodoUseCaseProvider)
        .call(
          title,
          priority: outcome!.priority,
          linkedNoteId: outcome.linkedNoteId,
        );
    result.fold((failure) {
      if (context.mounted) {
        AppUtils.showSnackBar(context, message: failure.message);
      }
    }, (_) {});
  }

  /// 点卡片 → 详情小窗（提醒时间 + 完成）。
  ///
  /// 改标题 / 删除**不在这里做**：小窗只负责提醒与完成，标题编辑仍走原弹窗
  /// （小窗里的铅笔按钮回调回 [\_edit]），免得同一个字段有两条写入路径。
  Future<void> _openSheet(BuildContext context, WidgetRef ref, Todo todo) {
    return showTodoReminderSheet(
      context: context,
      todo: todo,
      onEditTitle: () => _edit(context, ref, todo),
    );
  }

  /// 编辑待办：改标题，或从同一个弹窗里删除。
  ///
  /// 勾选**不在**这里做 —— 卡片左侧的复选框才是勾选入口，弹窗里再放一个会出现
  /// 两个能改同一字段的地方，`todoOverridesProvider` 的乐观回滚也就无从判断
  /// 该回滚哪一个。
  ///
  /// ⚠️ 传 `todo.isDone` 而非重新取：`todo` 是 stream + 覆盖层叠加后的权威值，
  /// `UpdateTodoUseCase` 是全量覆盖写，漏传会把勾选状态抹掉。
  Future<void> _edit(BuildContext context, WidgetRef ref, Todo todo) async {
    final l10n = AppLocalizations.of(context);
    // 现挂笔记的标题（展示用）。读不到（已清扫）就退化为只显示 id 无标题态 ——
    // 用户仍可点「解除关联」。
    String? linkedTitle;
    if (todo.linkedNoteId != null) {
      final note = await ref
          .read(getNoteUseCaseProvider)
          .call(todo.linkedNoteId!);
      linkedTitle = note.fold((_) => null, (n) => n.title);
    }
    if (!context.mounted) return;

    final outcome = await _titleDialog(
      context,
      ref: ref,
      titleText: l10n.editTodo,
      initialValue: todo.title,
      withDelete: true,
      initialPriority: todo.priority,
      initialRecurrence: todo.recurrence,
      hasReminder: todo.reminderAt != null,
      subtaskTodoId: todo.id,
      initialLinkedNoteId: todo.linkedNoteId,
      initialLinkedNoteTitle: linkedTitle,
    );
    if (outcome == null || !context.mounted) return;

    if (outcome.remove) {
      await _confirmDelete(context, ref, todo);
      return;
    }

    final title = outcome.title;
    if (title == null || title.trim().isEmpty) return;

    // ⛔ 不在这里另写一条「改优先级」的路径：优先级与标题同属一次全字段覆盖写，
    // 分成两次写会让中间态被 `ReminderReconciler` 看见（它订阅待办流）而白对账一次。
    // 想「不改标题只改优先级」也不行 —— `update` 是全字段覆盖，但**都带上原值**
    // 就等价于只改一个字段。
    final result = await ref.read(updateTodoUseCaseProvider)(
      UpdateTodoParams(
        todoId: todo.id,
        title: title,
        isDone: todo.isDone,
        reminderAt: todo.reminderAt,
        priority: outcome.priority,
        recurrence: outcome.recurrence,
        linkedNoteId: outcome.linkedNoteId,
      ),
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) {},
    );
  }

  /// 删除二次确认。`DeleteTodoUseCase` 的注释明写「接线时**必须**先补二次确认」。
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Todo todo,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      content: l10n.deleteTodoConfirm,
      confirmLabel: l10n.delete,
    );
    if (confirmed != true || !context.mounted) return;

    // ⛔ 不在这里撤通知：平台通知的真相源是库，`ReminderReconciler` 订阅着待办流，
    // 软删除写完 `deleted_at` 就会触发一次全量对账，`cancelAll` 顺手带走这条。
    // 单独撤一次在这里是重复的真相源 —— 而重复的真相源正是「恢复后不响」漏掉的原因。
    final result = await ref.read(deleteTodoUseCaseProvider)(todo.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) {},
    );
  }

  /// 清除全部已完成（与编辑弹窗里的单条删除并列）。
  ///
  /// 成功后 `collapse()`：已空的分隔行不该留在展开态。
  /// ⛔ 不逐条撤通知：同 [_confirmDelete]，`ReminderReconciler` 的全量对账已经覆盖
  /// （`deleteCompleted` 是**单条 SQL**，对账只需等一次 emit，而逐条 await 是 N 次平台往返）。
  Future<void> _clearCompleted(
    BuildContext context,
    WidgetRef ref,
    List<Todo> done,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      content: l10n.clearCompletedTodosConfirm,
      confirmLabel: l10n.clearCompletedTodos,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(deleteCompletedTodosUseCaseProvider)();
    if (!context.mounted) return;
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) {
        ref.read(todoDoneSectionProvider.notifier).collapse();
        AppUtils.showSnackBar(context, message: l10n.emptyDone);
      },
    );
  }

  /// 二次确认弹窗。删除单条与清除全部共用同一形状（弹窗视觉无稿，沿用 Material
  /// 默认形态，与笔记详情 / 文件夹管理一致，故不抽 `AppDialog`）。
  ///
  /// 返回 true = 确认，false / null（点外面）= 取消。
  Future<bool?> _confirm(
    BuildContext context, {
    required String content,
    required String confirmLabel,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// 标题输入弹窗。新建与编辑共用 —— 结构相同，只差「初值」和「删除按钮」。
  ///
  /// 返回 `(title: 提交的标题, remove: 是否点了删除)`；取消时整个弹窗返回 null。
  /// ⛔ 不用 `TextEditingController`：同 `_promptCreateFolder` —— dialog 的 future
  /// 在 `pop` 时就完成，立即 dispose 会让仍在退场动画里的输入框拿到已释放的
  /// controller。预填交给 `TextFormField.initialValue`，它的 controller 随 widget
  /// 生命周期走，不需要我们管。
  /// 新建 / 编辑共用的弹窗。返回 `(title, priority, recurrence, remove)`；
  /// 取消返回 null，`remove: true` 表示走了删除分支。
  ///
  /// **优先级与重复规则在这一栏里改**，而不是等到保存 —— 它们是「这条待办长什么样」
  /// 的一部分，与标题同级；放进标题下方的单行输入框会让弹窗变成只能改一个字段。
  ///
  /// ⛔ **子任务不在这栏**：子项要立刻写库（drift watch 推回），而新建的待办
  /// 还没有 id（`create` 之后才有），外键会拒绝 —— 所以它只在 [withDelete] 的
  /// 编辑态渲染（`TodoSubtaskSection` 收一个已有的 todoId）。
  Future<
    ({
      String? title,
      TodoPriority priority,
      TodoRecurrence? recurrence,
      String? linkedNoteId,
      bool remove,
    })?
  >
  _titleDialog(
    BuildContext context, {
    required WidgetRef ref,
    required String titleText,
    String initialValue = '',
    bool withDelete = false,
    TodoPriority initialPriority = TodoPriority.normal,
    TodoRecurrence? initialRecurrence,
    bool hasReminder = false,
    String? subtaskTodoId,
    String? initialLinkedNoteId,
    String? initialLinkedNoteTitle,
  }) {
    final l10n = AppLocalizations.of(context);
    var entered = initialValue;
    var priority = initialPriority;
    var recurrence = initialRecurrence;
    var linkedNoteId = initialLinkedNoteId;
    var linkedNoteTitle = initialLinkedNoteTitle;
    return showDialog<
      ({
        String? title,
        TodoPriority priority,
        TodoRecurrence? recurrence,
        String? linkedNoteId,
        bool remove,
      })
    >(
      context: context,
      builder: (dialogContext) {
        // ⚠️ 选择器要重建才能反映选择 → 用 `StatefulBuilder`。
        // 与 `folder_manager_screen` 的名称弹窗同一取舍（一个弹窗一个 StatefulBuilder，
        // 不为它建一个 StatefulWidget）。
        void submit() => Navigator.of(dialogContext).pop((
          title: entered,
          priority: priority,
          recurrence: recurrence,
          linkedNoteId: linkedNoteId,
          remove: false,
        ));

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(titleText),
            content: SizedBox(
              // 弹窗内容一多（标题 + 两组 chip + 子任务）就会溢出，加这一行滚动。
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      key: const Key('todo_dialog_title'),
                      autofocus: true,
                      initialValue: initialValue,
                      decoration: InputDecoration(hintText: l10n.todoTitle),
                      onChanged: (value) => entered = value,
                      onFieldSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.todoPriority, style: context.textStyles.meta),
                    const SizedBox(height: AppSpacing.sm),
                    TodoPriorityPicker(
                      value: priority,
                      onChanged: (value) => setState(() => priority = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.todoRepeat, style: context.textStyles.meta),
                    const SizedBox(height: AppSpacing.sm),
                    TodoRecurrencePicker(
                      value: recurrence,
                      onChanged: (value) {
                        // ⛔ **没设提醒就不让选重复**：重复的是提醒时刻，而
                        // `reminder_at` 为 null 时重复规则没有任何东西可作用。
                        // 提示而不是静默忽略 —— 静默忽略会让用户以为规则已生效。
                        if (value != null && !hasReminder) {
                          AppUtils.showSnackBar(
                            context,
                            message: l10n.todoRecurrenceNeedsReminder,
                          );
                          return;
                        }
                        setState(() => recurrence = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _LinkedNoteRow(
                      linkedNoteId: linkedNoteId,
                      linkedNoteTitle: linkedNoteTitle,
                      onPick: () => showNotePickerSheet(
                        context,
                        ref: ref,
                        onSelected: (note) => setState(() {
                          linkedNoteId = note.id;
                          linkedNoteTitle = note.title.isEmpty
                              ? NoteDelta.plainText(note.content)
                              : note.title;
                        }),
                      ),
                      onUnlink: () => setState(() {
                        linkedNoteId = null;
                        linkedNoteTitle = null;
                      }),
                    ),
                    if (subtaskTodoId != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      TodoSubtaskSection(todoId: subtaskTodoId),
                    ],
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              if (withDelete)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop((
                    title: null,
                    priority: priority,
                    recurrence: recurrence,
                    linkedNoteId: linkedNoteId,
                    remove: true,
                  )),
                  child: Text(l10n.deleteTodo),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(onPressed: submit, child: Text(l10n.save)),
            ],
          ),
        );
      },
    );
  }

  /// 勾选回写。**只调 provider**：回滚逻辑是 `todoOverridesProvider` 的事，
  /// Screen 不重复实现、也不自己改列表。
  ///
  /// 落库失败时 provider 已回滚，这里补一句 Snackbar —— 静默回滚会让用户以为
  /// 勾上了（Snackbar 视觉无稿，沿用既有 `AppUtils.showSnackBar`）。
  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Todo todo,
    bool value,
  ) async {
    final ok = await ref
        .read(todoOverridesProvider.notifier)
        .toggle(todo, value);
    if (!ok && context.mounted) {
      AppUtils.showSnackBar(
        context,
        message: AppLocalizations.of(context).todoToggleFailed,
      );
    }
  }
}

class _TodoList extends StatelessWidget {
  const _TodoList({
    required this.active,
    required this.done,
    required this.expanded,
    required this.onToggleSection,
    required this.onChanged,
    required this.onEdit,
  });

  /// 未完成项。顺序即 `TodoDao.watchAll` 的 SQL 序。
  final List<Todo> active;

  /// 已完成项，同上序（沉在末尾）。
  final List<Todo> done;

  /// 「已完成 N」是否展开。
  final bool expanded;

  final VoidCallback onToggleSection;

  final void Function(Todo todo, bool value) onChanged;

  /// 点卡片本体 → 编辑弹窗。
  final void Function(Todo todo) onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 空状态内联 3 行，与 `RecentlyDeletedScreen` 的既有写法逐字一致，
    // ⛔ 不抽 `AppEmptyView`。
    if (active.isEmpty && done.isEmpty) {
      return Center(
        child: Text(
          l10n.emptyTodos,
          style: context.textStyles.subtitle.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      );
    }

    // 单个 ListView 承载「未完成 + 分隔行 + 已完成」，⛔ 不套两层：嵌套滚动 +
    // 各自 padding 是 bug 温床。`doneStart` = 首个已完成项的索引。
    final doneStart = active.length + 1;
    final itemCount = doneStart + (expanded ? done.length : 0);

    return ListView.separated(
      // 行间距沿用笔记列表稿的 `gridRow`(12dp) ——待办稿只有 1 张卡，间距无稿，但同 App
      // 统一间距比另开一个只被一处用的值便宜。
      padding: _padding(context),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.gridRow),
      itemBuilder: (context, index) {
        if (index == active.length) {
          return _DoneSectionHeader(
            count: done.length,
            expanded: expanded,
            onTap: onToggleSection,
          );
        }
        final todo = index < active.length
            ? active[index]
            : done[index - doneStart];
        return TodoCard(
          // key 不含 isDone → 勾选后卡片不因 key 变化而整体重建（视觉上只有复选框变）。
          key: ValueKey<String>(todo.id),
          title: todo.title,
          checked: todo.isDone,
          reminderAt: todo.reminderAt,
          priority: todo.priority,
          linkedNoteId: todo.linkedNoteId,
          onChanged: (value) => onChanged(todo, value),
          onTap: () => onEdit(todo),
        );
      },
    );
  }

  /// 底部留白 = 底部导航高 + 12dp + 安全区，与笔记列表 / 笔记详情同一约定（笔记列表稿实测卡片
  /// 曾被底栏直接裁切）。待办稿只有 1 张卡看不出裁切，但 FAB 会压住空区域 ——
  /// 不为「看不到」而省掉。
  // `listBottomInsetOf` 内部同理只用 `paddingOf`：后者对**全部** MediaQuery
  // 指标建依赖，键盘弹出 / 收起（改的是 `viewInsets`）都会重建整个列表。
  EdgeInsets _padding(BuildContext context) => EdgeInsets.fromLTRB(
    AppSpacing.pageH,
    0,
    AppSpacing.pageH,
    listBottomInsetOf(context),
  );
}

/// 「已完成 N」折叠分隔行。页面内私有组件（语义只属于本页，不上提 `core/ui`）。
class _DoneSectionHeader extends StatelessWidget {
  const _DoneSectionHeader({
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: AppLocalizations.of(context).todoDoneSection(count),
      titleWeight: FontWeight.w600,
      trailing: AppIcon(
        icon: expanded ? AppIcons.stepper : AppIcons.chevronRight,
      ),
      onTap: onTap,
    );
  }
}

/// 编辑弹窗里的「关联笔记」行：现挂标题（或空态提示）+ 点按选笔记 / 解除关联。
/// 选择结果只存弹窗本地变量，「保存」才落库 —— 与标题 / 优先级同一节奏。
class _LinkedNoteRow extends StatelessWidget {
  const _LinkedNoteRow({
    required this.linkedNoteId,
    required this.linkedNoteTitle,
    required this.onPick,
    required this.onUnlink,
  });

  final String? linkedNoteId;

  /// 现挂笔记的标题。null（读不到 / 已被清扫）时只显示通用提示，
  /// 用户仍可解除关联或换挂别的。
  final String? linkedNoteTitle;

  final VoidCallback onPick;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const AppIcon(icon: AppIcons.note),
      title: Text(
        l10n.todoLinkedNote,
        style: context.textStyles.body.copyWith(color: colors.textPrimary),
      ),
      subtitle: linkedNoteId == null
          ? null
          : Text(
              linkedNoteTitle ?? l10n.noteLinkMissing,
              style: context.textStyles.meta.copyWith(
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: linkedNoteId == null
          ? const AppIcon(icon: AppIcons.chevronRight)
          : AppIconButton(
              key: const Key('todo_dialog_unlink'),
              icon: AppIcons.close,
              tooltip: l10n.todoUnlink,
              onPressed: onUnlink,
            ),
      onTap: onPick,
    );
  }
}
