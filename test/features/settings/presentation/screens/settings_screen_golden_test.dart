import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/domain/repositories/settings_repository.dart';
import 'package:mynote/features/settings/presentation/screens/settings_screen.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoloto/zoloto.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// 与笔记列表 / 待办 / 笔记详情 / 文件夹管理四份基线同一视口，便于横向比对。
const TestEnvironment goldenEnv = TestEnvironment(
  name: 'light',
  size: Size(360, 778),
  pixelRatio: 1.0,
  platform: TargetPlatform.android,
);

void main() {
  setUpAll(() => registerFallbackValue(const AppSettings.defaults()));

  testGoldenWidgets('设置 — 默认档（文字大小「默认」/ 按编辑日期 / 宫格模式）', (tester) async {
    final repo = _MockSettingsRepository();
    when(() => repo.load()).thenAnswer(
      (_) async => const Right<Failure, AppSettings>(AppSettings.defaults()),
    );
    when(
      () => repo.save(any()),
    ).thenAnswer((_) async => const Right<Failure, Unit>(unit));

    await expectMatchTestEnvironments(
      'settings_screen',
      tester: tester,
      widget: ProviderScope(
        // override 打在 Repository 层：测试环境无 `shared_preferences` 插件实现。
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            ...AppLocalizations.localizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          debugShowCheckedModeBanner: false,
          home: const SettingsScreen(),
        ),
      ),
      testEnvironments: <TestEnvironment>[goldenEnv],
    );
  });
}
