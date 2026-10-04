import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_elevation.dart';
import 'package:init/core/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('AppFab 渲染 64dp 圆形', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          floatingActionButton: AppFab(onPressed: () {}),
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.byType(AppFab), findsOneWidget);
    expect(tester.getSize(find.byType(AppFab)), const Size(64, 64));

    final decoration =
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(AppFab),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as ShapeDecoration;
    expect(decoration.color, const AppColors.light().accent);
    expect(decoration.shape, isA<CircleBorder>());
    expect(decoration.shadows, AppElevation.fab);
  });

  testWidgets('AppFab onPressed == null 时不渲染', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          floatingActionButton: AppFab(onPressed: null),
          body: const SizedBox(),
        ),
      ),
    );

    expect(find.byType(AppFab), findsOneWidget, reason: '组件在树里但塌缩为空');
    expect(tester.getSize(find.byType(AppFab)), Size.zero);
  });

  testWidgets('AppFab 点击触发 onPressed', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          floatingActionButton: AppFab(onPressed: () => pressed++),
          body: const SizedBox(),
        ),
      ),
    );

    await tester.tap(find.byType(AppFab));
    expect(pressed, 1);
  });

  testWidgets('AppCheckbox value=true 不崩（D2 checked 无稿）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: AppCheckbox(value: true, onChanged: (_) {})),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(AppCheckbox.size, 20);
    expect(AppCheckbox.radius, 6);
    expect(AppCheckbox.strokeWidth, 2);
  });

  testWidgets('AppCheckbox 点击回调收到 true', (tester) async {
    bool? received;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppCheckbox(value: false, onChanged: (v) => received = v),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    expect(received, isTrue);
  });

  testWidgets('AppSwitchRow 显示标题与副标题', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppSwitchRow(
            title: '强提醒',
            subtitle: '持续响铃且静音和勿扰状态下仍有效',
            value: false,
            onChanged: null,
          ),
        ),
      ),
    );

    expect(find.text('强提醒'), findsOneWidget);
    expect(find.text('持续响铃且静音和勿扰状态下仍有效'), findsOneWidget);
    expect(find.byType(AppListTile), findsOneWidget, reason: '复用 TASK-012 的行');
    expect(
      tester.widget<Text>(find.text('强提醒')).style?.fontWeight,
      FontWeight.w600,
    );
  });

  testWidgets('AppSwitchRow 点击开关回调收到 true', (tester) async {
    bool? received;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppSwitchRow(
            title: '强提醒',
            value: false,
            onChanged: (v) => received = v,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    expect(received, isTrue);
  });

  testWidgets('ui.dart 桶文件导出全部 T1 组件', (tester) async {
    // 引用即验证：任何一个 export 缺失或文件为 0 字节，本文件都编译不过。
    expect(AppFab, isNotNull);
    expect(AppCheckbox, isNotNull);
    expect(AppSwitchRow, isNotNull);
    expect(AppListTile, isNotNull);
    expect(AppTopBar, isNotNull);
    expect(AppLargeTitle, isNotNull);
    expect(AppSectionHeader, isNotNull);
    expect(AppCard, isNotNull);
    expect(AppFilterChip, isNotNull);
    expect(AppIcon, isNotNull);
    expect(AppIconButton, isNotNull);
    expect(AppDivider, isNotNull);
    expect(AppBottomNav, isNotNull);
  });
}
