import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:material_ui/material_ui.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const items = <AppBottomNavItem>[
  AppBottomNavItem(icon: Icons.list_rounded, label: '笔记'),
  AppBottomNavItem(icon: Icons.check_rounded, label: '待办'),
];

void main() {
  testWidgets('2 项等宽平分', (tester) async {
    await tester.pumpWidget(
      wrap(AppBottomNav(items: items, selectedIndex: 0, onTap: (_) {})),
    );

    expect(find.byType(Expanded), findsNWidgets(2));
    final w0 = tester.getSize(find.byType(InkWell).at(0)).width;
    final w1 = tester.getSize(find.byType(InkWell).at(1)).width;
    expect(w0, closeTo(w1, 0.5), reason: '两项宽度必须相等（等宽平分）');
  });

  testWidgets('仅 selectedIndex 指向的那一项有深色方块底', (tester) async {
    await tester.pumpWidget(
      wrap(AppBottomNav(items: items, selectedIndex: 1, onTap: (_) {})),
    );

    final decorated = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.color == const Color(0xFF1A1A1A))
        .length;
    expect(decorated, 1, reason: '有且只有一个深色圆角方块底');
    expect(
      tester
          .widget<Container>(
            find.ancestor(
              of: find.byIcon(Icons.check_rounded),
              matching: find.byType(Container),
            ),
          )
          .decoration,
      isA<BoxDecoration>().having(
        (d) => d.borderRadius,
        'borderRadius',
        BorderRadius.circular(AppRadius.navIcon),
      ),
    );
  });

  testWidgets('点击第 2 项回调 index 1（只上报，不自己导航）', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      wrap(AppBottomNav(items: items, selectedIndex: 0, onTap: tapped.add)),
    );

    await tester.tap(find.byType(InkWell).at(1));
    expect(tapped, <int>[1]);
  });

  testWidgets('Semantics 正确标记选中态', (tester) async {
    await tester.pumpWidget(
      wrap(AppBottomNav(items: items, selectedIndex: 0, onTap: (_) {})),
    );

    Semantics node(bool selected) => tester.widget<Semantics>(
      find
          .byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == true &&
                w.properties.label != null,
          )
          .at(selected ? 0 : 1),
    );

    final selectedItem = node(true);
    expect(selectedItem.properties.label, '笔记');
    expect(selectedItem.properties.selected, isTrue);

    final unselectedItem = node(false);
    expect(unselectedItem.properties.label, '待办');
    expect(unselectedItem.properties.selected, isFalse);
  });

  testWidgets('底色 surface / 顶边 1dp divider / 内容区高 64dp', (tester) async {
    await tester.pumpWidget(
      wrap(AppBottomNav(items: items, selectedIndex: 0, onTap: (_) {})),
    );

    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(AppBottomNav),
                  matching: find.byType(SizedBox),
                )
                .first,
          )
          .height,
      64,
    );

    final decoration =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
            as BoxDecoration;
    expect(decoration.color, const AppColors.light().surface);
    expect(
      decoration.border,
      const Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
    );
  });

  testWidgets('触控区 ≥48dp', (tester) async {
    await tester.pumpWidget(
      wrap(AppBottomNav(items: items, selectedIndex: 0, onTap: (_) {})),
    );

    for (var i = 0; i < 2; i++) {
      final size = tester.getSize(find.byType(InkWell).at(i));
      expect(size.height, greaterThanOrEqualTo(48), reason: '第 $i 项触控区不足 48dp');
    }
  });
}
