import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_radius.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 分类筛选 chip（D1）。
///
/// 取值来自 `UI-IMPLEMENTATION-SPEC.md` §4 P1 FilterChips：
/// h 28dp、内边距 h 12dp、`text.chip`；选中 `bg.chip.selected` 底 + `text.primary` 字，
/// 未选中 `surface` 底 + `text.secondary` 字；圆角 `radius.chip` 12dp。
///
/// ⛔ **自绘而非 Material `Chip`**：`Chip` 的 M3 默认值与设计冲突 4 处
/// （圆角 8 / labelPadding 8 / 最小高度 32 / 带 checkmark 槽位）。
///
/// ⛔ **本组件不含横向滚动**。D1 只有 3 个 chip 且实测未溢出，滚动行为无证据
/// （§8 Q17）。chip 之间的 8dp 间距与滚动容器由 P1 自己决定（TASK-034）。
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    required this.label,
    required this.selected,
    required this.textScale,
    super.key,
    this.onTap,
  });

  /// 文案，由调用方传 l10n 结果。
  final String label;

  /// 是否选中。**选中态由页面持有**（它是筛选状态，不是组件内部状态）。
  final bool selected;

  /// P5「文字大小」的排版系数，由调用方 `ref.watch(textScaleFactorProvider)`
  /// 得到后传入。⛔ 必填无默认：P1 传真实值，P2 / P5 传 1（D2 / D5 上没有
  /// 「文字大小」这一行的消费方，见 `ARCHITECTURE-DESIGN.md` §4）。
  final double textScale;

  /// 点击回调。null → 不可点（D1 的 chip 均可点）。
  final VoidCallback? onTap;

  /// chip 高度。§4 P1「h 28dp」。
  static const double height = 28;

  /// 左右内边距。§4 P1「内边距 h 12dp」= [AppSpacing.pageH]。
  static const double horizontalPadding = AppSpacing.pageH;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.chip);

    return Material(
      color: selected ? colors.chipSelectedBg : colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.chip
                .scaled(textScale)
                .copyWith(
                  color: selected ? colors.textPrimary : colors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}
