import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/features/settings/presentation/providers/settings_provider.dart';
import 'package:init/features/settings/presentation/screens/settings_screen.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// D5 的 4 个分组标题（「云服务」已按产品要求移除，「最近删除」并入「其他」）。
const List<String> _groupTitles = <String>['笔记样式', '快捷功能', '提醒', '其他'];

const List<String> _groupKeys = <String>[
  'section_note_style',
  'section_quick',
  'section_reminder',
  'section_other',
];

void main() {
  setUpAll(() => registerFallbackValue(const AppSettings.defaults()));

  late _MockSettingsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockSettingsRepository();
    when(() => repo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => repo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    // override 打在 **Repository** 层：既不接 SharedPreferences（测试环境无插件实现），
    // 也守住「Screen 只经 provider 取偏好」这条分层约束。
    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpP5(WidgetTester tester) async {
    // 默认测试视口是 800×600，而 P5 的 5 个分组实测 ≈794dp 高 —— 最后一个分组会
    // 落在 ListView 的 cacheExtent 之外**根本不被构建**，几何与计数断言会误报。
    // 这里给一个能容下整页的视口（比例 1.0，与 golden 基线同一约定）。
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 点开 [rowKey] 的选项单，选中 [option]（按 `BottomSheet` 限定，因为选项文案
  /// 与行尾当前值同名）。
  Future<void> pick(WidgetTester tester, String rowKey, String option) async {
    await tester.tap(find.byKey(Key(rowKey)));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text(option)),
    );
    await tester.pumpAndSettle();
  }

  group('D5 结构', () {
    testWidgets('渲染出 4 个分组，顺序为 笔记样式 → 快捷功能 → 提醒 → 其他', (tester) async {
      await pumpP5(tester);

      for (final title in _groupTitles) {
        expect(
          find.descendant(
            of: find.byType(AppSectionHeader),
            matching: find.text(title),
          ),
          findsOneWidget,
          reason: '缺少分组标题「$title」',
        );
      }

      var previousTop = -1.0;
      for (final key in _groupKeys) {
        final top = tester.getTopLeft(find.byKey(Key(key))).dy;
        expect(top, greaterThan(previousTop), reason: '$key 顺序不对');
        previousTop = top;
      }
    });

    testWidgets('顶栏：居中标题「设置」+ back 箭头，无右侧动作、无分隔线', (tester) async {
      await pumpP5(tester);

      final topBar = tester.widget<AppTopBar>(find.byType(AppTopBar));
      expect(topBar.actions, isEmpty, reason: '顶栏无右侧动作');
      expect(topBar.showDivider, isFalse, reason: '顶栏下无 1dp 分隔线');
      expect(find.byIcon(AppIcons.back), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppTopBar),
          matching: find.text('设置'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('标题在顶栏内、分组卡之上', (tester) async {
      await pumpP5(tester);

      expect(find.byType(AppLargeTitle), findsNothing);
      expect(
        tester.getBottomLeft(find.byType(AppTopBar)).dy,
        lessThan(tester.getTopLeft(find.byType(AppCard).first).dy),
      );
    });

    testWidgets('卡片左右各 12dp、分组标题左缩进 28dp（页面绝对）', (tester) async {
      await pumpP5(tester);

      final card = tester.getRect(find.byType(AppCard).first);
      expect(card.left, AppSpacing.pageH);
      expect(
        card.right,
        tester.view.physicalSize.width / tester.view.devicePixelRatio -
            AppSpacing.pageH,
      );

      final headerText = find.descendant(
        of: find.byType(AppSectionHeader),
        matching: find.text(_groupTitles.first),
      );
      expect(
        tester.getTopLeft(headerText).dx,
        AppSpacing.sectionHeaderIndent,
        reason: '分组标题缩进是页面绝对值，不能被卡片的 12dp 包裹',
      );
    });

    testWidgets('同卡片内第 2 行起各有一条 1dp 分割线（共 5 条）', (tester) async {
      await pumpP5(tester);

      // 笔记样式 4 行 → 3 条，其他 3 行 → 2 条。
      expect(find.byType(AppDivider), findsNWidgets(5));
    });

    testWidgets('4 张分组卡，9 行', (tester) async {
      await pumpP5(tester);

      expect(find.byType(AppCard), findsNWidgets(4));
      expect(find.byType(AppListTile), findsNWidgets(9));
      expect(find.byType(Switch), findsNothing, reason: '开关已改为选择器行');
      // 4 个 chevron 行 + 5 个选择器行（文字大小 / 排序 / 布局 / 深色模式 / 强提醒）。
      expect(find.byIcon(AppIcons.chevronRight), findsNWidgets(9));
    });
  });

  group('5 个可写行走 settingsProvider', () {
    testWidgets('3 个选择器行显示当前值文案，不是枚举英文名', (tester) async {
      await pumpP5(tester);

      expect(find.text('默认'), findsOneWidget);
      expect(find.text('按编辑日期'), findsOneWidget);
      expect(find.text('宫格模式'), findsOneWidget);

      for (final name in <String>[
        'small',
        'normal',
        'xLarge',
        'grid',
        'list',
      ]) {
        expect(find.text(name), findsNothing);
      }
    });

    testWidgets('点选择器行：弹层列出全部档位，选中即写回', (tester) async {
      await pumpP5(tester);

      await tester.tap(find.byKey(const Key('select_note_layout')));
      await tester.pumpAndSettle();

      // ⚠️ 选项文案与行尾当前值同名，故按 `BottomSheet` 限定。
      final sheet = find.byType(BottomSheet);
      for (final option in <String>['宫格模式', '列表模式']) {
        expect(
          find.descendant(of: sheet, matching: find.text(option)),
          findsOneWidget,
          reason: '选项缺少 $option',
        );
      }

      await tester.tap(find.descendant(of: sheet, matching: find.text('列表模式')));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).noteLayout, NoteLayout.list);
      expect(find.text('列表模式'), findsOneWidget);
      expect(find.text('宫格模式'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('3 个选择器行各自只改自己的字段，且各落盘一次', (tester) async {
      await pumpP5(tester);

      await pick(tester,'select_text_scale', '大');
      await pick(tester,'select_note_sort', '按编辑日期（最早）');
      await pick(tester,'select_note_layout', '列表模式');

      final settings = container.read(settingsProvider);
      expect(settings.textScale, TextScaleLevel.large);
      expect(settings.noteSort, AppNoteSort.editedAsc);
      expect(settings.noteLayout, NoteLayout.list);
      expect(find.text('大'), findsOneWidget);
      expect(find.text('按编辑日期（最早）'), findsOneWidget);
      expect(find.text('列表模式'), findsOneWidget);
      verify(() => repo.save(any())).called(3);
    });

    testWidgets('新值走 provider 而非本地 state：离开页面再进入仍是新值', (tester) async {
      await pumpP5(tester);
      await pick(tester,'select_text_scale', '大');

      // 销毁整个页面再重建（provider 是 keepAlive，state 不该被丢弃）
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpP5(tester);

      expect(find.text('大'), findsOneWidget);
      expect(find.text('默认'), findsNothing);
    });

    testWidgets('强提醒：初始值取自 provider，选「开启」后写回', (tester) async {
      await pumpP5(tester);

      expect(container.read(settingsProvider).strongReminder, isFalse);
      expect(find.text('关闭'), findsOneWidget, reason: '行尾显示当前值');
      expect(
        find.text('持续响铃且静音和勿扰状态下仍有效'),
        findsOneWidget,
        reason: 'D5 强提醒行有副标题',
      );

      await tester.tap(find.byKey(const Key('select_strong_reminder')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.tap(find.text('开启'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).strongReminder, isTrue);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('开启'), findsOneWidget);
    });

    testWidgets('深色模式：点行弹选项单，选中才落盘；选当前值不写', (tester) async {
      await pumpP5(tester);

      expect(container.read(settingsProvider).themeMode, AppThemeMode.system);
      expect(find.text('跟随系统'), findsOneWidget, reason: '行尾显示当前值');
      expect(find.byType(Switch), findsNothing, reason: '已不是开关行');

      await tester.tap(find.byKey(const Key('select_theme_mode')));
      await tester.pumpAndSettle();
      // 三档全列出 —— 开关形态下 `system` 永不可达。
      // ⚠️ 选项文案在弹层内，行尾当前值同名，故必须按 `BottomSheet` 限定。
      final sheet = find.byType(BottomSheet);
      for (final option in <String>['跟随系统', '浅色', '深色']) {
        expect(
          find.descendant(of: sheet, matching: find.text(option)),
          findsOneWidget,
          reason: '选项缺少 $option',
        );
      }

      // 选当前值：不写盘
      await tester.tap(find.descendant(of: sheet, matching: find.text('跟随系统')));
      await tester.pumpAndSettle();
      verifyNever(() => repo.save(any()));

      await tester.tap(find.byKey(const Key('select_theme_mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: sheet, matching: find.text('深色')));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).themeMode, AppThemeMode.dark);
      expect(find.text('深色'), findsOneWidget);
      verify(() => repo.save(any())).called(1);
    });

    testWidgets('深色模式只改自己的字段', (tester) async {
      await pumpP5(tester);

      await tester.tap(find.byKey(const Key('select_theme_mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('深色'));
      await tester.pumpAndSettle();

      final settings = container.read(settingsProvider);
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.textScale, TextScaleLevel.normal);
      expect(settings.noteSort, AppNoteSort.editedDesc);
      expect(settings.noteLayout, NoteLayout.grid);
    });
  });

  group('chevron 行', () {
    /// 仍不可点的一行（Q14：速记二级页无稿）。
    const String deadKey = 'chevron_quick_capture';

    /// 已接线的 3 行（最近删除 / 隐私政策 / 用户协议）。
    const List<String> wiredKeys = <String>[
      'chevron_recent_deleted',
      'chevron_privacy_policy',
      'chevron_user_agreement',
    ];

    testWidgets('每行都有右箭头；不可点行无 InkWell，接线行有', (tester) async {
      await pumpP5(tester);

      for (final key in <String>[deadKey, ...wiredKeys]) {
        expect(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byIcon(AppIcons.chevronRight),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: find.byKey(const Key(deadKey)),
          matching: find.byType(InkWell),
        ),
        findsNothing,
        reason: '$deadKey 包了 InkWell → 可点，违反 Q14',
      );
      for (final key in wiredKeys) {
        expect(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(InkWell),
          ),
          findsOneWidget,
          reason: '$key 应已接线（可点）',
        );
      }
    });
  });

  group('文案与源码不变量', () {
    testWidgets('页面上没有任何一行显示英文小写 key 原文', (tester) async {
      await pumpP5(tester);

      final keyLike = RegExp(r'^[a-z][a-z0-9_]*$');
      final leaked = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .where(keyLike.hasMatch)
          .toList();

      expect(leaked, isEmpty, reason: '泄漏了 key 原文：$leaked');
    });

    test('源码里 7 个缺失 key 的调用与 3 处空 onTap 全部消失', () {
      final source = File(
        'lib/features/settings/presentation/screens/settings_screen.dart',
      ).readAsStringSync();

      for (final key in <String>[
        'change_language',
        'change_theme',
        'notification_settings',
        'localization_demo',
        'localization_demo_description',
      ]) {
        expect(source, isNot(contains(key)), reason: '仍引用 $key');
      }
      expect(source, isNot(contains('（待实现）')));
      // `.notifications` 同理：提醒相关的缺失 key 已全部消失。⚠️ 这里原本还断言
      // `.theme` 不出现 —— 「深色模式」行接上后 `settings.themeMode` 合法命中，
      // 断言随之撤销；主题缺席的约束改由上面 `change_theme` 一项守住。
      expect(source, isNot(contains('.notifications')));
      // Q14 的不可点行只剩「速记」；最近删除 / 隐私政策 / 用户协议已接线。
      expect(source, contains('AppRoutes.noteTrash'));
      expect(source, contains('AppRoutes.privacyPolicy'));
      expect(source, contains('AppRoutes.userAgreement'));
      expect(
        source,
        isNot(contains('onTap: null')),
        reason: 'chevron 行的不可点语义已由「不传 onTap」表达',
      );
    });

    test('P5 只用 `_` 前缀的页面内私有组件', () {
      final source = File(
        'lib/features/settings/presentation/screens/settings_screen.dart',
      ).readAsStringSync();
      final privateWidgets = RegExp(
        r'^class (_\w+)',
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!).toList();

      expect(privateWidgets, containsAll(<String>['_Group']));
      expect(
        privateWidgets.where((name) => !name.startsWith('_')),
        isEmpty,
        reason: '出现了非 `_` 前缀的私有 Widget',
      );
    });

    test('页面不直接依赖 data 层（只经 provider）', () {
      final source = File(
        'lib/features/settings/presentation/screens/settings_screen.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('/data/')));
      expect(source, isNot(contains('settings_providers.dart')));
    });
  });
}
