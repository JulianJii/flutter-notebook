// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ⛔ **不自己 new `LocalStorageService`**：必须走 [localStorageServiceProvider]
/// → `sharedPreferencesProvider` 这条既有 provider 链，测试才能替换依赖
/// （`main.dart` 在 `overrides` 里替换的就是 `sharedPreferencesProvider`）。

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// ⛔ **不自己 new `LocalStorageService`**：必须走 [localStorageServiceProvider]
/// → `sharedPreferencesProvider` 这条既有 provider 链，测试才能替换依赖
/// （`main.dart` 在 `overrides` 里替换的就是 `sharedPreferencesProvider`）。

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// ⛔ **不自己 new `LocalStorageService`**：必须走 [localStorageServiceProvider]
  /// → `sharedPreferencesProvider` 这条既有 provider 链，测试才能替换依赖
  /// （`main.dart` 在 `overrides` 里替换的就是 `sharedPreferencesProvider`）。
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'57fc8432e00c8ddc3b82b56bc58fb529d54cc06a';

@ProviderFor(getSettingsUseCase)
final getSettingsUseCaseProvider = GetSettingsUseCaseProvider._();

final class GetSettingsUseCaseProvider
    extends
        $FunctionalProvider<
          GetSettingsUseCase,
          GetSettingsUseCase,
          GetSettingsUseCase
        >
    with $Provider<GetSettingsUseCase> {
  GetSettingsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getSettingsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getSettingsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSettingsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetSettingsUseCase create(Ref ref) {
    return getSettingsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSettingsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSettingsUseCase>(value),
    );
  }
}

String _$getSettingsUseCaseHash() =>
    r'09c503ca87f7a3fdda8750ca6f256cd5ef800f73';

@ProviderFor(saveSettingsUseCase)
final saveSettingsUseCaseProvider = SaveSettingsUseCaseProvider._();

final class SaveSettingsUseCaseProvider
    extends
        $FunctionalProvider<
          SaveSettingsUseCase,
          SaveSettingsUseCase,
          SaveSettingsUseCase
        >
    with $Provider<SaveSettingsUseCase> {
  SaveSettingsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveSettingsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveSettingsUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveSettingsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveSettingsUseCase create(Ref ref) {
    return saveSettingsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveSettingsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveSettingsUseCase>(value),
    );
  }
}

String _$saveSettingsUseCaseHash() =>
    r'deebc3301db604f50375ca72b371f0ca2bdd8f89';
