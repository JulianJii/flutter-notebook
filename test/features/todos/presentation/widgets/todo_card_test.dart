import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/todos/presentation/widgets/todo_card.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zoloto/zoloto.dart';

/// 与 P1 / P3 三份基线同视口（1080px = 360dp），便于横向比对（TASK-035 §2）。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

void _noop(bool value) {}

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    // `Align` 传松约束 → 卡片按内容自高（Scaffold 的紧约束会把它撑满整屏）。
    home: Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 360, child: child),
      ),
    ),
  );

  testWidgets('渲染标题 + 复选框，容器是 AppCard', (tester) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );

    expect(find.text('测试'), findsOneWidget);
    expect(find.byType(AppCheckbox), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byType(InkWell), findsNothing, reason: 'onTap 为 null → 静态卡片');
  });

  testWidgets('D2 实测：卡高 ≈60dp；行内复选框与标题垂直居中', (tester) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );

    expect(
      tester.getSize(find.byType(AppCard)).height,
      closeTo(60, 3),
      reason:
          'D2 实测 ≈60dp。残差来自 16sp × 1.4 的 22.4dp 行高（排版由内容决定，'
          '不写死高度）；上下内边距按稿 = (60 − 20) / 2 = 20dp',
    );

    final box = tester.getRect(find.byType(AppCheckbox));
    final text = tester.getRect(find.text('测试'));
    expect(box.center.dy, closeTo(text.center.dy, 0.5), reason: '复选框与标题垂直居中对齐');
  });

  testWidgets('内边距：左右 rowPadH(16) / 上下 20；框↔文字 AppSpacing.sm(8)', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );

    final card = tester.getRect(find.byType(AppCard));
    final box = tester.getRect(find.byType(AppCheckbox));
    final text = tester.getRect(find.text('测试'));
    // 卡片唯一那层 Row（深度优先第一个）；从它量上下内边距，量复选框会带进
    // 「20dp 盒在 22.4dp 行高中居中」的 1.2dp 余量。
    final row = tester.getRect(
      find
          .descendant(of: find.byType(AppCard), matching: find.byType(Row))
          .first,
    );

    expect(box.left - card.left, closeTo(AppSpacing.rowPadH, 0.5));
    expect(row.top - card.top, closeTo(20, 0.5));
    expect(card.bottom - row.bottom, closeTo(20, 0.5));
    expect(text.left - box.right, closeTo(AppSpacing.sm, 0.5));
  });

  testWidgets('卡片不自带外边距（外边距归列表容器）', (tester) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );

    // 组件通栏铺满给定的 360dp 宽 → 若自带 margin，卡片宽会 < 360。
    expect(tester.getRect(find.byType(AppCard)).width, 360);
  });

  testWidgets('Q21 完成态：勾选透传 + 标题删除线且变灰', (tester) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: true, onChanged: _noop)),
    );

    expect(tester.widget<AppCheckbox>(find.byType(AppCheckbox)).value, isTrue);
    final done = tester.widget<Text>(find.text('测试'));
    expect(done.style?.decoration, TextDecoration.lineThrough);
    expect(done.style?.color, isNot(const Color(0xFF1F1F1F)));

    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );
    final active = tester.widget<Text>(find.text('测试'));
    expect(active.style?.decoration, isNull);
  });

  testWidgets('点复选框：回调携带目标值（true / false）', (tester) async {
    final seen = <bool>[];
    await tester.pumpWidget(
      wrap(TodoCard(title: '测试', checked: false, onChanged: seen.add)),
    );

    await tester.tap(find.byType(AppCheckbox));
    await tester.pumpAndSettle();
    expect(seen, <bool>[true]);

    await tester.pumpWidget(
      wrap(TodoCard(title: '测试', checked: true, onChanged: seen.add)),
    );
    await tester.tap(find.byType(AppCheckbox));
    expect(seen, <bool>[true, false]);
  });

  testWidgets('onChanged 为 null：复选框禁用，点击不崩', (tester) async {
    await tester.pumpWidget(wrap(const TodoCard(title: '测试', checked: false)));

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    await tester.tap(find.byType(AppCheckbox));
    expect(tester.takeException(), isNull);
  });

  testWidgets('onTap 传 null：点卡片无涟漪、无异常（Q35 / Q21 无稿）', (tester) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );
    await tester.tap(find.byType(AppCard));

    expect(tester.takeException(), isNull);
  });

  testWidgets('onTap 传值时被调用一次', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(
        TodoCard(
          title: '测试',
          checked: false,
          onChanged: _noop,
          onTap: () => tapped++,
        ),
      ),
    );
    await tester.tap(find.byType(AppCard));

    expect(tapped, 1);
  });

  testWidgets('超长标题单行省略，卡片不撑高（不写死 height）', (tester) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );
    final short = tester.getSize(find.byType(AppCard)).height;

    await tester.pumpWidget(
      wrap(
        TodoCard(
          title: List<String>.filled(40, '字').join(),
          checked: false,
          onChanged: _noop,
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(AppCard)).height, short);
    expect(tester.takeException(), isNull);
  });

  testWidgets('标题样式为 rowTitle(15sp w400) + textPrimary', (tester) async {
    await tester.pumpWidget(
      wrap(const TodoCard(title: '测试', checked: false, onChanged: _noop)),
    );

    final style = tester.widget<Text>(find.text('测试')).style!;
    expect(style.fontSize, 15);
    expect(style.fontWeight, FontWeight.w400);
    expect(style.height, 1.4);
    expect(style.color, const Color(0xFF1A1A1A));
  });

  testGoldenWidgets('未勾选态结构基线', (tester) async {
    await expectMatchTestEnvironments(
      'todo_card',
      tester: tester,
      widget: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        body: const TodoCard(title: '测试', checked: false, onChanged: _noop),
      ),
      testEnvironments: <TestEnvironment>[goldenEnv],
    );
  });
}
