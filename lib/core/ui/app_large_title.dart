import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 页面大标题（替代 AppBar 标题）。
///
/// 出现于 P5（`COMPONENT-INVENTORY.md` §2 #2）。⚠️ P1 / P2 的「笔记」「待办」
/// 已移进 `AppTopBar` 的 `title`（标题归顶栏），这里只剩设置页。
/// 取值来自 `UI-IMPLEMENTATION-SPEC.md` §4 P1「LargeTitle」：
/// 文案 24sp w700，左边距 12dp，上边距 16dp，下边距 12dp。
class AppLargeTitle extends StatelessWidget {
  const AppLargeTitle({required this.text, required this.textScale, super.key});

  /// 标题文案。调用方传已本地化的字符串
  /// （`AppLocalizations.of(context).notesTitle`）。
  final String text;

  /// P5「文字大小」的排版系数，由调用方 `ref.watch(textScaleFactorProvider)`
  /// 得到后传入。⛔ 必填无默认：P1 传真实值，P2 / P5 传 1（D2 / D5 上没有
  /// 「文字大小」这一行的消费方，见 `ARCHITECTURE-DESIGN.md` §4）。
  final double textScale;

  /// 上边距（顶部栏底部 → 大标题）。`UI-IMPLEMENTATION-SPEC.md` §2.3 `space.topBar` = 16dp。
  static const double topPadding = AppSpacing.topBar;

  /// 下边距。§4 P1「下边距 12dp」= `AppSpacing.pageH`。
  static const double bottomPadding = AppSpacing.pageH;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.pageH,
        top: topPadding,
        bottom: bottomPadding,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          // ⚠️ `displayTitle` 刻意不设 color（TASK-005 §4 硬规则），这里显式补。
          style: context.textStyles.displayTitle
              .scaled(textScale)
              .copyWith(color: context.colors.textPrimary),
        ),
      ),
    );
  }
}
