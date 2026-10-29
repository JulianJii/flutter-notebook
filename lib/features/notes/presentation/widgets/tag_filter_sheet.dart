import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/tag.dart';
import '../providers/tag_providers.dart';

/// 标签筛选底部弹层（笔记列表顶栏的入口）：chip 流式布局，点选即回调。
/// 再点已选中的 = 取消筛选（回调 null）。
Future<void> showTagFilterSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String? selectedTagId,
  required ValueChanged<String?> onSelected,
  required VoidCallback onManage,
}) {
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final colors = sheetContext.colors;
      final textStyles = sheetContext.textStyles;
      final tags = ref.watch(tagListProvider).value ?? const <Tag>[];

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.tags,
                style: textStyles.subtitle.copyWith(color: colors.textPrimary),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: tags.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          l10n.noTags,
                          style: textStyles.body.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: AppSpacing.chipGap,
                        runSpacing: AppSpacing.chipGap,
                        children: <Widget>[
                          for (final tag in tags)
                            TagChip(
                              key: Key('tag_filter_${tag.id}'),
                              label: tag.name,
                              selected: tag.id == selectedTagId,
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                onSelected(
                                  tag.id == selectedTagId ? null : tag.id,
                                );
                              },
                            ),
                        ],
                      ),
              ),
            ),
            // 管理入口：与筛选同居一个弹层 —— 标签的删除 / 重命名是低频动作，
            // 不值得顶栏再占一个位。
            ListTile(
              leading: const AppIcon(icon: AppIcons.settings),
              title: Text(
                l10n.manageTags,
                style: textStyles.body.copyWith(color: colors.textPrimary),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onManage();
              },
            ),
          ],
        ),
      );
    },
  );
}

/// 筛选/打标共用的 chip：选中 = 主色填充白字，未选中 = surface 底描边。
/// 两处视觉必须一致（同一套标注语言），故只此一份实现。
class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accent : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? colors.accent : colors.divider),
        ),
        child: Text(
          label,
          style: textStyles.chip.copyWith(
            color: selected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
