import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/folder_with_count.dart';
import '../providers/folder_provider.dart';

/// 批量移动的文件夹选择底部弹层：真实文件夹 + 「未分类」，选择即回调。
///
/// 页面私有级组件（只批量移动用），但带 [FolderWithCount] 业务类型，
/// 与 `_CategoryTabBar` 一样不进 `core/ui`。
Future<void> showFolderPickerSheet(
  BuildContext context, {
  required WidgetRef ref,
  required ValueChanged<String?> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final folders = ref.read(folderProvider).value ?? const <FolderWithCount>[];
      final l10n = AppLocalizations.of(sheetContext);
      final colors = sheetContext.colors;
      final textStyles = sheetContext.textStyles;

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.batchMoveToFolder,
              style: textStyles.subtitle.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                children: <Widget>[
                  // 「未分类」在首位：批量移动最常见的落点是「移出文件夹」。
                  _PickerRow(
                    key: const Key('folder_picker_uncategorized'),
                    icon: AppIcons.folder,
                    label: l10n.uncategorized,
                    onTap: () => _pop(sheetContext, null, onSelected),
                  ),
                  for (final item in folders)
                    _PickerRow(
                      key: Key('folder_picker_${item.folder.id}'),
                      icon: AppIcons.folder,
                      label: item.folder.name,
                      trailing: '${item.count}',
                      onTap: () => _pop(sheetContext, item.folder.id, onSelected),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 先关弹层再回调：回调里常伴随列表刷新与退出多选，留在弹层上下文里做会
/// 撞上「已 dispose」的边界。
void _pop(
  BuildContext sheetContext,
  String? folderId,
  ValueChanged<String?> onSelected,
) {
  Navigator.of(sheetContext).pop();
  onSelected(folderId);
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// 右侧计数（该文件夹下的笔记数）。null = 不显示。
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return ListTile(
      leading: AppIcon(icon: icon, color: colors.outlineControl),
      title: Text(
        label,
        style: textStyles.body.copyWith(color: colors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing == null
          ? const AppIcon(icon: AppIcons.chevronRight)
          : Text(
              trailing!,
              style: textStyles.meta.copyWith(color: colors.textTertiary),
            ),
      onTap: onTap,
    );
  }
}
