import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/app_filter_chip.dart';
import 'package:init/core/ui/app_section_header.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppFilterChip', () {
    testWidgets('高 28dp、pill 全圆角', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: AppFilterChip(label: '全部', selected: true, textScale: 1),
            ),
          ),
        ),
      );

      expect(AppFilterChip.height, 28);
      expect(
        AppFilterChip.height,
        tester.getSize(find.byType(AppFilterChip)).height,
      );
      expect(AppFilterChip.horizontalPadding, AppSpacing.pageH);
      expect(AppFilterChip.horizontalPadding, 12);

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AppFilterChip),
          matching: find.byType(Material),
        ),
      );
      expect(AppFilterChip.shape, isA<BorderRadius>());
      expect(AppFilterChip.shape.topLeft.x, AppFilterChip.height / 2);
      expect((material.borderRadius! as BorderRadius).topLeft.x, 14);
    });

    testWidgets('选中态：#EFEFEF 底 + textPrimary 字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: AppFilterChip(label: '全部', selected: true, textScale: 1),
            ),
          ),
        ),
      );

      const colors = AppColors.light();
      expect(
        tester
            .widget<Material>(
              find.descendant(
                of: find.byType(AppFilterChip),
                matching: find.byType(Material),
              ),
            )
            .color,
        colors.chipSelectedBg,
      );
      expect(
        tester.widget<Text>(find.text('全部')).style?.color,
        colors.textPrimary,
      );
    });

    testWidgets('未选中态：surface 底 + textSecondary 字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: AppFilterChip(label: '未分类', selected: false, textScale: 1),
            ),
          ),
        ),
      );

      const colors = AppColors.light();
      expect(
        tester
            .widget<Material>(
              find.descendant(
                of: find.byType(AppFilterChip),
                matching: find.byType(Material),
              ),
            )
            .color,
        colors.surface,
      );
      expect(
        tester.widget<Text>(find.text('未分类')).style?.color,
        colors.textSecondary,
      );
    });

    testWidgets('文字样式取 text.chip（13sp / w500）且单行省略', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: AppFilterChip(label: '词声笔记', selected: true, textScale: 1),
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('词声笔记'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.style?.fontSize, 13);
      expect(text.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('无勾选标记（D1 未提勾）', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: AppFilterChip(label: '全部', selected: true, textScale: 1),
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('onTap 回调触发', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: AppFilterChip(
                label: '词声笔记',
                selected: false,
                textScale: 1,
                onTap: () => tapped++,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppFilterChip));
      expect(tapped, 1);
    });
  });

  group('AppSectionHeader', () {
    testWidgets('缩进 28 / 上 16 / 下 8，字色 #A0A0A0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AppSectionHeader(text: '云服务')),
        ),
      );

      expect(AppSectionHeader.indent, AppSpacing.sectionHeaderIndent);
      expect(AppSectionHeader.indent, 28);
      expect(AppSectionHeader.topPadding, 16);
      expect(AppSectionHeader.bottomPadding, 8);

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(AppSectionHeader),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        const EdgeInsets.only(left: 28, top: 16, bottom: 8),
      );

      const colors = AppColors.light();
      expect(colors.textSectionHeader, const Color(0xFFA0A0A0));
      expect(
        tester.widget<Text>(find.text('云服务')).style?.color,
        colors.textSectionHeader,
      );
    });
  });
}
