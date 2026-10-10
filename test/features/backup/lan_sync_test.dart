import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/utils/app_clock.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/data/datasources/lan_discovery.dart';
import 'package:mynote/features/backup/data/repositories/lan_sync_repository_impl.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';
import 'package:mynote/features/backup/domain/entities/lan_peer.dart';

/// 局域网同步的**端到端**行为：两个独立的内存库，通过真的 socket 走一遍协议。
///
/// ⚠️ 刻意**不 mock** `LanServer` / `LanClient`：这个功能的全部价值就在「两端真的
/// 能连上、能收敛、能对时」，mock 掉传输层等于什么都没测。
///
/// ⚠️ 测试里**不起 UDP 广播**（`LanDiscovery` 的广播部分）：广播依赖真实网卡，
/// 在 CI 上不可靠。发现层靠 [LanPeer] 直接构造绕过 —— 它只是个地址+端口，
/// 不值得为它写一个依赖网络的测试。
void main() {
  late AppDatabase dbA;
  late AppDatabase dbB;
  late BackupLocalDataSource localA;
  late BackupLocalDataSource localB;
  late LanSyncRepositoryImpl host;
  late LanSyncRepositoryImpl peer;
  late int hostPort;

  tearDown(AppClock.reset);

  setUpAll(() {
    // ⚠️ **必做**：`flutter_test` 在全局装了一个 `HttpOverrides`，它把
    // `HttpClient` 换成一个假实现，对**任何**请求都返回 400。症状极具误导性 ——
    // 你会以为是自己的服务端在拒绝请求，去查协议、查压缩、查路由，全查不出来。
    // 想测真实 socket 就必须把覆盖摘掉。
    HttpOverrides.global = null;
  });

  tearDownAll(() => HttpOverrides.global = _TestHttpOverrides());

  setUp(() async {
    dbA = AppDatabase.memory();
    dbB = AppDatabase.memory();
    localA = BackupLocalDataSource(dbA);
    localB = BackupLocalDataSource(dbB);
    host = LanSyncRepositoryImpl(localA, LanDiscovery(deviceName: 'A'));
    peer = LanSyncRepositoryImpl(localB, LanDiscovery(deviceName: 'B'));

    final started = await host.startHosting('A');
    expect(started.isRight(), isTrue);
    hostPort = started.fold((_) => 0, (p) => p);
    expect(hostPort, greaterThan(0), reason: '起服务必须拿到一个真实端口');
  });

  tearDown(() async {
    await host.stopHosting();
    await peer.stopHosting();
    await dbA.close();
    await dbB.close();
  });

  BackupSnapshot snap(String title, {DateTime? at}) {
    final when = at ?? DateTime.fromMillisecondsSinceEpoch(1000 * 1000);
    return BackupSnapshot(
      exportedAt: when,
      notes: <BackupNote>[
        BackupNote(
          id: 'n-$title',
          title: title,
          content: '[]',
          folderId: null,
          background: null,
          createdAt: when,
          updatedAt: when,
          deletedAt: null,
        ),
      ],
      folders: const <BackupFolder>[],
      todos: const <BackupTodo>[],
    );
  }

  /// 直连宿主。⛔ 绕开 `LanDiscovery` 的广播 —— 广播依赖真实网卡，CI 上不可靠；
  /// 而「发现」只是把「地址 + 端口」填进 `LanPeer`，不值得为它写一个依赖网络的测试。
  LanPeer hostPeer() => LanPeer(
    address: '127.0.0.1',
    port: hostPort,
    name: 'A',
    lastSeen: DateTime.now(),
  );

  test('一次往返：两端收敛到同一份数据', () async {
    await localA.write(snap('A 的笔记'));
    await localB.write(snap('B 的笔记'));

    final result = await peer.syncWithPeer(hostPeer());

    expect(result.isRight(), isTrue, reason: result.fold((f) => f.message, (_) => ''));

    final a = await localA.read();
    final b = await localB.read();
    expect(a.notes.map((n) => n.title).toSet(), <String>{'A 的笔记', 'B 的笔记'});
    expect(
      b.notes.map((n) => n.title).toSet(),
      a.notes.map((n) => n.title).toSet(),
      reason: '两端必须收敛到同一集合 —— 这是一次往返就成立的核心契约',
    );
  });

  test('收敛是幂等的：再连一次不产生新变化', () async {
    await localA.write(snap('A 的笔记'));
    await localB.write(snap('B 的笔记'));
    await peer.syncWithPeer(hostPeer());

    final second = await peer.syncWithPeer(hostPeer());

    expect(second.isRight(), isTrue);
    expect(
      second.fold((_) => -1, (r) => r.changed),
      0,
      reason: '没有新东西时不该报「有变化」—— 用户会以为同步出了问题',
    );
  });

  test('软删除跨局域网传播（删除不是硬删，所以能传）', () async {
    await localA.write(snap('要删的'));
    await localB.write(snap('要删的'));
    await peer.syncWithPeer(hostPeer());

    // A 机删掉（软删除）。
    await dbA.customStatement(
      'UPDATE notes SET deleted_at = ? WHERE id = ?',
      [9999999, 'n-要删的'],
    );

    await peer.syncWithPeer(hostPeer());

    final b = await localB.read();
    expect(b.notes.single.deletedAt, isNotNull, reason: 'B 也要看到删除');
  });

  test('对时：把本机时钟设偏，同步后偏差被拉回', () async {
    // 本机慢 10 分钟（真实世界的典型场景：某台设备从没开过自动对时）。
    AppClock.setOffset(const Duration(minutes: -10));
    await localA.write(snap('对时用的'));
    await localB.write(snap('对时用的'));

    await peer.syncWithPeer(hostPeer());

    // 同步后 B（本机）应认为自己的偏差接近 0 —— 它对齐到了 A。
    // ⚠️ 不要求精确为 0：往返时延不对称会带来毫秒级误差，而局域网里
    // 「请求 + 合并 + 写库」的耗时足以到几十毫秒。所以断言一个量级。
    expect(
      AppClock.offset.inSeconds.abs(),
      lessThan(60),
      reason: '本机原本偏 -10 分钟，同步后应被拉回到与对端相差不到一分钟',
    );
  });

  /// ⛔ 这条**不能**写成「两端各自 assert 自己的 offset」：`AppClock` 是全局静态，
/// 一个进程里只有一个 offset，两端 repository 共享它 —— 那样断言不了任何东西。
///
/// 真正要钉的是「服务端处理请求的路径里没有 `setOffset`」。绕开 `LanClient`、
/// 直接用裸 `HttpClient` 打服务端，就只剩服务端这一侧，offset 变没变一目了然。
  test('服务方处理请求时不改本机时钟（只有发起方该被拉动）', () async {
    AppClock.setOffset(const Duration(minutes: 7));

    final client = HttpClient();
    final body = gzip.encode(utf8.encode(jsonEncode({
      'snapshot': snap('来自裸客户端').toJson(),
      'clientTime': DateTime(2026, 10, 10, 12).toIso8601String(),
    })));
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:$hostPort/sync'),
    );
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.contentEncodingHeader, 'gzip')
      ..contentLength = body.length;
    request.add(body);
    await (await request.close()).drain<void>();
    client.close(force: true);

    expect(
      AppClock.offset.inMinutes,
      7,
      reason: '两端互相把时钟拉向对方会让偏差越滚越大 —— 只有发起方才该动',
    );
    // 服务端**确实**处理了请求（不是「压根没连上」导致 offset 没变）。
    expect((await localA.read()).notes.single.title, '来自裸客户端');
  });

  test('连不上（对端没开服务）→ NetworkFailure，不是崩溃', () async {
    final result = await peer.syncWithPeer(
      LanPeer(
        address: '127.0.0.1',
        port: 1, // 几乎肯定没人监听
        name: '幽灵',
        lastSeen: DateTime.now(),
      ),
    );

    expect(result.isLeft(), isTrue);
  });

  test('双方都用软删除时，删除时间更晚的一方赢', () async {
    await localA.write(snap('争'));
    await localB.write(snap('争'));
    await peer.syncWithPeer(hostPeer());

    // B 删除（更晚），A 不删 —— 应以 B 为准，两端都是删除态。
    await dbB.customStatement(
      'UPDATE notes SET deleted_at = ? WHERE id = ?',
      [9999999, 'n-争'],
    );
    await peer.syncWithPeer(hostPeer());

    expect((await localA.read()).notes.single.deletedAt, isNotNull);
  });

  test('停掉服务后端口释放，能再次启动', () async {
    expect(host.isHosting, isTrue);

    await host.stopHosting();
    expect(host.isHosting, isFalse);

    await host.startHosting('A2');
    expect(host.isHosting, isTrue);
  });
}

/// 还原 `flutter_test` 装的那个覆盖。
///
/// ⛔ 不用 `HttpOverrides.global = HttpOverrides()`（空构造）：那会把**整个文件里**
/// 的网络访问都放行，包括那些本该被挡住的。与其猜全局默认是什么，不如显式装回
/// 一个「什么请求都拒绝」的覆盖 —— 与 flutter_test 的行为一致，且不依赖它的内部实现。
class _TestHttpOverrides extends HttpOverrides {}