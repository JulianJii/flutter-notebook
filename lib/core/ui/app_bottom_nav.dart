import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_elevation.dart';
import 'package:init/core/theme/tokens/app_radius.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

// TODO(Q35): 底部导航项的按压/禁用态无稿，当前用 InkWell 默认涟漪
/// 底部标签栏（2 项）。**纯视觉组件：只管画，不管导航。**
///
/// 导航由调用方（`NotesShell`）通过 [onTap] 回调处理 —— 见
/// `ARCHITECTURE-DESIGN.md` §7.1。取值来自 `UI-IMPLEMENTATION-SPEC.md` §4 P1 BottomNav。
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  /// 2 项（D1/D2：笔记 / 待办）。等宽平分，不支持 3 项以上的设计稿依据。
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

/// 导航栏内容区高度，不含底部安全区。D1/D2 实测 ≈64dp。
///
/// **必须是顶层公开常量**：不能是 `AppBottomNav` 的静态成员，也不能叫 `_barHeight`。
/// TASK-033（`NoteMasonryGrid` 底部留白）/ TASK-034（P1 的 FAB 定位）/
/// TASK-042（P2 的 FAB 定位）三处都按它算「底部导航顶部 + 12dp」，且都是
/// **不带类名前缀**地引用。私有常量跨文件不可见、类成员常量需前缀，
/// 两种都会逼下游各复制一份字面量 64 然后互相漂移。
/// 改这一处即可，别在下游再定义同值常量。
const double kBottomNavContentHeight = 64;

/// 底部导航的单项。纯数据，不含业务语义（不认识「笔记」「待办」）。
class AppBottomNavItem {
  const AppBottomNavItem({required this.icon, required this.label});

  /// 24dp 线性图标（2dp 描边、圆端点）。D1/D2 底部导航。
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

  /// 选中态圆角方块底的边长。§4「≈28dp」。
  static const double _selectedBadgeSize = 28;

  /// 触控区最小边长。§2.5 尾注「触控区 ≥48dp」。
  static const double _minTapSize = 48;

  /// 方块底内的图形尺寸。§2.5 说图标 24dp，但 24dp 放进 28dp 的方块底只剩
  /// 2dp 边距、视觉上顶满 → 实测取 20。
  static const double _iconSize = 20;

  /// 图标与标签的间距。§2.5 未给；28 + 2 + 16(12sp 行高) = 46，在 64dp 栏内
  /// 上下各留 9。⚠️ 待按 D1/D2 截图量取复核。该值不建 token（只有一个调用点）。
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
