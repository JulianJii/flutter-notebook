import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mynote/core/utils/app_clock.dart';
import 'package:mynote/features/backup/domain/entities/backup_version_entry.dart';
import 'package:mynote/features/backup/domain/entities/webdav_config.dart';

/// WebDAV 客户端。快照本身三件事：`GET` 取、`PUT` 传、`PROPFIND` 探活；
/// 历史版本再加四个：列索引、读版本、写版本、删版本。
///
/// 用 dio 手搓而不是引一个 webdav 包：同步的是**单个 JSON 文件**，需要的动词
/// 就这几个，`Options(method: ...)` 已经够，多一个依赖多一份版本兼容风险。
///
/// ⛔ 不加 `LogInterceptor`：Basic Auth 头里是用户名密码的 base64（等同明文），
/// 拦截器会把 URL 与请求头全量打到控制台。
/// ⛔ 不 import Flutter。
///
/// ## 历史版本为什么用「索引文件」而不是 PROPFIND 列目录
///
/// 列目录得发 `PROPFIND Depth: 1` 并解析 `207 Multi-Status` 的 XML，而响应格式在
/// nginx / Apache / Nextcloud / Synology 上各不相同，要引一个 XML parser 去容忍那些
/// 差异（`xml` 目前只是传递依赖，提成直接依赖才有得 import）。
/// 索引文件**完全复用已经跑通的 GET / PUT**，零新依赖、零服务器差异。
///
/// ponytail: 代价是索引与版本文件可能不一致（版本上传成功但索引 PUT 失败），
/// 不做对账修复 —— 后果最多丢一条历史记录，不会损坏任何数据，而自愈要写
/// 「逐个探测文件是否存在」的对账扫描。真出现「历史里有点数但打不开」再说。
class WebDavDataSource {
  WebDavDataSource(this._dio);

  final Dio _dio;

  /// 取远端快照。**文件不存在（404）返回 `null`** —— 那是「还没同步过」，
  /// 不是错误。
  Future<String?> fetch(WebDavConfig config) async {
    final response = await _dio.getUri<String>(
      _fileUri(config),
      options: Options(
        responseType: ResponseType.plain,
        headers: _headers(config),
        // 默认 validateStatus 会把 404 变成 DioException，这里放行让调用方拿到 null。
        validateStatus: (status) => status != null && (status < 400 || status == 404),
      ),
    );
    // 借这次往返顺手对时（只在主快照 GET 上做，历史读不重复校准）。
    _absorbClockSkew(response);
    if (response.statusCode == 404) return null;
    return _maybeGunzip(response.data);
  }

  /// 上传快照。目录不存在时先 MKCOL（建不建得成让随后的 PUT 说话）。
  Future<void> upload(WebDavConfig config, String json) async {
    await _ensureDirectory(config);
    await _putJson(config, _fileUri(config), json);
  }

  /// 探活：对目录发一次 `PROPFIND Depth: 0`。地址错 / 密码错都会在这里现形。
  Future<void> ping(WebDavConfig config) async {
    await _dio.requestUri<String>(
      _directoryUri(config),
      options: Options(
        method: 'PROPFIND',
        headers: <String, Object?>{..._headers(config), 'Depth': '0'},
      ),
    );
  }

  // ---- 历史版本 ----

  /// 读历史索引，返回**新 → 旧**排序（最新在前）。
  ///
  /// 索引 / 目录不存在（404）返回 `null` = 从没归档过。
  ///
  /// ⚠️ `config` 必须传进来 —— Basic Auth 头在这里生成，漏了就变成匿名请求，
  /// 任何需要密码的 WebDAV 上直接 401。
  Future<List<BackupVersionEntry>?> fetchHistoryIndex(WebDavConfig config) async {
    final body = await _getPlain(config, _historyIndexUri(config));
    if (body == null) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      // 索引损坏 → 当作「没有历史」。它是本 App 自己写的派生数据，坏掉不该
      // 挡住用户同步（那才是主功能）。
      return null;
    }
    if (decoded is! List) return null;

