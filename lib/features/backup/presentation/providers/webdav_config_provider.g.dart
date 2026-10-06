// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webdav_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// WebDAV 配置的读写入口。
///
/// 与 `settingsProvider` 同形态：`build()` 同步给默认值，microtask 里读盘。
/// `keepAlive: true` —— 数据与同步页、配置页、启动同步三处都要读它。

@ProviderFor(WebDavConfigNotifier)
final webDavConfigProvider = WebDavConfigNotifierProvider._();

/// WebDAV 配置的读写入口。
///
/// 与 `settingsProvider` 同形态：`build()` 同步给默认值，microtask 里读盘。
/// `keepAlive: true` —— 数据与同步页、配置页、启动同步三处都要读它。
final class WebDavConfigNotifierProvider
    extends $NotifierProvider<WebDavConfigNotifier, WebDavConfig> {
  /// WebDAV 配置的读写入口。
  ///
  /// 与 `settingsProvider` 同形态：`build()` 同步给默认值，microtask 里读盘。
  /// `keepAlive: true` —— 数据与同步页、配置页、启动同步三处都要读它。
  WebDavConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webDavConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webDavConfigNotifierHash();

  @$internal
  @override
  WebDavConfigNotifier create() => WebDavConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebDavConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebDavConfig>(value),
    );
  }
}

String _$webDavConfigNotifierHash() =>
    r'59222ce1b619edab61ea838eb02403404eabd6eb';

/// WebDAV 配置的读写入口。
///
/// 与 `settingsProvider` 同形态：`build()` 同步给默认值，microtask 里读盘。
/// `keepAlive: true` —— 数据与同步页、配置页、启动同步三处都要读它。

abstract class _$WebDavConfigNotifier extends $Notifier<WebDavConfig> {
  WebDavConfig build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WebDavConfig, WebDavConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WebDavConfig, WebDavConfig>,
              WebDavConfig,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
