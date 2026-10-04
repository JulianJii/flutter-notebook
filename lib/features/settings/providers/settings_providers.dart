import 'package:init/core/providers/storage_providers.dart';
import 'package:init/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:init/features/settings/domain/repositories/settings_repository.dart';
import 'package:init/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:init/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

// ⛔ **零 import `features/notes` / `features/todos`**：features 之间不互相依赖。
// ⛔ provider 体只做装配。

// ---- repository ----
/// ⛔ **不自己 new `LocalStorageService`**：必须走 [localStorageServiceProvider]
/// → `sharedPreferencesProvider` 这条既有 provider 链，测试才能替换依赖
/// （`main.dart` 在 `overrides` 里替换的就是 `sharedPreferencesProvider`）。
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepositoryImpl(ref.watch(localStorageServiceProvider));
}

// ---- use case ----
@riverpod
GetSettingsUseCase getSettingsUseCase(Ref ref) {
  return GetSettingsUseCase(ref.watch(settingsRepositoryProvider));
}

@riverpod
SaveSettingsUseCase saveSettingsUseCase(Ref ref) {
  return SaveSettingsUseCase(ref.watch(settingsRepositoryProvider));
}
