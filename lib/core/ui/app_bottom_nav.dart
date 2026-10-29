import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/app_breakpoints.dart';
import 'package:mynote/core/ui/app_fab.dart';
import 'package:material_ui/material_ui.dart';

/// 底部标签栏（2 项）。**纯视觉组件：只管画，不管导航。**
///
/// 导航由调用方（`NotesShell`）通过 [onTap] 回调处理。取值来自笔记列表设计稿的
/// BottomNav。
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  /// 2 项（笔记列表稿/待办稿：笔记 / 待办）。等宽平分，不支持 3 项以上的设计稿依据。
  final List<AppBottomNavItem> items;

  /// 当前选中项下标。选中态由它推导，不放在 item 上。
  final int selectedIndex;

  /// 点击第 [index] 项。**只上报，不自己导航。**
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return DecoratedBox(
      // 顶部 1dp 分隔线；elevation.nav = 0（无阴影）。
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.divider, width: AppStroke.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kBottomNavContentHeight,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomNavItem(
                    item: items[i],
                    isSelected: i == selectedIndex,
                    colors: colors,
                    textStyles: textStyles,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 导航栏内容区高度，不含底部安全区。笔记列表稿/待办稿实测 ≈64dp。
///
/// **必须是顶层公开常量**：不能是 `AppBottomNav` 的静态成员，也不能叫 `_barHeight`。
/// 笔记瀑布流底部留白、笔记列表的 FAB 定位、待办的 FAB 定位三处都按它算
/// 「底部导航顶部 + 12dp」，且都是**不带类名前缀**地引用。私有常量跨文件不可见、
/// 类成员常量需前缀，两种都会逼下游各复制一份字面量 64 然后互相漂移。
/// 改这一处即可，别在下游再定义同值常量。
const double kBottomNavContentHeight = 64;

/// 页面内容需要为底部导航预留的高度：窄屏 = [kBottomNavContentHeight]，
/// 宽屏（左侧导航栏）= 0。
///
/// ⚠️ 存在的理由：FAB 定位、列表底部留白、多选动作栏三处都按
/// 「底部导航顶部 + 12dp」算，宽屏没有底栏，直接用 [kBottomNavContentHeight]
/// 会在 FAB 下面留一条 64dp 的空洞。所有这类位置一律改读本函数。
double navBottomInsetOf(BuildContext context) =>
    context.usesNavRail ? 0 : kBottomNavContentHeight;

/// FAB 距内容区底边的高度。
///
/// - 窄屏：`kBottomNavContentHeight + 12 - 8 - 30` = 38dp，即设计稿里 FAB 与
///   底栏重叠 26dp 的那一版（换算过程写在 `note_list_screen` 的旧注释里）。
/// - 宽屏：没有底栏，贴到内容区右下角（页面边距 12 + 8）。
///
/// ⚠️ 这个减法只在「有底栏」时成立：宽屏直接套会算出 **-26**，FAB 一半落到
/// 屏幕外。故收口到本函数，页面里不再各自写算式。
double fabBottomInsetOf(BuildContext context) {
  final nav = navBottomInsetOf(context);
  if (nav == 0) return AppSpacing.pageH + AppSpacing.sm;
  return nav + AppSpacing.pageH - AppSpacing.sm - 30;
}

/// 列表底部留白：底栏 + FAB 都不能遮住最后一项。
///
/// - 窄屏：`底栏高 + 12 + 安全区`（与设计稿的实测一致）。
/// - 宽屏：没有底栏，但 FAB 悬在右下角，留白改成「FAB 直径 + 页面边距」。
double listBottomInsetOf(BuildContext context) {
  final nav = navBottomInsetOf(context);
  return (nav > 0 ? nav : AppFab.size) +
      AppSpacing.pageH +
      MediaQuery.paddingOf(context).bottom;
}

/// 底部导航的单项。纯数据，不含业务语义（不认识「笔记」「待办」）。
class AppBottomNavItem {
  const AppBottomNavItem({required this.icon, required this.label});

  /// 24dp 线性图标（2dp 描边、圆端点）。笔记列表稿/待办稿底部导航。
  final IconData icon;

  /// 标签文案。调用方传已本地化的字符串（`AppLocalizations.of(context).xxx`）。
  final String label;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.colors,
    required this.textStyles,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool isSelected;
  final AppColors colors;
  final AppTextStyles textStyles;
  final VoidCallback onTap;

  /// 选中态圆角方块底的边长。设计稿实测 ≈28dp。
  static const double _selectedBadgeSize = 28;

  /// 触控区最小边长。触控区须 ≥48dp。
  static const double _minTapSize = 48;

  /// 方块底内的图形尺寸。设计稿的图标是 24dp，但 24dp 放进 28dp 的方块底只剩
  /// 2dp 边距、视觉上顶满 → 实测取 20。
  static const double _iconSize = 20;

  /// 图标与标签的间距。设计稿未给；28 + 2 + 16(12sp 行高) = 46，在 64dp 栏内
  /// 上下各留 9。⚠️ 待按笔记列表稿/待办稿截图量取复核。该值不建 token（只有一个调用点）。
  static const double _labelGap = 2;

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? colors.surface : colors.outlineControl;
    final labelStyle =
        (isSelected
                ? textStyles.navLabel.copyWith(fontWeight: FontWeight.w700)
                : textStyles.navLabel)
            .copyWith(
              color: isSelected ? colors.textPrimary : colors.textSecondary,
            );

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        // 触控区 ≥48dp；视觉上居中。
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minTapSize,
            minHeight: _minTapSize,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: _selectedBadgeSize,
                height: _selectedBadgeSize,
                // 选中：surface.inverse 圆角方块底；未选中：无底色。
                decoration: isSelected
                    ? BoxDecoration(
                        color: colors.surfaceInverse,
                        borderRadius: BorderRadius.circular(AppRadius.navIcon),
                      )
                    : null,
                child: Icon(item.icon, size: _iconSize, color: iconColor),
              ),
              const SizedBox(height: _labelGap),
              Text(item.label, style: labelStyle, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}
