import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';
import '../../providers/notes_providers.dart';
import 'folder_picker_sheet.dart';

/// 笔记卡片的**右键上下文菜单**（桌面）。
///
/// 与移动端的长按多选互补而不是替代：长按仍是「进入多选」，右键是单篇的
/// 快捷动作 —— 桌面用户不会为了置顶一篇笔记先进多选模式。
///
/// ⚠️ 所有写操作都走**已有的批量 use case**（传单元素列表）：批量与单项共用
/// 同一条落库链路（同一套字段校验、同一次版本存版、同一次列表刷新），
/// 不另开一条「单篇」分支。
///
/// 视觉无稿：菜单用 Material 默认形态 + 主题色，删除项用危险色文字。
Future<void> showNoteContextMenu(
  BuildContext context, {
  required WidgetRef ref,
  required Note note,
  required Offset position,
  required VoidCallback onOpen,
  VoidCallback? onDeleted,
}) async {
  final l10n = AppLocalizations.of(context);
  final colors = context.colors;
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;

  final action = await showMenu<_NoteMenuAction>(
    context: context,
    // 在指针位置弹出：`RelativeRect` 是相对 overlay 的四边距离。
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    // 紧凑菜单：200dp 宽、行高 40dp（文案都是 2–4 个字，不需要默认的宽行）。
    constraints: const BoxConstraints(minWidth: 200, maxWidth: 220),
    items: <PopupMenuEntry<_NoteMenuAction>>[
      PopupMenuItem<_NoteMenuAction>(
        value: _NoteMenuAction.open,
        height: 40,
        child: _MenuRow(icon: AppIcons.note, label: l10n.openNote),
      ),
      PopupMenuItem<_NoteMenuAction>(
        value: _NoteMenuAction.pin,
        height: 40,
        child: _MenuRow(
          icon: note.isPinned ? AppIcons.pushPinFilled : AppIcons.pushPin,
          label: note.isPinned ? l10n.noteUnpin : l10n.notePin,
        ),
      ),
      PopupMenuItem<_NoteMenuAction>(
        value: _NoteMenuAction.favorite,
        height: 40,
        child: _MenuRow(
          icon: note.isFavorite ? AppIcons.starFilled : AppIcons.starOutline,
          label: note.isFavorite ? l10n.noteUnfavorite : l10n.noteFavorite,
        ),
      ),
      PopupMenuItem<_NoteMenuAction>(
        value: _NoteMenuAction.move,
        height: 40,
        child: _MenuRow(icon: AppIcons.folder, label: l10n.batchMove),
      ),
      PopupMenuItem<_NoteMenuAction>(
        value: _NoteMenuAction.delete,
        height: 40,
        child: _MenuRow(
          icon: AppIcons.trash,
          label: l10n.delete,
          color: colors.feedbackDanger,
        ),
      ),
    ],
  );

  // 菜单关闭后本页可能已经不在（例如「打开」进了详情页）：后续操作一律先判在树上。
  if (action == null || !context.mounted) return;

  switch (action) {
    case _NoteMenuAction.open:
      onOpen();
    case _NoteMenuAction.pin:
      await _run(
        context,
        ref.read(batchUpdateNoteFlagsUseCaseProvider).call(<String>[
          note.id,
        ], isPinned: !note.isPinned),
      );
    case _NoteMenuAction.favorite:
      await _run(
        context,
        ref.read(batchUpdateNoteFlagsUseCaseProvider).call(<String>[
          note.id,
        ], isFavorite: !note.isFavorite),
      );
    case _NoteMenuAction.move:
      await showFolderPickerSheet(
        context,
        ref: ref,
        onSelected: (folderId) => _run(
          context,
          ref.read(batchMoveNotesUseCaseProvider)(<String>[note.id], folderId),
        ),
      );
    case _NoteMenuAction.delete:
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(l10n.deleteNoteConfirm),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await _run(
        context,
        ref.read(batchDeleteNotesUseCaseProvider)(<String>[note.id]),
      );
      // 宽屏双栏：删掉的正是右栏那篇 → 顺手关掉，别留一张读不到数据的空壳。
      onDeleted?.call();
  }
}

/// 动作的统一出口：成功静默（列表自己会动），失败才出 SnackBar ——
/// 与全 App「不出成功提示」的既有惯例一致（同 `_SelectionActionBar._fire`）。
Future<void> _run(
  BuildContext context,
  Future<Either<Failure, int>> future,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final failureText = AppLocalizations.of(context).batchOperationFailed;
  final result = await future;
  result.fold(
    (_) => messenger.showSnackBar(SnackBar(content: Text(failureText))),
    (_) {},
  );
}

/// 右键菜单的动作。枚举而不是多个回调，`showMenu` 的返回值才能只 switch 一次。
enum _NoteMenuAction { open, pin, favorite, move, delete }

/// 菜单一行：图标 + 文案。五项共用，保证字形与间距一致。
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;

  /// null = 常规前景色；删除传 `feedbackDanger`（图标与文字一起变）。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.colors.textPrimary;
    return Row(
      children: <Widget>[
        AppIcon(icon: icon, size: 20, color: foreground),
        const SizedBox(width: AppSpacing.chipGap),
        Text(
          label,
          style: context.textStyles.rowTitle.copyWith(color: foreground),
        ),
      ],
    );
  }
}
