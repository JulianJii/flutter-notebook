import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/presentation/providers/todo_list_provider.dart';
import 'package:mynote/features/todos/presentation/providers/todo_reminder_provider.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// 「设置提醒时间」面板的结果：`clear` 为 true 时 [at] 必然是 null。
typedef SetReminderResult = ({DateTime? at, bool clear});

/// 点待办卡片弹出的小窗：只读标题 + 提醒时间 + 完成。
///
/// ⛔ 不抽 `AppBottomSheet`（§8「不建」清单）：Material 默认形态 + 现有的
/// `AppListTile` / `AppIconButton` 已经够，且字阶与间距跟页面内其他行同源。
/// Q14 → docs/OPEN-DESIGN-QUESTIONS.md（弹层视觉无稿，沿用 Material 默认）。
///
/// ⚠️ **标题只读**：改标题 / 删除仍走原来的 `AlertDialog`（[onEditTitle] 由页面
/// 传入），本窗不复制第二条能改同一字段的路径。
Future<void> showTodoReminderSheet({
  required BuildContext context,
  required Todo todo,
  required VoidCallback onEditTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) =>
        _TodoReminderSheet(todo: todo, onEditTitle: onEditTitle),
  );
}

class _TodoReminderSheet extends ConsumerStatefulWidget {
  const _TodoReminderSheet({required this.todo, required this.onEditTitle});

  final Todo todo;

  final VoidCallback onEditTitle;

  @override
  ConsumerState<_TodoReminderSheet> createState() => _TodoReminderSheetState();
}

class _TodoReminderSheetState extends ConsumerState<_TodoReminderSheet> {
  /// 面板里的提醒时刻。⚠️ 不从 provider 读：设置成功后 drift 的 watch 会推新值
  /// 回来，但那要等一帧，本地这份让 UI 立刻响应（列表页的实体随后同步）。
  late DateTime? _reminderAt = widget.todo.reminderAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    // 标题 / 勾选态取 **stream 的最新值**：小窗里改标题后，库推新行回来，这里跟着
    // 变（否则弹窗关掉后小窗还挂着旧标题）。`indexWhere` 而不是 `firstWhere`：
    // 老版本 Dart 的 `Iterable` 没有 `firstOrNull`。
    final live = ref.watch(todoListProvider).value ?? const <Todo>[];
    final index = live.indexWhere((t) => t.id == widget.todo.id);
    final todo = index == -1 ? widget.todo : live[index];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.rowPadH,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      todo.title,
                      style: context.textStyles.rowTitleStrong.copyWith(
                        color: todo.isDone
                            ? colors.textTertiary
                            : colors.textPrimary,
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: AppIcons.edit,
                    tooltip: l10n.editTodo,
                    onPressed: widget.onEditTitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppListTile(
              title: l10n.todoReminder,
              leading: AppIcon(
                icon: AppIcons.alarm,
                size: AppSpacing.rowIconSize,
                color: _reminderAt == null
                    ? colors.textTertiary
                    : colors.accent,
              ),
              trailingValue: _reminderAt == null
                  ? l10n.todoReminderNone
                  : AppUtils.formatLocaleDateTime(context, _reminderAt!),
              trailing: AppIconButton(
                icon: AppIcons.clock,
                tooltip: l10n.todoReminderPickTime,
                onPressed: _pickReminder,
              ),
              onTap: _pickReminder,
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.rowPadH,
              ),
              child: FilledButton(
                onPressed: () => _toggleDone(todo),
                child: Text(todo.isDone ? l10n.todoReopen : l10n.todoComplete),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开「设置提醒时间」面板并落库。**只在确定后写** —— 面板里的日期 / 时间
  /// 改动是本地的，取消不留痕。
  Future<void> _pickReminder() async {
    final result = await showSetReminderSheet(
      context: context,
      initial: _reminderAt,
    );
    if (result == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    final TodoReminderResult outcome;
    if (result.clear) {
      outcome = await ref.read(todoReminderProvider).clear(widget.todo);
    } else {
      final at = result.at;
      if (at == null) return;
      outcome = await ref
          .read(todoReminderProvider)
          .set(widget.todo, at, l10n.todoReminderNotificationBody);
    }
    if (!mounted) return;

    switch (outcome) {
      case TodoReminderResult.ok:
        setState(() => _reminderAt = result.clear ? null : result.at);
        AppUtils.showSnackBar(
          context,
          message: result.clear
              ? l10n.todoReminderCleared
              : l10n.todoReminderSaved,
        );
      case TodoReminderResult.inThePast:
        AppUtils.showSnackBar(context, message: l10n.todoReminderPast);
      case TodoReminderResult.permissionDenied:
        AppUtils.showSnackBar(
          context,
          message: l10n.todoReminderPermissionDenied,
        );
      case TodoReminderResult.failed:
        AppUtils.showSnackBar(context, message: l10n.todoReminderFailed);
    }
  }

  /// 完成 / 重新打开。复用列表的勾选链路（乐观更新 + 失败回滚），不开第二条。
  Future<void> _toggleDone(Todo todo) async {
    final ok = await ref
        .read(todoOverridesProvider.notifier)
        .toggle(todo, !todo.isDone);
    if (!mounted) return;
    if (!ok) {
      AppUtils.showSnackBar(
        context,
        message: AppLocalizations.of(context).todoToggleFailed,
      );
      return;
    }
    Navigator.of(context).pop();
  }
}

/// 「设置提醒时间」：日期 + 时间两行，内置选择器（Q14：弹层沿用 Material 默认）。
///
/// 返回 null = 取消；否则 `(at: 时刻, clear: 是否点了清除)`。
Future<SetReminderResult?> showSetReminderSheet({
  required BuildContext context,
  DateTime? initial,
}) {
  return showModalBottomSheet<SetReminderResult>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _SetReminderSheet(initial: initial),
  );
}

class _SetReminderSheet extends StatefulWidget {
  const _SetReminderSheet({this.initial});

  final DateTime? initial;

  @override
  State<_SetReminderSheet> createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends State<_SetReminderSheet> {
  /// 默认「一小时后」：比「此刻」更可能就是用户想要的，且天然避开过去时刻。
  late DateTime _at = widget.initial ?? DateTime.now().add(_defaultLead);

  static const Duration _defaultLead = Duration(hours: 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.rowPadH,
              ),
              child: Text(
                l10n.todoReminderTitle,
                style: context.textStyles.rowTitleStrong.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppListTile(
              title: l10n.todoReminderDate,
              trailingValue: DateFormat.yMMMd(
                Localizations.localeOf(context).toString(),
              ).format(_at),
              onTap: _pickDate,
            ),
            AppListTile(
              dividerBefore: true,
              title: l10n.todoReminderTime,
              trailingValue: DateFormat.Hm(
                Localizations.localeOf(context).toString(),
              ).format(_at),
              onTap: _pickTime,
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.rowPadH,
              ),
              child: Row(
                children: <Widget>[
                  if (widget.initial != null)
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop((at: null, clear: true)),
                      child: Text(
                        l10n.todoReminderClear,
                        style: context.textStyles.rowTitle.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop((at: _at, clear: false)),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // 只允许今天起一年内的提醒：过去的选择器里选不了，`inThePast` 兜底也就
      // 只剩「今天早些时候」这一种情况。
      initialDate: _at,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _at = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _at.hour,
        _at.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _at = DateTime(
        _at.year,
        _at.month,
        _at.day,
        picked.hour,
        picked.minute,
      ),
    );
  }
}
