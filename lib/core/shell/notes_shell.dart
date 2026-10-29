import 'package:go_router/go_router.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:mynote/core/ui/app_breakpoints.dart';
import 'package:mynote/core/ui/app_icon.dart';
import 'package:mynote/core/ui/app_nav_rail.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 笔记 App 的 Shell 容器。笔记列表/待办两个 Tab 由它承载，切换时各自保状态。
///
/// **导航形态随宽度二选一**，数据与回调完全共用：
/// - < [AppBreakpoints.rail]（手机竖屏 / 窄窗口）：底部导航 [AppBottomNav]。
/// - ≥ [AppBreakpoints.rail]（Windows / 横屏平板）：左侧导航栏 [AppNavRail]，
///   内容区占右侧。宽屏下**不渲染底部导航**，`navBottomInsetOf` 因此返回 0，
///   各页 FAB / 列表底部留白自动归零。
///
/// 非 edge-to-edge：安全区由本组件自己包。
class NotesShell extends StatelessWidget {
  const NotesShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// 底部 / 侧边两项。标签由调用方（Shell）从 l10n 取 —— Shell 在 `core/` 内，
  /// 可以 import `gen/l10n`（不是 feature）。
  List<AppBottomNavItem> _items(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return <AppBottomNavItem>[
      AppBottomNavItem(icon: AppIcons.navNotes, label: l10n.notes),
      AppBottomNavItem(icon: AppIcons.navTodo, label: l10n.todos),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    final index = navigationShell.currentIndex;

    if (context.usesNavRail) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: <Widget>[
              AppNavRail(items: items, selectedIndex: index, onTap: _onTap),
              // 内容区自带 `Expanded` 之外的安全区：右侧状态栏 / 刘海由这层吃。
              Expanded(child: navigationShell),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: AppBottomNav(
        items: items,
        selectedIndex: index,
        onTap: _onTap,
      ),
    );
  }

  /// 切 Tab。**关键**：`initialLocation: index == currentIndex` ——
  /// 点已选中的 Tab 时回到该分支的根路由，而不是把栈清空；
  /// 切到别的 Tab 时保留该分支原有栈（滚动位置 / 编辑中的内容）。
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
