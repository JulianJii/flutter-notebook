import 'package:init/core/ui/app_icon.dart';
import 'package:material_ui/material_ui.dart';

/// 顶栏图标按钮。48dp 触控区 / 24dp 图形。
///
/// 度量来自 `UI-IMPLEMENTATION-SPEC.md` §2.5 尾注：「触控区 ≥48dp」。
/// 出现在 5/5 页（D1~D5 顶栏）。
///
/// ⚠️ 顶栏 8 个图标的 `tooltip` 是**无障碍必需**，不是可选装饰 —— D1~D5 的稿上
/// 没有文字标签，不传 tooltip 等于给屏幕阅读器用户一个无名按钮。
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.size = AppIcon.defaultSize,
    this.color,
  });

  /// 图标字形。取值来自 [AppIcons]。
  final IconData icon;

  /// 点击回调。null → 按钮禁用（⚠️ 禁用态无稿，见 Q35）。
  final VoidCallback? onPressed;

  /// 长按提示，由调用方传 l10n 结果。
  final String? tooltip;

  /// 图形尺寸，默认 24dp。
  final double size;

  /// 图形颜色。
  final Color? color;

  /// 触控区最小边长。§2.5 尾注「触控区 ≥48dp」。
  static const double minTapSize = 48;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: AppIcon(icon: icon, size: size, color: color),
      // 48dp 触控区，但不额外撑大视觉。IconButton 默认 padding 12dp 会让 48dp
      // 约束下总边长变成 72dp，故设 zero。
      constraints: const BoxConstraints(
        minWidth: minTapSize,
        minHeight: minTapSize,
      ),
      padding: EdgeInsets.zero,
      // Q35 → docs/OPEN-DESIGN-QUESTIONS.md
    );
  }
}
