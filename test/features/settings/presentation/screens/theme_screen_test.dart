import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/theme/app_color_scheme.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/features/settings/presentation/providers/settings_provider.dart';
import 'package:init/features/settings/presentation/screens/theme_screen.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

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
    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpThemePage(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: const ThemeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 分段控件内的某一档。⚠️ 档位文案在「当前：…」回显里也出现，必须限定范围。
  Finder segment(String label) => find.descendant(
    of: find.byType(SegmentedButton<AppThemeMode>),
    matching: find.text(label),
  );

  testWidgets('明暗三档一次全见：浅色 / 深色 / 跟随系统，默认在跟随系统', (
    tester,
  ) async {
    await pumpThemePage(tester);

    expect(container.read(settingsProvider).themeMode, AppThemeMode.system);
    for (final label in <String>['浅色', '深色', '跟随系统']) {
      expect(segment(label), findsOneWidget, reason: '缺少档位 $label');
    }
  });

  testWidgets('点档位即切换并落盘；点当前档不写盘', (tester) async {
    await pumpThemePage(tester);

    await tester.tap(segment('深色'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).themeMode, AppThemeMode.dark);

    // 同一个值再点一次：`_write` 比对 state 相同 → 不产生第二次 IO。
    // ⚠️ `verify` 只调用一次：mocktail 的 verify 会把已匹配的调用移出记录。
    await tester.tap(segment('深色'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).themeMode, AppThemeMode.dark);
    verify(() => repo.save(any())).called(1);
  });

  testWidgets('明暗只改自己的字段', (tester) async {
    await pumpThemePage(tester);

    await tester.tap(segment('浅色'));
    await tester.pumpAndSettle();

    final settings = container.read(settingsProvider);
    expect(settings.themeMode, AppThemeMode.light);
    expect(settings.colorScheme, AppColorScheme.amber);
    expect(settings.textScale, TextScaleLevel.normal);
  });

  testWidgets('配色方案 4 行，只有当前方案带勾', (tester) async {
    await pumpThemePage(tester);

    for (final scheme in AppColorScheme.values) {
      expect(find.byKey(Key('palette_${scheme.name}')), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(const Key('palette_amber')),
        matching: find.byIcon(AppIcons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('palette_blue')),
        matching: find.byIcon(AppIcons.check),
      ),
      findsNothing,
    );
  });

  testWidgets('选配色：勾跟着走，且与明暗互不干扰', (tester) async {
    await pumpThemePage(tester);

    await tester.tap(segment('深色'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('palette_violet')));
    await tester.pumpAndSettle();

    final settings = container.read(settingsProvider);
    expect(settings.colorScheme, AppColorScheme.violet);
    expect(settings.themeMode, AppThemeMode.dark, reason: '明暗不该被配色覆盖');
    expect(
      find.descendant(
        of: find.byKey(const Key('palette_violet')),
        matching: find.byIcon(AppIcons.check),
      ),
      findsOneWidget,
    );
    verify(() => repo.save(any())).called(2);
  });

  testWidgets('回显当前组合：配色 · 明暗', (tester) async {
    await pumpThemePage(tester);

    expect(find.text('当前：琥珀 · 跟随系统'), findsOneWidget);

    await tester.tap(find.byKey(const Key('palette_green')));
    await tester.pumpAndSettle();
    await tester.tap(segment('浅色'));
    await tester.pumpAndSettle();

    expect(find.text('当前：绿色 · 浅色'), findsOneWidget);
  });

  testWidgets('配色决定强调色：换方案后 context.colors.accent 跟着变', (
    tester,
  ) async {
    await pumpThemePage(tester);

    await tester.tap(find.byKey(const Key('palette_blue')));
    await tester.pumpAndSettle();

    // 主题由 `main.dart` 按 `AppTheme.light(colorScheme)` 重建；这里直接验证
    // 方案主色与主题强调色是同一个值，避免两处各写一份色值后漂移。
    expect(
      AppTheme.light(AppColorScheme.blue).colorScheme.primary,
      Color(AppColorScheme.blue.seed),
    );
    expect(
      AppTheme.light(AppColorScheme.blue).extension<AppColors>()!.accent,
      Color(AppColorScheme.blue.seed),
    );
  });
}
