import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/app_top_bar.dart';
import 'package:material_ui/material_ui.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Column(
      children: <Widget>[
        child,
        const Expanded(child: SizedBox.shrink()),
      ],
    ),
  ),
);

BoxDecoration barDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
        as BoxDecoration;

void main() {
  testWidgets('顶栏内容区高 56dp（不含状态栏）', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTopBar(
          actions: <Widget>[Icon(Icons.list), Icon(Icons.settings)],
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppTopBar)).height, 56);
  });

  testWidgets('底色为 colors.bg；showDivider 控制 1dp 底边', (tester) async {
    await tester.pumpWidget(wrap(const AppTopBar()));
    expect(barDecoration(tester).color, const AppColors.light().bg);
    expect(
      barDecoration(tester).border,
      isNotNull,
      reason: '默认 showDivider = true 应有底边',
    );

    await tester.pumpWidget(wrap(const AppTopBar(showDivider: false)));
    expect(
      barDecoration(tester).border,
      isNull,
      reason: 'showDivider = false 不应有底边',
    );
  });

  testWidgets('2 个 action 之间间距 8dp，且靠右', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTopBar(
          actions: <Widget>[Icon(Icons.folder), Icon(Icons.settings)],
        ),
      ),
    );

    final r0 = tester.getRect(find.byIcon(Icons.folder));
    final r1 = tester.getRect(find.byIcon(Icons.settings));
    expect(r1.left - r0.right, closeTo(AppSpacing.chipGap, 0.5));

    // 靠右：最后一个 action 与顶栏右边缘之间只剩 12dp 页面内边距
    final bar = tester.getRect(find.byType(AppTopBar));
    expect(bar.right - r1.right, closeTo(AppSpacing.pageH, 0.5));
  });

  testWidgets('形态 B：centerTitle 存在时居中，leading 在左', (tester) async {
    // leading / action 同为 48dp 触控区（TASK-010 的 AppIconButton）时，
    // Expanded 的中线与顶栏中线重合 —— 这就是设计稿文件夹管理稿的居中标题。
    await tester.pumpWidget(
      wrap(
        const AppTopBar(
          leading: SizedBox(width: 48, height: 48),
          centerTitle: Text('文件夹'),
          actions: <Widget>[SizedBox(width: 48, height: 48)],
        ),
      ),
    );

    final bar = tester.getRect(find.byType(AppTopBar));
    final title = tester.getRect(find.text('文件夹'));
    expect(title.center.dx, closeTo(bar.center.dx, 1.0));
  });

  testWidgets('形态 A\'：title 左对齐，与右侧 actions 同行', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTopBar(
          title: Text('笔记'),
          actions: <Widget>[Icon(Icons.settings)],
        ),
      ),
    );

    final bar = tester.getRect(find.byType(AppTopBar));
    final title = tester.getRect(find.text('笔记'));
    final action = tester.getRect(find.byIcon(Icons.settings));
    // 左对齐：与顶栏内容区左边缘之间只剩 12dp 页面内边距（无 leading）
    expect(title.left - bar.left, closeTo(AppSpacing.pageH, 0.5));
    expect(title.right, lessThan(action.left), reason: '标题与图标不重叠');
    expect(title.center.dy, closeTo(action.center.dy, 1.0), reason: '同一行');
  });

  testWidgets('形态 A：无 centerTitle 时 actions 仍靠右', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppTopBar(
          actions: <Widget>[Icon(Icons.folder), Icon(Icons.settings)],
        ),
      ),
    );

    expect(find.text('文件夹'), findsNothing);
    final bar = tester.getRect(find.byType(AppTopBar));
    final last = tester.getRect(find.byIcon(Icons.settings));
    expect(bar.right - last.right, greaterThan(0));
  });
}
