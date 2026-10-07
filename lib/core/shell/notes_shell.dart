import 'package:go_router/go_router.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:mynote/core/ui/app_icon.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 笔记 App 的 Shell 容器。笔记列表/待办两个 Tab 由它承载，切换时各自保状态。
///
/// 非 edge-to-edge：安全区由本组件自己包。
class NotesShell extends StatelessWidget {
  const NotesShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// 底部 2 项。标签由调用方（Shell）从 l10n 取 —— Shell 在 `core/` 内，
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
    return Scaffold(
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: AppBottomNav(
        items: _items(context),
        selectedIndex: navigationShell.currentIndex,
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
