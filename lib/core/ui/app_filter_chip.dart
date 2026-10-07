import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// 分类筛选 chip（D1）。
///
/// 取值：`text.chip`；选中 `bg.chip.selected` 底 + `text.primary` 字，
/// 未选中 `surface` 底 + `text.secondary` 字；高度 28dp、左右内边距 12dp。
/// 圆角为 **pill 全圆角**（半径 = 高度的一半，见 [shape]）—— 目标稿里 chip
/// 是胶囊形，圆角方形与它不符。
///
/// ⛔ **自绘而非 Material `Chip`**：`Chip` 的 M3 默认值与设计冲突 4 处
/// （圆角 8 / labelPadding 8 / 最小高度 32 / 带 checkmark 槽位）。
///
/// ⛔ **本组件不含横向滚动**。chip 之间的 8dp 间距与滚动容器由 P1 自己决定。
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

  /// 圆角：pill 全圆角。半径 = [height] 的一半，由高度派生 —— 改高度自动跟随。
  ///
  /// ⚠️ 用 [BorderRadius] 而非 [StadiumBorder]：后者的水波漪裁剪不生效
  /// （`Material.borderRadius` / `InkWell.borderRadius` 都只接受
  /// `BorderRadius`），传 `StadiumBorder` 会退化成直角水波漪。
  static BorderRadius get shape => BorderRadius.circular(height / 2);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: selected ? colors.chipSelectedBg : colors.surface,
      borderRadius: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
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
