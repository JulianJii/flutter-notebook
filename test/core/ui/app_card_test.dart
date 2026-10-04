import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_radius.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/app_card.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: Center(child: SizedBox(width: 200, child: child)),
    ),
  );

  testWidgets('默认内边距 12dp 且可被覆盖', (tester) async {
    expect(AppCard.defaultPadding, const EdgeInsets.all(AppSpacing.cardPad));
    expect(AppCard.defaultPadding, const EdgeInsets.all(12));

    await tester.pumpWidget(wrap(const AppCard(child: Text('笔记'))));
    expect(
      tester.getTopLeft(find.text('笔记')).dx -
          tester.getTopLeft(find.byType(Card)).dx,
      12,
      reason: '默认内边距应渲染为 12dp',
    );

    await tester.pumpWidget(
      wrap(
        const AppCard(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.rowPadH),
          child: Text('待办'),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('待办')).dx -
          tester.getTopLeft(find.byType(Card)).dx,
      16,
      reason: '调用方可覆盖为左右 16dp',
    );
  });

  testWidgets('margin 为零（否则白卡不会贴齐 12dp 页面边距）', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('笔记'))));

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.margin, EdgeInsets.zero);
  });

  testWidgets('外观来自 cardTheme：白底 / 12dp 圆角 / 无阴影', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('笔记'))));

    final card = tester.widget<Card>(find.byType(Card));
    final theme = AppTheme.lightTheme.cardTheme;
    expect(card.color ?? theme.color, const AppColors.light().surface);
    expect(theme.elevation, 0, reason: '§2.4 elevation.card = 0');
    expect(theme.shape, isA<RoundedRectangleBorder>());
    final radius =
        (theme.shape! as RoundedRectangleBorder).borderRadius as BorderRadius;
    expect(radius.topLeft.x, AppRadius.card);
  });

  testWidgets('onTap 为 null 时不可点；非 null 时回调触发', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      wrap(AppCard(onTap: () => tapped++, child: const Text('笔记'))),
    );

    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.byType(AppCard));
    expect(tapped, 1);

    await tester.pumpWidget(wrap(const AppCard(child: Text('笔记'))));
    expect(find.byType(InkWell), findsNothing, reason: '静态卡片不应有 InkWell');
  });

  testWidgets('surfaceTintColor 清零且裁剪按圆角', (tester) async {
    await tester.pumpWidget(wrap(const AppCard(child: Text('笔记'))));

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.surfaceTintColor, Colors.transparent);
    expect(card.clipBehavior, Clip.antiAlias);
  });
}
