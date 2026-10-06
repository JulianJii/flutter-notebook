import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';
import '../../domain/utils/note_delta.dart';
import 'note_background_image.dart';

/// D1 的笔记卡：标题 → 摘要 → 日期 三段竖排。
///
/// 容器直接复用 `AppCard` —— 全 App 只有一种卡片外观（`UI-IMPLEMENTATION-SPEC.md`
/// §2.4：12dp 圆角、`elevation.card` = 0），不许在这里自绘 `Container`。
/// 有背景时在 `AppCard` 内加一层 `Stack` 把纸纹铺满整卡（圆角由 `Card` 的
/// `Clip.antiAlias` 裁），内边距因此改由内容层自己带。
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

  /// 摘要最大行数。**卡片高度就是瀑布流的错落来源**：上限卡在 2 行时短正文
  /// 与长正文的卡片几乎等高，两列排下来观感退化成等高网格。放宽到 6 行后
  /// 短笔记 1 行、长笔记占满 6 行，高度差才撑得起 D1 的错落。
  static const int _kSnippetMaxLines = 6;

  /// null → 静态卡片（按压态无稿，见 Q35）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final snippet = _snippetOf(context, note.content);
    final background = noteBackgroundImageOrNull(note.background);

    return AppCard(
      onTap: onTap,
      // 背景要铺满整张卡（含圆角），故内边距从 AppCard 挪到内容层自己带：
      // 默认那份 `AppSpacing.cardPad` 走 `AppCard.defaultPadding`，数值不变。
      padding: EdgeInsets.zero,
      child: Stack(
        children: <Widget>[
          if (background != null)
            Positioned.fill(
              child: Opacity(
                opacity: kNoteBackgroundOpacity,
                child: background.image(fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: AppCard.defaultPadding,
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
                  snippet,
                  style: textStyles.snippet
                      .scaled(textScale)
                      .copyWith(color: colors.textSecondary),
                  maxLines: _kSnippetMaxLines,
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
          ),
        ],
      ),
    );
  }

  // Q20 → docs/OPEN-DESIGN-QUESTIONS.md（「无附加文案」当前按占位文案处理）
  String _snippetOf(BuildContext context, String content) {
    // `content` 是 Quill Delta JSON，卡片只取纯文本 —— 摘要规则里的「空」判定
    // 依据是「用户没写正文」，而不是「文档结构为空」。
    final trimmed = NoteDelta.plainText(content).trim();
    return trimmed.isEmpty
        ? AppLocalizations.of(context).noteSnippetPlaceholder
        : trimmed;
  }
}
