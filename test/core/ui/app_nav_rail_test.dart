import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:mynote/core/ui/app_nav_rail.dart';
import 'package:material_ui/material_ui.dart';

/// 侧栏与底栏**共用**同一份 `AppBottomNavItem` 数据与同一个回调签名
/// （见 `NotesShell`）。这里钉死「纯视觉组件、只上报不导航」这条契约，
/// 以及选中态的语义标注 —— 侧栏是宽屏唯一的导航，无障碍标注错了就没有替代入口。
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: Row(children: <Widget>[child])),
  );

  final items = <AppBottomNavItem>[
    const AppBottomNavItem(icon: Icons.description_outlined, label: '笔记'),
    const AppBottomNavItem(icon: Icons.check_circle_outline, label: '待办'),
  ];

  testWidgets('渲染两个导航项（图标 + 文字）', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppNavRail(items: items, selectedIndex: 0, onTap: (_) {}),
      ),
    );

    expect(find.text('笔记'), findsOneWidget);
    expect(find.text('待办'), findsOneWidget);
    expect(
      tester.getRect(find.byType(AppNavRail)).width,
      88,
      reason: '侧栏宽度是断点表里的单点值',
    );
  });

  testWidgets('点击上报下标，自己不导航', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      wrap(
        AppNavRail(items: items, selectedIndex: 0, onTap: tapped.add),
      ),
    );

    await tester.tap(find.text('待办'));
    expect(tapped, <int>[1]);
  });

  testWidgets('选中项带 selected 语义，未选中项不带', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppNavRail(items: items, selectedIndex: 1, onTap: (_) {}),
      ),
    );

    // 直接读本组件声明的 `Semantics`（按 label 精确定位）：`InkWell` / `Text`
    // 自己也会插入 `Semantics`，用「最近的祖先」会拿到别人的那一层。
    Semantics semanticsOf(String label) => tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == label,
      ),
    );

    expect(semanticsOf('待办').properties.selected, isTrue);
    expect(semanticsOf('待办').properties.button, isTrue);
    expect(semanticsOf('笔记').properties.selected, isFalse);
  });
}
