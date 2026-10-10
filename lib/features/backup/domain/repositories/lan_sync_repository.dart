import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/backup/domain/entities/lan_peer.dart';

/// 局域网设备间同步的领域抽象。实现在 data 层。
///
/// **对称**：没有「主机 / 客户端」之分 —— 两端跑同一套代码，任何一端都可以
/// 开启「允许被连接」并主动连别人。
abstract class LanSyncRepository {
  /// 局域网里发现到的设备（**新 → 旧无关，按 IP 稳定排序**，便于 UI 不跳动）。
  Stream<List<LanPeer>> watchPeers();

  /// 开启「允许本机被连接」：起 HTTP 服务 + 开始广播。返回实际绑定的端口。
  /// 幂等：已在跑时直接返回当前端口。
  Future<Either<Failure, int>> startHosting(String deviceName);

  /// 关闭服务与广播。幂等。
  Future<Either<Failure, Unit>> stopHosting();

  bool get isHosting;

  /// 与一台设备同步：一次 `POST /sync` 往返即双方收敛，**顺带完成一次对时**。
  Future<Either<Failure, LanSyncReport>> syncWithPeer(LanPeer peer);

  /// 手输 IP 加一台设备（广播被路由器丢弃时的兜底）。
  Future<Either<Failure, Unit>> addManualPeer(String address, String name);
}

/// 一次局域网同步的结果。
class LanSyncReport {
  const LanSyncReport({
    required this.changed,
    required this.skipped,
    required this.clockOffset,
  });

  /// 本机因此变动的条数（新增 + 更新）。
  final int changed;

  /// 跳过条数（对端快照里的坏行 + 本地写不进去的）。
  final int skipped;

  /// 本次对时算出的时钟偏差，已写进 `AppClock`。给 UI 显示用 ——
  /// 用户看得见「时钟已对齐到那台设备」，才不会把它当玄学。
  final Duration clockOffset;
}