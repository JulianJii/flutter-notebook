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

/// D5 的 5 个分组标题，顺序即 `UI-IMPLEMENTATION-SPEC.md` §4 P5 段。
const List<String> _groupTitles = <String>['云服务', '笔记样式', '快捷功能', '提醒', '其他'];

const List<String> _groupKeys = <String>[
  'section_cloud',
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

  group('D5 结构', () {
    testWidgets('渲染出 5 个分组，顺序为 云服务 → 笔记样式 → 快捷功能 → 提醒 → 其他', (tester) async {
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

    testWidgets('顶栏只有 back 箭头：无标题、无右侧动作、无分隔线', (tester) async {
      await pumpP5(tester);

      final topBar = tester.widget<AppTopBar>(find.byType(AppTopBar));
      expect(topBar.centerTitle, isNull, reason: 'D5 顶栏无标题');
      expect(topBar.actions, isEmpty, reason: 'D5 顶栏无右侧动作');
      expect(topBar.showDivider, isFalse, reason: 'D5 顶栏下无 1dp 分隔线');
      expect(find.byIcon(AppIcons.back), findsOneWidget);
    });

    testWidgets('大标题是「笔记」，位于分组卡之上', (tester) async {
      await pumpP5(tester);

      final title = find.byType(AppLargeTitle);
      expect(title, findsOneWidget);
      expect(
        find.descendant(of: title, matching: find.text('笔记')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(title).dy,
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

    testWidgets('同卡片内第 2 行起各有一条 1dp 分割线（共 3 条）', (tester) async {
      await pumpP5(tester);

      // 笔记样式 3 行 → 2 条，其他 2 行 → 1 条。
      expect(find.byType(AppDivider), findsNWidgets(3));
    });

    testWidgets('5 张分组卡，8 行', (tester) async {
      await pumpP5(tester);

      expect(find.byType(AppCard), findsNWidgets(5));
      expect(find.byType(AppListTile), findsNWidgets(8));
      expect(find.byType(AppSwitchRow), findsOneWidget);
    });
  });

  group('4 个可写行走 settingsProvider', () {
    testWidgets('3 个 stepper 行显示当前值文案，不是枚举英文名', (tester) async {
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

    testWidgets('点 stepper 行：循环到下一个值，右侧文案随之改变', (tester) async {
      await pumpP5(tester);

      await tester.tap(find.byKey(const Key('stepper_note_layout')));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).noteLayout, NoteLayout.list);
      expect(find.text('列表模式'), findsOneWidget);
      expect(find.text('宫格模式'), findsNothing);

      // 再点回到第一档（2 值循环）
      await tester.tap(find.byKey(const Key('stepper_note_layout')));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).noteLayout, NoteLayout.grid);
    });

    testWidgets('3 个 stepper 行各自只改自己的字段，且落盘一次', (tester) async {
      await pumpP5(tester);

      await tester.tap(find.byKey(const Key('stepper_text_scale')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stepper_note_sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stepper_note_layout')));
      await tester.pumpAndSettle();

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
      await tester.tap(find.byKey(const Key('stepper_text_scale')));
      await tester.pumpAndSettle();

      // 销毁整个页面再重建（provider 是 keepAlive，state 不该被丢弃）
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpP5(tester);

      expect(find.text('大'), findsOneWidget);
      expect(find.text('默认'), findsNothing);
    });

    testWidgets('强提醒开关：初始值取自 provider，切换后写回', (tester) async {
      await pumpP5(tester);

      final switchFinder = find.descendant(
        of: find.byKey(const Key('switch_strong_reminder')),
        matching: find.byType(Switch),
      );
      expect(container.read(settingsProvider).strongReminder, isFalse);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).strongReminder, isTrue);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);
      expect(
        find.text('持续响铃且静音和勿扰状态下仍有效'),
        findsOneWidget,
        reason: 'D5 强提醒行有副标题',
      );
    });
  });

  group('4 个 chevron 行按 Q14 保持不可点', () {
    const List<String> chevronKeys = <String>[
      'chevron_recent_deleted',
      'chevron_quick_capture',
      'chevron_privacy_policy',
      'chevron_user_agreement',
    ];

    testWidgets('每行都有右箭头但没有 InkWell（= 不可点）', (tester) async {
      await pumpP5(tester);

      expect(find.byIcon(AppIcons.chevronRight), findsNWidgets(4));
      for (final key in chevronKeys) {
        expect(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(InkWell),
          ),
          findsNothing,
          reason: '$key 包了 InkWell → 可点，违反 Q14',
        );
      }
    });

    testWidgets('点击无任何反应：不跳转、不弹层、不改偏好、不崩', (tester) async {
      await pumpP5(tester);
      final before = container.read(settingsProvider);

      for (final key in chevronKeys) {
        await tester.tap(find.byKey(Key(key)), warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(container.read(settingsProvider), before);
      verifyNever(() => repo.save(any()));
      expect(tester.takeException(), isNull);
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
      // `theme` / `notifications` 这两个词只会以 l10n getter 形式出现在别处，
      // 这里只断言它们不再被 `AppLocalizations` 取用。
      expect(source, isNot(contains('.theme')));
      expect(source, isNot(contains('.notifications')));
      expect(source, contains('// TODO(Q14)'), reason: 'Q14 需留标注');
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
