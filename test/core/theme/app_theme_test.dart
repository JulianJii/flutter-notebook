import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/app_color_scheme.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final light = AppColors.light();
  final dark = AppColors.dark();

  group('AppTheme 接线', () {
    test('light / dark 都挂了 AppColors 与 AppTextStyles extension', () {
      expect(AppTheme.light().extension<AppColors>(), isNotNull);
      expect(AppTheme.light().extension<AppTextStyles>(), isNotNull);
      expect(AppTheme.dark().extension<AppColors>(), isNotNull);
      expect(AppTheme.dark().extension<AppTextStyles>(), isNotNull);
    });

    test('colorScheme 覆盖值等于 token', () {
      final s = AppTheme.light().colorScheme;
      expect(s.primary, light.accent);
      expect(s.onPrimary, light.surface);
      expect(s.surface, light.surface);
      expect(s.onSurface, light.textPrimary);
      expect(s.outline, light.outlineControl);
      expect(s.surfaceContainer, light.bg);
      expect(s.surfaceContainerLowest, light.bg);
    });

    test('scaffoldBackgroundColor 是页面底色而非卡片色', () {
      expect(AppTheme.light().scaffoldBackgroundColor, light.bg);
      expect(AppTheme.light().scaffoldBackgroundColor, isNot(light.surface));
      expect(AppTheme.dark().scaffoldBackgroundColor, dark.bg);
    });

    test('卡片无阴影、圆角 12dp', () {
      final card = AppTheme.light().cardTheme;
      expect(card.elevation, AppElevation.card);
      expect(card.elevation, 0);
      expect(card.color, light.surface);
      final shape = card.shape! as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, AppRadius.card);
    });

    test('顶栏无阴影、无 centerTitle', () {
      expect(AppTheme.light().appBarTheme.elevation, 0);
      expect(AppTheme.light().appBarTheme.centerTitle, isNull);
      expect(AppTheme.light().appBarTheme.backgroundColor, light.bg);
    });

    test('分割线 1dp + 设计稿 divider 色', () {
      expect(AppTheme.light().dividerTheme.thickness, AppStroke.divider);
      expect(AppTheme.light().dividerTheme.color, light.divider);
    });

    test('light / dark 的 brightness 相反且不是同一实例', () {
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
      expect(AppTheme.light(), isNot(same(AppTheme.dark())));
    });

    test('重复访问返回同一实例（按明暗 × 方案缓存）', () {
      expect(AppTheme.light(), same(AppTheme.light()));
      expect(AppTheme.dark(), same(AppTheme.dark()));
      expect(
        AppTheme.light(AppColorScheme.blue),
        same(AppTheme.light(AppColorScheme.blue)),
      );
      expect(AppTheme.light(), isNot(same(AppTheme.light(AppColorScheme.blue))));
    });
  });

  group('配色方案', () {
    test('方案主色同时进 colorScheme.primary 与 AppColors.accent', () {
      for (final scheme in AppColorScheme.values) {
        final theme = AppTheme.light(scheme);
        expect(theme.colorScheme.primary, Color(scheme.seed));
        expect(theme.extension<AppColors>()!.accent, Color(scheme.seed));
      }
    });

    test('默认方案是设计稿强调色 #F0A020', () {
      expect(Color(AppColorScheme.amber.seed), const Color(0xFFF0A020));
      expect(AppTheme.light().colorScheme.primary, const Color(0xFFF0A020));
    });

    test('换方案只动强调色，中性色不动', () {
      final amber = AppTheme.light().extension<AppColors>()!;
      final blue = AppTheme.light(AppColorScheme.blue).extension<AppColors>()!;

      expect(blue.accent, isNot(amber.accent));
      expect(blue.bg, amber.bg);
      expect(blue.surface, amber.surface);
      expect(blue.textPrimary, amber.textPrimary);
    });
  });

  group('深色', () {
    // Q36 → docs/OPEN-DESIGN-QUESTIONS.md（深色彩无稿，按 M3 深色规范反推）
    test('深色不是浅色的复制：底色与文字色都换了', () {
      expect(dark.bg, isNot(light.bg));
      expect(dark.surface, isNot(light.surface));
      expect(dark.textPrimary, isNot(light.textPrimary));
    });

    test('深色主题用深色语义色', () {
      final s = AppTheme.dark().colorScheme;
      expect(s.brightness, Brightness.dark);
      expect(s.surface, dark.surface);
      expect(s.onSurface, dark.textPrimary);
      expect(AppTheme.dark().scaffoldBackgroundColor, dark.bg);
    });
  });

  group('extension 读取', () {
    testWidgets('挂载后 context.colors / context.textStyles 可读', (tester) async {
      late AppColors readColors;
      late AppTextStyles readTextStyles;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              readColors = context.colors;
              readTextStyles = context.textStyles;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(readColors.accent, light.accent);
      expect(readTextStyles.displayTitle.fontSize, 20);
    });

    testWidgets('未挂载 extension 时降级为 light 值而不抛异常', (tester) async {
      late AppColors readColors;
      late AppTextStyles readTextStyles;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              readColors = context.colors;
              readTextStyles = context.textStyles;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(readColors.accent, light.accent);
      expect(readTextStyles.body.fontSize, 15);
    });
  });
}
