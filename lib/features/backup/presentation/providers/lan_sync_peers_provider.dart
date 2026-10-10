import 'package:mynote/features/backup/domain/entities/lan_peer.dart';
import 'package:mynote/features/backup/providers/backup_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lan_sync_peers_provider.g.dart';

/// 局域网里发现的设备。
///
/// ⚠️ `keepAlive: true`：底层那个 `LanDiscovery` 持有 **UDP socket**，它**必须**在
/// 整个 App 生命周期内存活 —— 屏幕被划掉又回来时，重新 bind 一次会换端口，
/// 而广播出去的端口与实际监听的对不上，症状是「对方明明开着却连不上」。
/// socket 的关闭由 [LanSyncScreen.dispose] 显式负责（离开页面即停止服务）。
@Riverpod(keepAlive: true)
Stream<List<LanPeer>> lanSyncPeers(Ref ref) {
  return ref.watch(lanSyncUseCasesProvider).watchPeers();
}