import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/utils/app_clock.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/data/datasources/lan_client.dart';
import 'package:mynote/features/backup/data/datasources/lan_discovery.dart';
import 'package:mynote/features/backup/data/datasources/lan_server.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';
import 'package:mynote/features/backup/domain/entities/lan_peer.dart';
import 'package:mynote/features/backup/domain/repositories/lan_sync_repository.dart';

/// 局域网设备间同步。
///
/// **对称**：两端跑同一份代码，任何一端都可以是「发起方」也可以是「服务方」。
/// 一次 `POST /sync` 双方各自合并并写自己的库 → **一次往返收敛**。
///
/// 与 WebDAV 同步的差别只有「字节从哪来」：那边是 `GET` + `PUT` 两个动词各一趟，
/// 这边一个 `POST` 一趟完成，顺带把时钟也对上（对时白送，不额外往返）。
///
/// ⛔ 不 import Flutter。
class LanSyncRepositoryImpl implements LanSyncRepository {
  LanSyncRepositoryImpl(this._local, this._discovery, {LanClient? client})
    : _client = client ?? LanClient() {
    _server = LanServer(_serveInbound);
  }

  final BackupLocalDataSource _local;
  final LanDiscovery _discovery;
  final LanClient _client;
  late final LanServer _server;

  @override
  Stream<List<LanPeer>> watchPeers() => _discovery.peers;

  /// 开启「允许本机被连接」：起 HTTP 服务 + 开始广播。
  ///
  /// 两次调用是幂等的（重复开关不会起两个服务 / 两个广播器）。
  @override
  Future<Either<Failure, int>> startHosting(String deviceName) {
    return _guard(() async {
      await _server.start();
      // HTTP 端口是**随机**的（避免撞端口），所以必须在服务起来**之后**才广播它。
      await _discovery.start(advertisedPort: _server.port);
      return _server.port!;
    });
  }

  @override
  Future<Either<Failure, Unit>> stopHosting() {
    return _guard(() async {
      await _server.stop();
      _discovery.stop();
      return unit;
    });
  }

  @override
  bool get isHosting => _server.isRunning;

  @override
  Future<Either<Failure, LanSyncReport>> syncWithPeer(LanPeer peer) {
    return _guard(() async {
      final local = await _local.read();
      final outcome = await _client.syncWith(peer, local);

      // 先落本地再对时：合并结果比时钟更重要，绝不能因为一个算出来的 offset
      // 拿不稳就丢掉已经拿到的数据。
      final writeSkipped = await _local.write(outcome.snapshot);

      // ⛔ **offset 不做合理性检查**。局域网内往返时延是毫秒级，理论上算出来的
      // 偏差不会离谱；但真出现网络抖动时它可能算出个几十秒的假偏差，而「用户时钟
      // 本来就不准」这个前提无法从单次采样里验证。与其加一道会误伤正常值的启发式
      // 门槛，不如如实应用 —— 偏差下次同步就会被刷新。
      AppClock.setOffset(outcome.offset);

      // 结果条数：以「合并结果 vs 我发出去的那份」为准，语义与 WebDAV 同步一致。
      return LanSyncReport(
        changed: _countChanges(local, outcome.snapshot),
        skipped: outcome.skipped + writeSkipped,
        clockOffset: outcome.offset,
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> addManualPeer(String address, String name) {
    return _guard(() async {
      _discovery.addManualPeer(address, name);
      return unit;
    });
  }

  /// 服务端：合并 → 写自己的库 → 回**同一份**合并结果。
  Future<LanSyncResponse> _serveInbound(LanSyncRequest request) async {
    final incoming = BackupSnapshot.parse(request.snapshot);
    final local = await _local.read();
    final merged = BackupSnapshot.merge(local, incoming.snapshot);
    await _local.write(merged.merged);

    // ⛔ 服务端**不**改自己的时钟偏移：对端的偏差是「对端相对我」的，我才是参照系。
    // 反过来做会让两台设备互相把时钟拉向对方。
    return LanSyncResponse(snapshot: merged.merged.toJson(), serverTime: DateTime.now());
  }

  /// 合并结果里有几条是「我这边没有 / 我这边更旧」的。
  ///
  /// ⛔ 不复用 `BackupSnapshot.merge` 的 `inserted` / `updated`：那统计的是
  /// 「**对端**赢了的行数」，而对用户有意义的是「我这边因此变了多少」。
  int _countChanges(BackupSnapshot before, BackupSnapshot after) {
    var changed = 0;
    void count<T>(List<T> a, List<T> b, String Function(T) idOf, DateTime Function(T) versionOf) {
      final beforeById = <String, T>{for (final row in a) idOf(row): row};
      for (final row in b) {
        final mine = beforeById[idOf(row)];
        if (mine == null || versionOf(row).isAfter(versionOf(mine))) changed++;
      }
    }

    count(before.notes, after.notes, (n) => n.id, (n) => n.version);
    count(before.folders, after.folders, (f) => f.id, (f) => f.version);
    count(before.todos, after.todos, (t) => t.id, (t) => t.version);
    return changed;
  }

  /// 异常 → Failure。与 `BackupRepositoryImpl._guard` 同一套映射，不新增类型。
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on LanTransportException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on SocketException catch (e) {
      // 连不上对方 / 对端已关 —— 绝大多数是「那台设备没开允许连接」。
      return Left(NetworkFailure(message: e.message));
    } on HttpException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on TimeoutException {
      return Left(const TimeoutFailure(message: 'LAN sync timed out'));
    } on FormatException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}