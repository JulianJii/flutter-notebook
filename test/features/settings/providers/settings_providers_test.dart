import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:init/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('repository + 2 个 use case provider 可解析', () {
    expect(
      container.read(settingsRepositoryProvider),
      isA<SettingsRepository>(),
    );
    expect(
      container.read(getSettingsUseCaseProvider),
      isA<GetSettingsUseCase>(),
    );
    expect(
      container.read(saveSettingsUseCaseProvider),
      isA<SaveSettingsUseCase>(),
    );
  });

  test('走 sharedPreferencesProvider 链（不是自己 new LocalStorageService）', () {
    expect(
      container.read(settingsRepositoryProvider),
      isA<SettingsRepositoryImpl>(),
    );
    // 同一个容器内只装配一次：重复读返回同一实例，说明没有被重复 new。
    expect(
      container.read(settingsRepositoryProvider),
      same(container.read(settingsRepositoryProvider)),
    );
  });

  test('端到端：save -> load 往返一致', () async {
    await container.read(saveSettingsUseCaseProvider)(
      const AppSettings(locale: 'en', themeMode: AppThemeMode.dark),
    );
    final loaded = await container.read(getSettingsUseCaseProvider)(NoParams());
    loaded.fold((f) => fail('应为 Right，实际 $f'), (s) {
      expect(s.locale, 'en');
      expect(s.themeMode, AppThemeMode.dark);
    });
  });
}
