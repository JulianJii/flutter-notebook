import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mynote/features/backup/domain/entities/lan_peer.dart';

/// 局域网同步服务端：起一个 `HttpServer`，只认 `POST /sync` 一个路由。
///
/// 协议刻意做到最简 —— 请求带自己的全量快照，服务端合并后回**同一份**合并结果。
/// 两端写同一个值 → **一次往返即收敛**，不需要第二阶段、不需要确认帧。
///
/// ⚛️ **明文 HTTP，无任何认证**：同网段的任何设备都能读写你的全部笔记。
/// 这是知情选择（局域网内可信），不是疏漏。见 `docs/FEATURES.md`「已知限制」。
///
/// ⛔ 不 import Flutter。
/// ⛔ 只处理 `POST /sync`：其他路径返回 404。这是本机临时起的服务，不该对外
/// 暴露目录列表之类的任何东西。
class LanServer {
  LanServer(this._handleSync);

  /// 收到请求 → 返回合并后的报文。由 Repository 注入（它才有本地库）。
  final Future<LanSyncResponse> Function(LanSyncRequest) _handleSync;

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _sub;

  /// 实际绑定的端口。**随机端口**（bind 传 0）—— 固定端口会在两台设备跑在同一台
  /// 机器上、或与别的服务撞车时起不来。端口由信标广播出去，所以随机没问题。
  int? get port => _server?.port;

  bool get isRunning => _server != null;

  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    _sub = server.listen(
      _handle,
      // 单个请求处理失败不该拖垮服务（比如对端中途断开）。
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != 'POST' || request.uri.path != '/sync') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final body = await _readBody(request);
      if (body == null) {
        request.response.statusCode = HttpStatus.requestEntityTooLarge;
        await request.response.close();
        return;
      }

      final parsed = _parseRequest(body);
      if (parsed == null) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final response = await _handleSync(parsed);
      await _writeGzip(request.response, jsonEncode(response.toJson()));
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }

  /// 读请求体。超过上限立刻掐断 → 返回 `null`（调用方回 413）。
  ///
  /// ⚠️ 必须**流式**读并边读边计数：`request` 整个读进内存的话，一个几百 MB 的
  /// 包就能把 App 的内存吃穿（与 `kMaxSnapshotChars` 同一个道理）。
  ///
  /// ⚠️ **必须自己解压**：`dart:io` 的 `HttpClient` 会自动解**响应**的 gzip，但
  /// `HttpServer` 收到的 `HttpRequest` 是**原始压缩字节**。漏这一步的表现是
  /// `utf8.decode` 抛错 → 请求被判为 400 → 客户端只看到「同步失败」，毫无线索。
  Future<String?> _readBody(HttpRequest request) async {
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      // 上界是**压缩后**的字节数 —— 拿它当闸门正好：压缩后还超 32MB 的请求，
      // 展开后只会更大。
      if (bytes.length > _kMaxRequestBytes) return null;
    }

    List<int> raw = bytes;
    final encoding = request.headers.value(HttpHeaders.contentEncodingHeader);
    if (encoding != null && encoding.toLowerCase().contains('gzip')) {
      try {
        raw = gzip.decode(bytes);
      } on FormatException {
        return null;
      }
    }

    try {
      return utf8.decode(raw);
    } on FormatException {
      return null;
    }
  }

  /// 解析请求体。**不是本 App 的报文 → `null`**（调用方回 500，对端会看到同步失败）。
  ///
  /// ⛔ 不回详细的解析错误：服务端是本机临时起的，但错误信息会经 HTTP 回给对端，
  /// 不值得为它建一套错误映射。
  static LanSyncRequest? _parseRequest(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;

    final snapshot = decoded['snapshot'];
    final clientTime = decoded['clientTime'];
    if (snapshot is! Map || clientTime is! String) return null;

    final parsedTime = DateTime.tryParse(clientTime);
    if (parsedTime == null) return null;

    return LanSyncRequest(
      snapshot: snapshot.cast<String, Object?>(),
      clientTime: parsedTime,
    );
  }

  Future<void> _writeGzip(HttpResponse response, String body) async {
    final compressed = gzip.encode(utf8.encode(body));
    response.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      // 声明 gzip 后，`HttpClient` 默认的 `autoUncompress` 会自动解开 ——
      // 对端不需要知道我们压缩了。
      ..set(HttpHeaders.contentEncodingHeader, 'gzip')
      ..contentLength = compressed.length;
    response.add(compressed);
  }
}

/// 请求体上限（**压缩后**字节）。≈ 32 MB。
///
/// 与 `BackupRepositoryImpl.kMaxSnapshotChars` 同一量级 —— 那是纯 JSON 的上限，
/// 这个是 gzip 后的，通常更小；偏小只会让「极大的库」在局域网同步时需要分片，
/// 而那是以后的事。
const int _kMaxRequestBytes = 32 * 1024 * 1024;