import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';
import '../../domain/utils/note_delta.dart';
import 'note_background_image.dart';

/// 笔记列表稿的笔记卡：标题 → 摘要 → 日期 三段竖排。
///
/// 容器直接复用 `AppCard` —— 全 App 只有一种卡片外观（12dp 圆角、
/// `elevation.card` = 0），不许在这里自绘 `Container`。
/// 有背景时在 `AppCard` 内加一层 `Stack` 把纸纹铺满整卡（圆角由 `Card` 的
/// `Clip.antiAlias` 裁），内边距因此改由内容层自己带。
///
/// 参数收整个 [Note] 而不是 `title / snippet / date`：摘要规则（空 → 占位文案）
/// 与日期格式是**卡片的表现规则**，只有一个消费方，放组件内改一处。
class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.note,
    super.key,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final Note note;

  /// 多选模式下的选中态：主色描边 + 右上角勾选角标。
  final bool selected;

  /// 长按回调（多选模式的入口）。
  final VoidCallback? onLongPress;

  /// 摘要最大行数。**卡片高度就是瀑布流的错落来源**：上限卡在 2 行时短正文
  /// 与长正文的卡片几乎等高，两列排下来观感退化成等高网格。放宽到 6 行后
  /// 短笔记 1 行、长笔记占满 6 行，高度差才撑得起笔记列表稿的错落。
  static const int _kSnippetMaxLines = 6;

  /// null → 静态卡片（按压态沿用 Material 默认）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final snippet = _snippetOf(context, note.content);
    final background = noteBackgroundImageOrNull(note.background);

    final card = AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        note.title,
                        style: textStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 置顶 / 收藏角标。**必须显出来**：置顶把笔记顶到列表最前，
                    // 不给标记用户会以为排序坏了；收藏更是全靠这个才看得见。
                    if (note.isPinned)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: AppIcon(
                          key: Key('note_card_pinned'),
                          icon: AppIcons.pushPinFilled,
                          size: 14,
                        ),
                      ),
                    if (note.isFavorite)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: AppIcon(
                          key: Key('note_card_favorite'),
                          icon: AppIcons.starFilled,
                          size: 14,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  snippet,
                  style: textStyles.snippet.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: _kSnippetMaxLines,
                  overflow: TextOverflow.ellipsis,
                ),
                // 标签 chip：最多 3 个 + 「+n」。无标签不占行高。
                if (note.tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  _TagStrip(names: note.tags),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  // 取 updatedAt：笔记列表默认排序键就是 editedDesc，卡片日期与排序依据
                  // 一致，用户不会看到「排在最前但日期最旧」。笔记列表稿只显示 `M月D日`，
                  // 无法区分 created / updated，此处取前者是成本最低的一致解。
                  DateFormat.MMMd(
                    Localizations.localeOf(context).toString(),
                  ).format(note.updatedAt),
                  style: textStyles.meta.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!selected) return card;
    // 多选选中态：主色描边 + 右上角勾选角标。描边画在覆盖层而不动 AppCard
    // （core/ui 不认识业务），圆角沿用主题的 `AppRadius.card`。
    return Stack(
      children: <Widget>[
        card,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: colors.accent, width: 2),
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.check,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 正文为空时显示占位文案（`noteSnippetPlaceholder`），不是用户数据。
  String _snippetOf(BuildContext context, String content) {
    // `content` 是 Quill Delta JSON，卡片只取纯文本 —— 摘要规则里的「空」判定
    // 依据是「用户没写正文」，而不是「文档结构为空」。
    final trimmed = NoteDelta.plainText(content).trim();
    return trimmed.isEmpty
        ? AppLocalizations.of(context).noteSnippetPlaceholder
        : trimmed;
  }
}

/// 卡片底部的标签条：小号 chip，最多 3 个 + 「+n」。
/// 纯展示（点卡片本身是进入详情），可点击的打标在详情页。
class _TagStrip extends StatelessWidget {
  const _TagStrip({required this.names});

  /// 卡片内最多亮 3 个标签 —— 瀑布流的错落来自摘要行数，标签多了会把卡片
  /// 撑成标签墙；剩下的折叠成「+n」。
  static const int _maxShown = 3;

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final shown = names.take(_maxShown);
    final overflow = names.length - _maxShown;

    return Wrap(
      spacing: AppSpacing.chipGap / 2,
      runSpacing: AppSpacing.chipGap / 2,
      children: <Widget>[
        for (final name in shown)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              name,
              style: textStyles.meta.copyWith(color: colors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: textStyles.meta.copyWith(color: colors.textTertiary),
          ),
      ],
    );
  }
}
