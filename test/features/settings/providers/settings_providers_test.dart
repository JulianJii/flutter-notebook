import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/providers/settings_providers.dart';
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

  test('走 sharedPreferencesProvider 链（不是自己 new LocalStorageService）', () {
    // 静态类型是接口 `SettingsRepository`，所以 `isA<SettingsRepositoryImpl>()`
    // 才是真断言：它证明 DI 装的是 Impl，装错成别的实现就红。
    expect(
      container.read(settingsRepositoryProvider),
      isA<SettingsRepositoryImpl>(),
    );
  });

  test('端到端：save -> load 往返一致', () async {
    await container.read(saveSettingsUseCaseProvider)(
      const AppSettings(themeMode: AppThemeMode.dark),
    );
    final loaded = await container.read(getSettingsUseCaseProvider)(NoParams());
    loaded.fold((f) => fail('应为 Right，实际 $f'), (s) {
      expect(s.themeMode, AppThemeMode.dark);
    });
  });
}
