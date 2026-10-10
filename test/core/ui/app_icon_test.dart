import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/ui/app_icon.dart';
import 'package:mynote/core/ui/app_icon_button.dart';
import 'package:material_ui/material_ui.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppIcon', () {
    testWidgets('默认视觉尺寸 24dp', (tester) async {
      await tester.pumpWidget(wrap(AppIcon(icon: AppIcons.folder)));

      expect(tester.getSize(find.byIcon(AppIcons.folder)).width, 24);
    });

    testWidgets('size 参数可覆盖', (tester) async {
      await tester.pumpWidget(wrap(AppIcon(icon: AppIcons.check, size: 20)));

      expect(tester.getSize(find.byIcon(AppIcons.check)).width, 20);
    });

    testWidgets('默认色为 outlineControl，显式 color 可覆盖', (tester) async {
      await tester.pumpWidget(wrap(AppIcon(icon: AppIcons.trash)));
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.trash)).color,
        const AppColors.light().outlineControl,
      );

      await tester.pumpWidget(
        wrap(
          AppIcon(icon: AppIcons.check, color: const AppColors.light().accent),
        ),
      );
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.check)).color,
        const AppColors.light().accent,
      );
    });

    test('AppIcons 15 个语义互不重复', () {
      // 数值本身由设计稿锁，这里只守「没有两个名字指向同一个图标」——
      // 复制粘贴错行时这条会红，转抄 15 个字面量则永远跟着源码一起绿。
      const icons = <IconData>[
        AppIcons.folder,
        AppIcons.settings,
        AppIcons.back,
        AppIcons.share,
        AppIcons.palette,
        AppIcons.overflow,
        AppIcons.plus,
        AppIcons.chevronRight,
        AppIcons.stepper,
        AppIcons.trash,
        AppIcons.check,
        AppIcons.circlePlusOutline,
        AppIcons.checkboxOutline,
        AppIcons.navNotes,
        AppIcons.navTodo,
      ];
      expect(icons.toSet(), hasLength(icons.length), reason: '存在重复映射');
    });
  });

  group('AppIconButton', () {
    testWidgets('触控区至少 48dp', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppIconButton(
            icon: AppIcons.settings,
            onPressed: () {},
            tooltip: '设置',
          ),
        ),
      );

      expect(AppIconButton.minTapSize, 48);
      final size = tester.getSize(find.byType(AppIconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('图形仍是 24dp（触控区不撑大视觉）', (tester) async {
      await tester.pumpWidget(
        wrap(
          AppIconButton(
            icon: AppIcons.settings,
            onPressed: () {},
            tooltip: '设置',
          ),
        ),
      );

      expect(
        tester.getSize(find.byIcon(AppIcons.settings)).width,
        AppIcon.defaultSize,
      );
    });

    testWidgets('onPressed 回调被触发', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(AppIconButton(icon: AppIcons.back, onPressed: () => tapped++)),
      );

      await tester.tap(find.byType(AppIconButton));
      expect(tapped, 1);
    });

    testWidgets('onPressed 为 null 时禁用且不崩溃', (tester) async {
      await tester.pumpWidget(
        wrap(AppIconButton(icon: AppIcons.palette, onPressed: null)),
      );

      expect(
        tester.getSize(find.byType(AppIconButton)).width,
        greaterThanOrEqualTo(48),
      );
    });
  });
}
