import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_elevation.dart';
import 'package:init/core/theme/tokens/app_radius.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final light = AppColors.light();
  final dark = AppColors.dark();

  group('AppTheme 接线', () {
    test('light / dark 都挂了 AppColors 与 AppTextStyles extension', () {
      expect(AppTheme.lightTheme.extension<AppColors>(), isNotNull);
      expect(AppTheme.lightTheme.extension<AppTextStyles>(), isNotNull);
      expect(AppTheme.darkTheme.extension<AppColors>(), isNotNull);
      expect(AppTheme.darkTheme.extension<AppTextStyles>(), isNotNull);
    });

    test('colorScheme 覆盖值等于 token', () {
      final s = AppTheme.lightTheme.colorScheme;
      expect(s.primary, light.accent);
      expect(s.onPrimary, light.surface);
      expect(s.surface, light.surface);
      expect(s.onSurface, light.textPrimary);
      expect(s.outline, light.outlineControl);
      expect(s.surfaceContainer, light.bg);
      expect(s.surfaceContainerLowest, light.bg);
    });

    test('scaffoldBackgroundColor 是页面底色而非卡片色', () {
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, light.bg);
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, isNot(light.surface));
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, dark.bg);
    });

    test('卡片无阴影、圆角 12dp', () {
      final card = AppTheme.lightTheme.cardTheme;
      expect(card.elevation, AppElevation.card);
      expect(card.elevation, 0);
      expect(card.color, light.surface);
      final shape = card.shape! as RoundedRectangleBorder;
      expect((shape.borderRadius as BorderRadius).topLeft.x, AppRadius.card);
    });

    test('顶栏无阴影、无 centerTitle', () {
      expect(AppTheme.lightTheme.appBarTheme.elevation, 0);
      expect(AppTheme.lightTheme.appBarTheme.centerTitle, isNull);
      expect(AppTheme.lightTheme.appBarTheme.backgroundColor, light.bg);
    });

    test('分割线 1dp + 设计稿 divider 色', () {
      expect(AppTheme.lightTheme.dividerTheme.thickness, AppStroke.divider);
      expect(AppTheme.lightTheme.dividerTheme.color, light.divider);
    });

    test('light / dark 的 brightness 相反且不是同一实例', () {
      expect(AppTheme.lightTheme.brightness, Brightness.light);
      expect(AppTheme.darkTheme.brightness, Brightness.dark);
      expect(AppTheme.lightTheme, isNot(same(AppTheme.darkTheme)));
    });

    test('重复访问返回同一实例（static final 而非 static 可变字段）', () {
      expect(AppTheme.lightTheme, same(AppTheme.lightTheme));
    });

    testWidgets('挂载后 context.colors / context.textStyles 可读', (tester) async {
      late AppColors readColors;
      late AppTextStyles readTextStyles;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
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
      expect(readTextStyles.displayTitle.fontSize, 24);
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
      expect(readTextStyles.body.fontSize, 17);
    });
  });
}
