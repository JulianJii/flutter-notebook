import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';

/// D1 的笔记卡：标题 → 摘要 → 日期 三段竖排。
///
/// 容器直接复用 `AppCard` —— 全 App 只有一种卡片外观（`UI-IMPLEMENTATION-SPEC.md`
/// §2.4：12dp 圆角、`elevation.card` = 0），不许在这里自绘 `Container`。
///
/// 参数收整个 [Note] 而不是 `title / snippet / date`：摘要规则（空 → 占位文案）
/// 与日期格式是**卡片的表现规则**，只有一个消费方，放组件内改一处。
class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.note,
    required this.textScale,
    super.key,
    this.onTap,
  });

  final Note note;

  /// P5「文字大小」的排版系数，由 `NoteMasonryGrid` 透传。⛔ 必填无默认。
  final double textScale;

  /// null → 静态卡片（按压态无稿，见 Q35）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            note.title,
            style: textStyles.cardTitle
                .scaled(textScale)
                .copyWith(color: colors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _snippetOf(context, note.content),
            style: textStyles.snippet
                .scaled(textScale)
                .copyWith(color: colors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            // 取 updatedAt：P1 默认排序键就是 editedDesc，卡片日期与排序依据
            // 一致，用户不会看到「排在最前但日期最旧」。D1 只显示 `M月D日`，
            // 无法区分 created / updated，此处取前者是成本最低的一致解。
            DateFormat.MMMd(
              Localizations.localeOf(context).toString(),
            ).format(note.updatedAt),
            style: textStyles.meta
                .scaled(textScale)
                .copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  // TODO(Q20): 「无附加文案」是占位文案还是用户数据？Q20 答后可能删除此分支。
  String _snippetOf(BuildContext context, String content) {
    final trimmed = content.trim();
    return trimmed.isEmpty
        ? AppLocalizations.of(context).noteSnippetPlaceholder
        : trimmed;
  }
}
