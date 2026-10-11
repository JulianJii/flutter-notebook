import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/todos/domain/entities/todo_priority.dart';
import 'package:mynote/features/todos/domain/entities/todo_recurrence.dart';
import 'package:mynote/features/todos/domain/entities/todo_subtask.dart';
import 'package:mynote/features/todos/presentation/providers/todo_subtask_provider.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 待办编辑弹窗里的**优先级**选择器：三枚互斥的 chip。
///
/// ⚠️ 视觉无稿，沿用 Material `ChoiceChip` 默认形态（与文件夹管理的无稿弹窗同一
/// 套取舍）。⛔ 不新造 `core/ui` 组件：整个 App 只有这一个选择器会用到三态互斥
/// chip，为它建组件等于把一个调用点的样式提升成全局约定。
///
/// ⛔ **普通也在列表里**而不是「普通 = 什么都不选」：普通是三档里的**一等公民**
/// （大多数待办都是普通），做成「默认不选」会让用户看不出「当前是普通」还是
/// 「当前是重要但忘了选」。
class TodoPriorityPicker extends StatelessWidget {
  const TodoPriorityPicker({required this.value, required this.onChanged, super.key});

  final TodoPriority value;

  final ValueChanged<TodoPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      children: <Widget>[
        for (final priority in TodoPriority.values)
          ChoiceChip(
            key: Key('todo_priority_${priority.id}'),
            label: Text(_labelOf(l10n, priority)),
            selected: priority == value,
            onSelected: (_) => onChanged(priority),
          ),
      ],
    );
  }

  /// 穷尽三档，无 default —— 新增档位时编译失败。
  static String _labelOf(AppLocalizations l10n, TodoPriority priority) =>
      switch (priority) {
        TodoPriority.normal => l10n.todoPriorityNormal,
        TodoPriority.important => l10n.todoPriorityImportant,
        TodoPriority.urgent => l10n.todoPriorityUrgent,
      };
}

/// 待办编辑弹窗里的**重复规则**选择器。
///
/// ⛔ **「不重复」是一枚显式 chip 而不是空状态**：与优先级同理，空状态说不清
/// 「当前没设重复」和「这一栏不存在」。
class TodoRecurrencePicker extends StatelessWidget {
  const TodoRecurrencePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// null = 不重复。
  final TodoRecurrence? value;

  final ValueChanged<TodoRecurrence?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      children: <Widget>[
        ChoiceChip(
          key: const Key('todo_recurrence_none'),
          label: Text(l10n.todoRecurrenceNone),
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final recurrence in TodoRecurrence.values.where(
          (r) => r != TodoRecurrence.none,
        ))
          ChoiceChip(
            key: Key('todo_recurrence_${recurrence.id}'),
            label: Text(_labelOf(l10n, recurrence)),
            selected: recurrence == value,
            onSelected: (_) => onChanged(recurrence),
          ),
      ],
    );
  }

  static String _labelOf(AppLocalizations l10n, TodoRecurrence recurrence) =>
      switch (recurrence) {
        TodoRecurrence.daily => l10n.todoRecurrenceDaily,
        TodoRecurrence.weekly => l10n.todoRecurrenceWeekly,
        TodoRecurrence.monthly => l10n.todoRecurrenceMonthly,
        TodoRecurrence.none => l10n.todoRecurrenceNone,
      };
}

/// 子任务清单（编辑弹窗里的一栏）。
///
/// **订阅 `watchByTodo` 而不是收一个外部列表**：子项的增删改都要立刻反映在
/// 弹窗里，而弹窗是 `showDialog` 开的、生命周期独立于页面。drift 的 watch 会
/// 自己把新行推回来，UI 不用手动 `setState`。
///
/// ⚠️ 新增走「输入 + 回车」的**行内**形式而不是再加一个弹窗：子项是一句话的东西，
/// 为它套一层弹窗会让人连加三个子项要点三次弹窗。
///
/// ⛔ **新建待办时不渲染这一栏**：待办还没有 id（`create` 之后才有），子项的
/// 外键指向一个不存在的行，写进去必然被外键拒绝。
class TodoSubtaskSection extends ConsumerStatefulWidget {
  const TodoSubtaskSection({required this.todoId, super.key});

  final String todoId;

  @override
  ConsumerState<TodoSubtaskSection> createState() => _TodoSubtaskSectionState();
}

class _TodoSubtaskSectionState extends ConsumerState<TodoSubtaskSection> {
  // ⛔ 不用 `TextEditingController`：见 `folder_manager_screen` 的同类说明 ——
  // `showDialog` 的 future 在 pop 时完成而退出动画还在跑，立即 dispose 会让仍在
  // 重建的 TextField 拿到已释放的 controller。
  var _entered = '';

  Future<void> _add() async {
    final title = _entered.trim();
    if (title.isEmpty) return;
    setState(() => _entered = '');
    await ref
        .read(todoSubtaskControllerProvider.notifier)
        .add(widget.todoId, title);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subtasks =
        ref.watch(todoSubtasksProvider(widget.todoId)).value ?? const [];
    final controller = ref.read(todoSubtaskControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(l10n.todoSubtasks, style: context.textStyles.rowTitle),
            const SizedBox(width: AppSpacing.sm),
            if (subtasks.isNotEmpty)
              Text(
                l10n.todoSubtaskProgress(
                  subtasks.where((s) => s.isDone).length,
                  subtasks.length,
                ),
                style: context.textStyles.meta.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final subtask in subtasks)
          _SubtaskRow(
            subtask: subtask,
            onToggle: () => controller.toggle(subtask),
            onDelete: () => controller.remove(subtask.id),
          ),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: const Key('todo_subtask_input'),
                decoration: InputDecoration(
                  hintText: l10n.todoSubtaskAddHint,
                  isDense: true,
                ),
                onChanged: (value) => _entered = value,
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppIconButton(
              key: const Key('todo_subtask_add'),
              icon: AppIcons.plus,
              tooltip: l10n.todoSubtaskAdd,
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }
}

/// 子任务的一行：勾选框 + 标题 + 删除。
///
/// ⚠️ 删除**不二次确认**：一行子项的代价是一句话，而一个确认框会让「删错了退回来」
/// 变成用户必须做的额外动作。真正的兜底是它不进回收站这件事本身（见
/// `todo_subtasks_table.dart`）—— 所以这里要**静默但可预期**，不给用户一个
/// 需要确认的错觉。
class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
  });

  final TodoSubtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AppCheckbox(value: subtask.isDone, onChanged: (_) => onToggle()),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            subtask.title,
            style: context.textStyles.rowTitle.copyWith(
              color: subtask.isDone
                  ? context.colors.textTertiary
                  : context.colors.textPrimary,
              decoration: subtask.isDone ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppIconButton(
          key: Key('todo_subtask_delete_${subtask.id}'),
          icon: AppIcons.close,
          tooltip: AppLocalizations.of(context).delete,
          onPressed: onDelete,
        ),
      ],
    );
  }
}