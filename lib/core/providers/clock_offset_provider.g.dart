// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_offset_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 启动时恢复偏差，并提供「设置并落盘」的入口。
///
/// ⚛️ **为什么要持久化**：偏差是在局域网同步那一刻算出来的。若不存盘，设备一
/// 重启就回到自己那个不准的系统时钟，而用户可能几天内不再同步 —— 偏移量白校了。
/// 存的是毫秒数（设备时钟偏差常见到分钟级，秒精度够用且数值可读）。

@ProviderFor(ClockOffsetNotifier)
final clockOffsetProvider = ClockOffsetNotifierProvider._();

/// 启动时恢复偏差，并提供「设置并落盘」的入口。
///
/// ⚛️ **为什么要持久化**：偏差是在局域网同步那一刻算出来的。若不存盘，设备一
/// 重启就回到自己那个不准的系统时钟，而用户可能几天内不再同步 —— 偏移量白校了。
/// 存的是毫秒数（设备时钟偏差常见到分钟级，秒精度够用且数值可读）。
final class ClockOffsetNotifierProvider
    extends $NotifierProvider<ClockOffsetNotifier, void> {
  /// 启动时恢复偏差，并提供「设置并落盘」的入口。
  ///
  /// ⚛️ **为什么要持久化**：偏差是在局域网同步那一刻算出来的。若不存盘，设备一
  /// 重启就回到自己那个不准的系统时钟，而用户可能几天内不再同步 —— 偏移量白校了。
  /// 存的是毫秒数（设备时钟偏差常见到分钟级，秒精度够用且数值可读）。
  ClockOffsetNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockOffsetProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockOffsetNotifierHash();

  @$internal
  @override
  ClockOffsetNotifier create() => ClockOffsetNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$clockOffsetNotifierHash() =>
    r'8f0718df7d08fd2ac16c751c5c3c0b90cc12a742';

/// 启动时恢复偏差，并提供「设置并落盘」的入口。
///
/// ⚛️ **为什么要持久化**：偏差是在局域网同步那一刻算出来的。若不存盘，设备一
/// 重启就回到自己那个不准的系统时钟，而用户可能几天内不再同步 —— 偏移量白校了。
/// 存的是毫秒数（设备时钟偏差常见到分钟级，秒精度够用且数值可读）。

abstract class _$ClockOffsetNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
