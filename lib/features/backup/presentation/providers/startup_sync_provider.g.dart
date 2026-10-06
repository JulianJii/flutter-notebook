// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup_sync_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App 启动时的一次自动同步。
///
/// 由 `main.dart` 里 `ref.watch(startupSyncProvider)` 挂载 —— `AsyncNotifier` 的
/// [build] 只在首次监听时跑一次，正好是「启动一次」的语义。
///
/// ⛔ **不做后台定时同步**：`workmanager` 要接平台配置与任务注册，而本 App 的
/// 数据是本地的，同步只是「顺手带一把」，不值得为它引入一条后台链路。
/// ⛔ **不弹任何提示**：启动时用户可能在任何页面，一次失败的自动同步不该打断他；
/// 结果只进日志，要看结果去设置页点「立即同步」。

@ProviderFor(StartupSync)
final startupSyncProvider = StartupSyncProvider._();

/// App 启动时的一次自动同步。
///
/// 由 `main.dart` 里 `ref.watch(startupSyncProvider)` 挂载 —— `AsyncNotifier` 的
/// [build] 只在首次监听时跑一次，正好是「启动一次」的语义。
///
/// ⛔ **不做后台定时同步**：`workmanager` 要接平台配置与任务注册，而本 App 的
/// 数据是本地的，同步只是「顺手带一把」，不值得为它引入一条后台链路。
/// ⛔ **不弹任何提示**：启动时用户可能在任何页面，一次失败的自动同步不该打断他；
/// 结果只进日志，要看结果去设置页点「立即同步」。
final class StartupSyncProvider
    extends $AsyncNotifierProvider<StartupSync, void> {
  /// App 启动时的一次自动同步。
  ///
  /// 由 `main.dart` 里 `ref.watch(startupSyncProvider)` 挂载 —— `AsyncNotifier` 的
  /// [build] 只在首次监听时跑一次，正好是「启动一次」的语义。
  ///
  /// ⛔ **不做后台定时同步**：`workmanager` 要接平台配置与任务注册，而本 App 的
  /// 数据是本地的，同步只是「顺手带一把」，不值得为它引入一条后台链路。
  /// ⛔ **不弹任何提示**：启动时用户可能在任何页面，一次失败的自动同步不该打断他；
  /// 结果只进日志，要看结果去设置页点「立即同步」。
  StartupSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupSyncHash();

  @$internal
  @override
  StartupSync create() => StartupSync();
}

String _$startupSyncHash() => r'18093d8e534008d3bf151f0424de5f939f002717';

/// App 启动时的一次自动同步。
///
/// 由 `main.dart` 里 `ref.watch(startupSyncProvider)` 挂载 —— `AsyncNotifier` 的
/// [build] 只在首次监听时跑一次，正好是「启动一次」的语义。
///
/// ⛔ **不做后台定时同步**：`workmanager` 要接平台配置与任务注册，而本 App 的
/// 数据是本地的，同步只是「顺手带一把」，不值得为它引入一条后台链路。
/// ⛔ **不弹任何提示**：启动时用户可能在任何页面，一次失败的自动同步不该打断他；
/// 结果只进日志，要看结果去设置页点「立即同步」。

abstract class _$StartupSync extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
