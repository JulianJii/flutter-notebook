// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localization_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 本地化服务的 Provider

@ProviderFor(localizationService)
final localizationServiceProvider = LocalizationServiceProvider._();

/// 本地化服务的 Provider

final class LocalizationServiceProvider
    extends
        $FunctionalProvider<
          LocalizationService,
          LocalizationService,
          LocalizationService
        >
    with $Provider<LocalizationService> {
  /// 本地化服务的 Provider
  LocalizationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localizationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localizationServiceHash();

  @$internal
  @override
  $ProviderElement<LocalizationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalizationService create(Ref ref) {
    return localizationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalizationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalizationService>(value),
    );
  }
}

String _$localizationServiceHash() =>
    r'73a9313d4c39a761704a77d8d58a48906a0503b8';
