import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:init/core/ui/app_large_title.dart';
import 'package:material_ui/material_ui.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      AppColors.light(),
      AppTextStyles.light(),
    ],
  ),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('padding 为 left 12 / top 16 / bottom 12', (tester) async {
    await tester.pumpWidget(
      wrap(const AppLargeTitle(text: '笔记', textScale: 1)),
    );

    final padding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(AppLargeTitle),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(
      padding.padding,
      const EdgeInsets.only(
        left: AppSpacing.pageH,
        top: 16,
        bottom: AppSpacing.pageH,
      ),
    );
  });

  testWidgets('文字样式取自 displayTitle 并显式带上 textPrimary', (tester) async {
    await tester.pumpWidget(
      wrap(const AppLargeTitle(text: '笔记', textScale: 1)),
    );

    final text = tester.widget<Text>(find.text('笔记'));
    expect(text.style?.fontSize, 24);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.height, 1.2);
    expect(text.style?.color, const AppColors.light().textPrimary);
  });

  testWidgets('左对齐且不设死高度', (tester) async {
    await tester.pumpWidget(
      wrap(const AppLargeTitle(text: '待办', textScale: 1)),
    );

    final align = tester.widget<Align>(
      find.descendant(
        of: find.byType(AppLargeTitle),
        matching: find.byType(Align),
      ),
    );
    expect(align.alignment, Alignment.centerLeft);
    // 高度由内容决定（16 + 24*1.2 + 12 ≈ 56.8），不是 48
    expect(tester.getSize(find.byType(AppLargeTitle)).height, greaterThan(48));
  });
}
