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
///
/// `keepAlive: true`：这三个 provider 是 `settingsProvider`（全局 keepAlive 状态）
/// 的依赖链。keepAlive 的 provider 不允许 read/watch autoDispose 的 provider
/// （`only_use_keep_alive_inside_keep_alive`），故整条链一起常驻。三者都是无状态
/// 薄壳，keepAlive 无副作用。

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// ⛔ **不自己 new `LocalStorageService`**：必须走 [localStorageServiceProvider]
/// → `sharedPreferencesProvider` 这条既有 provider 链，测试才能替换依赖
/// （`main.dart` 在 `overrides` 里替换的就是 `sharedPreferencesProvider`）。
///
/// `keepAlive: true`：这三个 provider 是 `settingsProvider`（全局 keepAlive 状态）
/// 的依赖链。keepAlive 的 provider 不允许 read/watch autoDispose 的 provider
/// （`only_use_keep_alive_inside_keep_alive`），故整条链一起常驻。三者都是无状态
/// 薄壳，keepAlive 无副作用。

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
  ///
  /// `keepAlive: true`：这三个 provider 是 `settingsProvider`（全局 keepAlive 状态）
  /// 的依赖链。keepAlive 的 provider 不允许 read/watch autoDispose 的 provider
  /// （`only_use_keep_alive_inside_keep_alive`），故整条链一起常驻。三者都是无状态
  /// 薄壳，keepAlive 无副作用。
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
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
    r'81a0008a42959f2dbddbcc36c2eb19f610a85579';

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
        isAutoDispose: false,
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
    r'bf3ab3420993942a7c9585499120b437be8e305e';

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
        isAutoDispose: false,
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
    r'cbc9eaafc06e74165d3c3342d9bf2f649424a38c';
