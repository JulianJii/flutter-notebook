import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/ui/app_icon.dart';
import 'package:material_ui/material_ui.dart';

/// 顶栏图标按钮。48dp 触控区 / 24dp 图形。
///
/// 触控区须 ≥48dp。出现在 5/5 页（笔记列表稿~设置稿顶栏）。
///
/// ⚠️ 顶栏 8 个图标的 `tooltip` 是**无障碍必需**，不是可选装饰 ——笔记列表稿~设置稿的稿上
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

  /// 点击回调。null → 按钮禁用（⚠️ 禁用态沿用 Material 默认）。
  final VoidCallback? onPressed;

  /// 长按提示，由调用方传 l10n 结果。
  final String? tooltip;

  /// 图形尺寸，默认 24dp。
  final double size;

  /// 图形颜色。
  final Color? color;

  /// 触控区最小边长。48dp。
  static const double minTapSize = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      // 悬停 / 聚焦用中性覆盖层，按压仍走主题主色：M3 默认把三者都用主色，
      // 在本 App 的琥珀配色上会浮出一圈明显的暖色光晕（同分类 TabBar 的
      // `overlayColor` 裁决）。⛔ 只在指针场景出现，窄屏与 golden 不受影响。
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.pressed)) {
            return Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.10);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return colors.hoverOverlay;
          }
          return null;
        }),
      ),
      icon: AppIcon(icon: icon, size: size, color: color),
      // 48dp 触控区，但不额外撑大视觉。IconButton 默认 padding 12dp 会让 48dp
      // 约束下总边长变成 72dp，故设 zero。
      constraints: const BoxConstraints(
        minWidth: minTapSize,
        minHeight: minTapSize,
      ),
      padding: EdgeInsets.zero,
    );
  }
}
