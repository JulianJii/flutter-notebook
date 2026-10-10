// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lan_sync_peers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 局域网里发现的设备。
///
/// ⚠️ `keepAlive: true`：底层那个 `LanDiscovery` 持有 **UDP socket**，它**必须**在
/// 整个 App 生命周期内存活 —— 屏幕被划掉又回来时，重新 bind 一次会换端口，
/// 而广播出去的端口与实际监听的对不上，症状是「对方明明开着却连不上」。
/// socket 的关闭由 [LanSyncScreen.dispose] 显式负责（离开页面即停止服务）。

@ProviderFor(lanSyncPeers)
final lanSyncPeersProvider = LanSyncPeersProvider._();

/// 局域网里发现的设备。
///
/// ⚠️ `keepAlive: true`：底层那个 `LanDiscovery` 持有 **UDP socket**，它**必须**在
/// 整个 App 生命周期内存活 —— 屏幕被划掉又回来时，重新 bind 一次会换端口，
/// 而广播出去的端口与实际监听的对不上，症状是「对方明明开着却连不上」。
/// socket 的关闭由 [LanSyncScreen.dispose] 显式负责（离开页面即停止服务）。

final class LanSyncPeersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LanPeer>>,
          List<LanPeer>,
          Stream<List<LanPeer>>
        >
    with $FutureModifier<List<LanPeer>>, $StreamProvider<List<LanPeer>> {
  /// 局域网里发现的设备。
  ///
  /// ⚠️ `keepAlive: true`：底层那个 `LanDiscovery` 持有 **UDP socket**，它**必须**在
  /// 整个 App 生命周期内存活 —— 屏幕被划掉又回来时，重新 bind 一次会换端口，
  /// 而广播出去的端口与实际监听的对不上，症状是「对方明明开着却连不上」。
  /// socket 的关闭由 [LanSyncScreen.dispose] 显式负责（离开页面即停止服务）。
  LanSyncPeersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lanSyncPeersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lanSyncPeersHash();

  @$internal
  @override
  $StreamProviderElement<List<LanPeer>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<LanPeer>> create(Ref ref) {
    return lanSyncPeers(ref);
  }
}

String _$lanSyncPeersHash() => r'39916642553c3cdc0dac300c63389fdc91210dc0';
