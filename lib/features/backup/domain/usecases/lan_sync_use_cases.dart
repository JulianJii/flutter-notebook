import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/backup/domain/entities/lan_peer.dart';
import 'package:mynote/features/backup/domain/repositories/lan_sync_repository.dart';

/// 局域网同步的全部动作，**共用同一个 repository 实例**。
///
/// ⛔ **刻意不拆成 4 个 use case**：这个 repository 持有 `HttpServer` 与
/// `LanDiscovery` 的 socket —— 它们**必须是同一个实例**才有意义（宿主端要能
/// 发现自己广播出去的端口，客户端要连上同一个监听器）。拆成四个 provider 后，
/// 每个都要自己 `ref.watch(...)`，而 Riverpod 的 `keepAlive` 差异一旦配错就会
/// 拿到两个实例，于是「我开了服务但列表里没有我」。一个对象 = 一次装配 =
/// 结构上不可能拿错。
///
/// ponytail: 真的出现「某个动作要被单独 mock 掉」的需求时再拆 —— 那时这些用例
/// 才有独立存在的意义。
class LanSyncUseCases {
  const LanSyncUseCases(this._repository);

  final LanSyncRepository _repository;

  /// 局域网里发现到的设备。
  Stream<List<LanPeer>> watchPeers() => _repository.watchPeers();

  /// 开启「允许本机被连接」，返回实际绑定的端口。
  Future<Either<Failure, int>> startHosting(String deviceName) =>
      _repository.startHosting(deviceName);

  Future<Either<Failure, Unit>> stopHosting() => _repository.stopHosting();

  bool get isHosting => _repository.isHosting;

  /// 与一台设备同步（一次往返即双方收敛，顺带完成一次对时）。
  Future<Either<Failure, LanSyncReport>> syncWithPeer(LanPeer peer) =>
      _repository.syncWithPeer(peer);

  /// 手输 IP 加设备（广播被路由器丢弃时的兜底）。
  Future<Either<Failure, Unit>> addManualPeer(String address, String name) =>
      _repository.addManualPeer(address, name);
}