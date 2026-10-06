import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:init/features/backup/domain/entities/webdav_config.dart';

/// WebDAV 客户端。只做三件事：`GET` 取快照、`PUT` 传快照、`PROPFIND` 探活。
///
/// 用 dio 手搓而不是引一个 webdav 包：同步的是**单个 JSON 文件**，需要的动词
/// 就这三个，`Options(method: ...)` 已经够，多一个依赖多一份版本兼容风险。
///
/// ⛔ 不加 `LogInterceptor`：Basic Auth 头里是用户名密码的 base64（等同明文），
/// 拦截器会把 URL 与请求头全量打到控制台。
/// ⛔ 不 import Flutter。
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
    if (response.statusCode == 404) return null;
    return response.data;
  }

  /// 上传快照。目录不存在时先 MKCOL（建不建得成让随后的 PUT 说话）。
  Future<void> upload(WebDavConfig config, String json) async {
    await _ensureDirectory(config);
    await _dio.putUri<String>(
      _fileUri(config),
      data: json,
      options: Options(
        headers: <String, Object?>{
          ..._headers(config),
          Headers.contentTypeHeader: 'application/json',
        },
      ),
    );
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
      // 同上：网络层错误让 PUT 再报一次。
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
    final directory = _directoryUri(config);
    return directory.replace(
      path: '${directory.path}${config.remoteFile.trim()}',
    );
  }
}
