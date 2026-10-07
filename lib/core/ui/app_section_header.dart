import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 设置分组标题（设置稿）。
///
/// 取值来自 `UI-IMPLEMENTATION-SPEC.md` §4 设置结构规则：
/// 左缩进 28dp、上边距 ≈16dp、下边距 ≈8dp；字色 `text.sectionHeader`（#A0A0A0）。
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({required this.text, super.key});

  /// 标题文案，由调用方传 l10n 结果。
  final String text;

  /// 左缩进。§2.3 `space.sectionHeader.indent` = 28dp。
  /// 语义：比卡片左边界（12dp）外扩 16dp，与卡片内行的文字左边界对齐。
  static const double indent = AppSpacing.sectionHeaderIndent;

  /// 上边距。§4 设置「标题上 ≈16dp」= [AppSpacing.topBar]。
  static const double topPadding = AppSpacing.topBar;

  /// 下边距。§4 设置「标题下 ≈8dp」= [AppSpacing.chipGap]。
  static const double bottomPadding = AppSpacing.chipGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: indent,
        top: topPadding,
        bottom: bottomPadding,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        // 分组标题在 §2.2 的 13 个字阶里没有，取最接近的 `text.subtitle`。
        child: Text(
          text,
          style: context.textStyles.subtitle.copyWith(
            color: context.colors.textSectionHeader,
          ),
        ),
      ),
    );
  }
}
