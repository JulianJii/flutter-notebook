import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:mynote/core/ui/app_breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// 宽屏（≥ [AppBreakpoints.rail]）下的左侧导航栏。
///
/// **纯视觉组件：只管画，不管导航** —— 导航由调用方（`NotesShell`）通过
/// [onTap] 处理，与 [AppBottomNav] 完全同构：同一份 [AppBottomNavItem] 数据、
/// 同一个 `selectedIndex`、同一个回调签名。两套导航共用一份数据，
/// 才不会出现「底栏改了、侧栏忘了」。
///
/// 视觉语言刻意沿用分类 TabBar 的「灰底白块」：底色与页面同为 [AppColors.bg]，
/// 选中项垫一块 [AppColors.surface] 的圆角白块并加粗文字。⛔ 不用底栏那套
/// 深色反白块 —— 竖排 88dp 宽时一整块深色会变成「窗口边上的黑条」。
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  /// 导航项（笔记 / 待办）。
  final List<AppBottomNavItem> items;

  /// 当前选中项下标。
  final int selectedIndex;

  /// 点击第 [index] 项。**只上报，不自己导航。**
  final ValueChanged<int> onTap;

  /// 选中块边长。40dp：比底栏的 28dp 大一号，竖排时才有「按钮」的量感。
  static const double _badgeSize = 40;

  /// 选中块内的图标尺寸。24dp 放进 40dp 方块各留 8dp，视觉不顶满。
  static const double _iconSize = 22;

  /// 单项总高（不含间距）。图标块 40 + 间距 4 + 标签 11 ≈ 55，取 64 保证触控。
  static const double _itemHeight = 64;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: AppBreakpoints.railWidth,
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(
          right: BorderSide(color: colors.divider, width: AppStroke.divider),
        ),
      ),
      child: Column(
        children: <Widget>[
          // 顶部留白：与自绘标题栏相邻时不能贴死，14dp 是「浮起但不散」的位置。
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            _NavRailItem(
              item: items[i],
              isSelected: i == selectedIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _NavRailItem extends StatelessWidget {
  const _NavRailItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final labelStyle =
        (isSelected
                ? textStyles.navLabel.copyWith(fontWeight: FontWeight.w600)
                : textStyles.navLabel)
            .copyWith(
              color: isSelected ? colors.textPrimary : colors.textSecondary,
            );

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Material(
          // Material 是 hover / splash 的绘制层：不用它的话
          // `InkWell.hoverColor` 在透明底上没有可叠加的载体。
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            hoverColor: colors.hoverOverlay,
            child: SizedBox(
              height: AppNavRail._itemHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: AppNavRail._badgeSize,
                    height: AppNavRail._badgeSize,
                    decoration: isSelected
                        ? BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(
                              AppRadius.navIcon,
                            ),
                          )
                        : null,
                    child: Icon(
                      item.icon,
                      size: AppNavRail._iconSize,
                      color: isSelected
                          ? colors.textPrimary
                          : colors.outlineControl,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(item.label, style: labelStyle, maxLines: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
