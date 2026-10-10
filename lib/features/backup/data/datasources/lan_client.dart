import 'dart:convert';
import 'dart:io';

import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';
import 'package:mynote/features/backup/domain/entities/lan_peer.dart';

/// 局域网同步客户端：一次 `POST /sync`，带回合并结果**和一次对时**。
///
/// 对时是**顺带**的，不额外往返 —— NTP 式三采样里缺的 t0（发出时刻）和 t2（收到
/// 时刻）都在本机，另一次往返才能拿到的那次本来就没有意义（那会测到的是「第二次
/// 往返」的延迟，而不是这次同步的链路）。
///
/// ⛔ 不 import Flutter。
class LanClient {
  LanClient({HttpClient? httpClient}) : _http = httpClient ?? HttpClient();

  final HttpClient _http;

  /// 连不上 / 超时 / 报文不合法 → 抛 [LanTransportException]，由 Repository 映射成
  /// `NetworkFailure` / `TimeoutFailure` / `ValidationFailure`。
  Future<LanSyncOutcome> syncWith(LanPeer peer, BackupSnapshot local) async {
    // t0：发出请求前取的时刻。⛔ 必须在**建请求之前**取 —— 建连本身有开销，
    // 算进去会让偏差偏大。
    final t0 = DateTime.now();

    final body = jsonEncode(
      LanSyncRequest(snapshot: local.toJson(), clientTime: t0).toJson(),
    );
    final compressed = gzip.encode(utf8.encode(body));

    final response = await _post(peer, compressed);
    final raw = await _readBody(response);
    final decoded = _parseResponse(raw);
    final parsed = BackupSnapshot.parse(decoded.snapshot);

    // t2：收到响应之后立刻取。与 t0 一起构成往返时延的上下界。
    final t2 = DateTime.now();

    return LanSyncOutcome(
      snapshot: parsed.snapshot,
      skipped: parsed.skipped,
      offset: _estimateOffset(t0, decoded.serverTime, t2),
    );
  }

  /// NTP 式偏差估计：`((t1 - t0) + (t1 - t2)) / 2`。
  ///
  /// 推导：真实单程时延 d 单向时，t1 - t0 = (对端偏移 + d)，t1 - t2 = (对端偏移 - d)；
  /// 两式相加消去 d，再除 2 即得「本机相对对端的时钟偏差」。
  ///
  /// ⚠️ 假设**往返时延对称**。局域网内成立；WiFi 省电或对端负载高时会偏一点 ——
  /// 所以这个值是「尽力而为」，且只在每次同步时刷新一次。
  static Duration _estimateOffset(DateTime t0, DateTime t1, DateTime t2) {
    return ((t1.difference(t0) + t1.difference(t2)) ~/ 2);
  }

  Future<HttpClientResponse> _post(LanPeer peer, List<int> body) async {
    final client = _http
      ..connectionTimeout = _kConnectTimeout
      // 快照可能有几 MB，收得慢；连不上才该快速失败。
      ..idleTimeout = _kIdleTimeout;

    final request = await client.postUrl(Uri.parse(_endpoint(peer)));
    request.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set(HttpHeaders.contentEncodingHeader, 'gzip')
      ..contentLength = body.length;
    request.add(body);

    return request.close();
  }

  /// 把对端地址拼成完整 URL。
  ///
  /// ⚠️ 端口为 0 = 还没绑定（手输 IP 但对端没开服务），这拼出来的 URL 连不上，
  /// 由 [_post] 的连接超时给出失败 —— 不在这里提前判，因为「端口 0」也可能是
  /// 数据来源填错，而真去连一次能拿到更具体的错误。
  static String _endpoint(LanPeer peer) => 'http://${peer.address}:${peer.port}/sync';

  Future<String> _readBody(HttpClientResponse response) async {
    if (response.statusCode != HttpStatus.ok) {
      throw LanTransportException(
        'lan sync failed with status ${response.statusCode}',
      );
    }
    return response.transform(utf8.decoder).join();
  }

  static LanSyncResponse _parseResponse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FormatException('malformed LAN sync response');
    }
    if (decoded is! Map) {
      throw const FormatException('malformed LAN sync response');
    }

    final snapshot = decoded['snapshot'];
    final serverTime = decoded['serverTime'];
    if (snapshot is! Map || serverTime is! String) {
      throw const FormatException('malformed LAN sync response');
    }
    final parsedTime = DateTime.tryParse(serverTime);
    if (parsedTime == null) {
      throw const FormatException('malformed LAN sync response');
    }

    return LanSyncResponse(
      snapshot: snapshot.cast<String, Object?>(),
      serverTime: parsedTime,
    );
  }

  void close() => _http.close(force: true);
}

/// 一次局域网同步的结果：合并后的快照 + 算出的时钟偏差。
class LanSyncOutcome {
  const LanSyncOutcome({
    required this.snapshot,
    required this.skipped,
    required this.offset,
  });

  final BackupSnapshot snapshot;

  /// 对端快照里的坏行数（透传给 UI 报「跳过 N 条」）。
  final int skipped;

  /// 本机相对对端的时钟偏差，交给 `AppClock`。
  final Duration offset;
}

/// 传输层失败。⛔ 不是 `CacheException`（那是本地库的意思）——
/// Repository 单独 catch 它，映射成网络类 Failure。
class LanTransportException implements Exception {
  const LanTransportException(this.message);

  final String message;

  @override
  String toString() => 'LanTransportException: $message';
}

const Duration _kConnectTimeout = Duration(seconds: 8);

const Duration _kIdleTimeout = Duration(seconds: 30);