    final entries = <BackupVersionEntry>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final entry = BackupVersionEntry.fromJson(item.cast<String, Object?>());
      // 坏行静默跳过：索引也是外部输入，一条脏数据不该炸掉整个历史列表。
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries;
  }

  /// 写历史索引（整表覆盖）。超出配额的文件由调用方先删。
  Future<void> putHistoryIndex(
    WebDavConfig config,
    List<BackupVersionEntry> entries,
  ) async {
    await _ensureHistoryDir(config);
    await _putJson(
      config,
      _historyIndexUri(config),
      jsonEncode(entries.map((e) => e.toJson()).toList(growable: false)),
    );
  }

  /// 归档一份快照到 `history/`。
  Future<void> uploadVersion(
    WebDavConfig config,
    String file,
    String json,
  ) async {
    await _ensureHistoryDir(config);
    await _putJson(config, _historyUri(config, file), json);
  }

  /// 读一份历史快照。**文件不存在返回 `null`** —— 索引与文件不一致时不该炸。
  Future<String?> fetchVersion(WebDavConfig config, String file) async {
    return _getPlain(config, _historyUri(config, file));
  }

  /// 删一份历史快照（轮转时清理超出的旧版本）。
  ///
  /// ⚠️ 吞掉异常：清理是尽力而为，某个文件删不掉不该让整次同步失败 ——
  /// 那会让用户以为「同步坏了」，而实际只是历史多留了两条。
  Future<void> deleteVersion(WebDavConfig config, String file) async {
    try {
      await _dio.deleteUri<String>(
        _historyUri(config, file),
        options: Options(headers: _headers(config)),
      );
    } on DioException {
      // 同上。
    }
  }

  // ---- 传输原语 ----

  /// `GET` 一段文本。404 → `null`（调用方据此判断「没有」）；其余状态照常抛，
  /// 由 Repository 映射成 Failure。
  ///
  /// ⚠️ 不在这里对时：只有主快照的 GET（[fetch]）代表一次真实的同步往返，
  /// 历史版本读取没有「对端时钟」语义，只是把一份本地文件取回来。
  Future<String?> _getPlain(WebDavConfig config, Uri uri) async {
    final response = await _dio.getUri<String>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        headers: _headers(config),
        validateStatus: (status) => status != null && (status < 400 || status == 404),
      ),
    );
    if (response.statusCode == 404) return null;
    return _maybeGunzip(response.data);
  }

  Future<void> _putJson(WebDavConfig config, Uri uri, String json) {
    return _dio.putUri<String>(
      uri,
      data: _gzip(json),
      options: Options(
        responseType: ResponseType.bytes,
        headers: <String, Object?>{
          ..._headers(config),
          Headers.contentTypeHeader: 'application/json',
          // ⚠️ 声明了就得能兜住解码：见 [_maybeGunzip] —— 我们**不**信任服务器会
          // 按 Content-Encoding 解压再存盘，而是靠魔数自己判（见该方法注释）。
          Headers.contentEncodingHeader: 'gzip',
        },
      ),
    );
  }

  /// gzip 编码。正文是 JSON 且内嵌 base64 图片，压缩比可观（全量同步每次都要
  /// 传一遍，这是最便宜的一次提速）。
  ///
  /// ⛔ **不做增量 / 变更日志表**：那是改 schema + 三条 DAO 全过一遍的工程，
  /// 而 gzip 零 schema 改动就能把单次传输量降一个量级。真嫌慢再上变更日志。
  static List<int> _gzip(String json) =>
      ZLibCodec(level: 6).encode(utf8.encode(json));

  /// 按**魔数**判断是否 gzip，是则解压。
  ///
  /// ⚠️ 刻意**不看** `Content-Encoding` 响应头：WebDAV 服务器对它的处理差异很大
  /// —— 有的按头解压后原样存盘（那我们拿到的是明文）、有的原样存下压缩字节却
  /// 丢了头（那我们拿到的是 gzip 字节但头说自己是明文）。两种都会在「信头」的
  /// 实现里炸掉。魔数是**内容自身**的事实，不依赖任何服务器的配合。
  static String _maybeGunzip(String? body) {
    if (body == null) return '';
    // 1f 8b = gzip 魔数。字符串长度 < 2 时不可能是压缩流。
    if (body.length < 2 ||
        body.codeUnitAt(0) != 0x1f ||
        body.codeUnitAt(1) != 0x8b) {
      return body;
    }
    // 到这里说明服务器（或 dio）把 gzip 字节塞进了 String。UTF-8 解码对非法
    // 序列是替换而非报错，所以 latin1 能无损地把每个码元还原成一个字节。
    final bytes = latin1.encode(body);
    return utf8.decode(ZLibCodec().decode(bytes));
  }

  /// 借响应的 `Date` 头刷新 [AppClock] 的时钟偏差。
  ///
  /// 合并键是各设备自己的墙上时钟，偏差会**静默**覆盖数据。局域网同步一直在
  /// 握手时对时，但 WebDAV 路径上此前**从不**对时 —— 于是「设备 A 用 WebDAV
  /// 同步」的用户是完全没有时钟校正的。HTTP 响应头是免费的时钟源，用它。
  ///
  /// ⚠️ 精度只有「半个往返」：`Date` 头在服务器**发出响应**时生成，我们在**收完**
  /// 时才读，所以差值里含着下行时延（同步一次几百毫秒）。这远好于「不校」，
  /// 且**不需要**额外的 NTP 往返 —— 对一个只需消除分钟级漂移的场景是划算的。
  ///
  /// ⛔ **超出 [kMaxClockSkew] 一律丢弃**：这个值会静默改写此后**所有**落库
  /// 时间戳。一个配错的服务器（时区错、时钟停在 1970）不该把整库的时间键
  /// 拖到垃圾值上，那比不校正糟糕得多。
  static const Duration kMaxClockSkew = Duration(days: 1);

  void _absorbClockSkew(Response<Object?> response) {
    final raw = response.headers.value('date');
    if (raw == null) return;
    final serverNow = HttpDate.parse(raw);
    final skew = serverNow.difference(DateTime.now());
    if (skew.abs() > kMaxClockSkew) return;
    AppClock.setOffset(skew);
  }

  Future<void> _ensureDirectory(WebDavConfig config) async {
    try {
      await _dio.requestUri<String>(
        _directoryUri(config),
        options: Options(
          method: 'MKCOL',
          headers: _headers(config),
          // 目录已存在时服务器普遍回 405，父目录不存在回 409：都不算这里的错，
          // 吞掉后由 PUT 给出真实原因（连不上 / 密码错 / 无写权限）。
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      // 网络层错误让 PUT 再报一次。
    }
  }

  /// 历史目录不存在时建出来。`history/` 是快照目录的**子**目录，父目录由
  /// [upload] 的 `_ensureDirectory` 建，这里只补自己这一层。
  Future<void> _ensureHistoryDir(WebDavConfig config) async {
    try {
      await _dio.requestUri<String>(
        _historyDirUri(config),
        options: Options(
          method: 'MKCOL',
          headers: _headers(config),
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      // 同上。
    }
  }

  /// Basic Auth。用户名与密码都为空时不发 `Authorization`（匿名 WebDAV）。
  Map<String, Object?> _headers(WebDavConfig config) {
    if (config.username.isEmpty && config.password.isEmpty) {
      return const <String, Object?>{};
    }
    final raw = '${config.username}:${config.password}';
    return <String, Object?>{
      'Authorization': 'Basic ${base64Encode(utf8.encode(raw))}',
    };
  }

  /// 目录地址：末尾补 `/`，`Uri.replace` 保留 scheme / host / userInfo。
  Uri _directoryUri(WebDavConfig config) {
    final base = Uri.parse(config.url.trim());
    return base.replace(
      path: base.path.endsWith('/') ? base.path : '${base.path}/',
    );
  }

  Uri _fileUri(WebDavConfig config) {
    // 空文件名兜底：与 `_configFromJson` 的回落保持一致。否则 `GET` 会打到目录
    // 本身，拿到 WebDAV 目录列表（207 / XML），报出一句误导的「不是快照文件」。
    final name = config.remoteFile.trim().isEmpty
        ? WebDavConfig.kDefaultRemoteFile
        : config.remoteFile.trim();
    return _directoryUri(config).replace(path: '${_directoryUri(config).path}$name');
  }

  Uri _historyDirUri(WebDavConfig config) => _join(config, '$kHistoryDir/');

  Uri _historyIndexUri(WebDavConfig config) => _historyUri(config, kHistoryIndexFile);

  Uri _historyUri(WebDavConfig config, String file) =>
      _join(config, '$kHistoryDir/$file');

  /// 在 WebDAV 根目录下拼一个相对路径。`history/` 与快照文件同级（**不是**放在
  /// `remoteFile` 的子目录里）—— 用户改 `remoteFile` 时历史不该跟着搬家。
  Uri _join(WebDavConfig config, String relative) {
    final directory = _directoryUri(config);
    return directory.replace(path: '${directory.path}$relative');
  }
}