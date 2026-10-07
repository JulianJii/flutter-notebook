import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/storage/local_storage_service.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/data/datasources/webdav_data_source.dart';
import 'package:mynote/features/backup/domain/entities/backup_import_result.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';
import 'package:mynote/features/backup/domain/entities/webdav_config.dart';
import 'package:mynote/features/backup/domain/repositories/backup_repository.dart';

/// 配置在 `SharedPreferences` 里的 key。单 key JSON（与 `app_settings` 同套路）。
const String webDavConfigStorageKey = 'webdav_config';

/// 快照 JSON 的解析 / 序列化 + 三个数据源的编排。
///
/// ⛔ 不 import Flutter、不碰 `BuildContext`。
/// ⛔ 不新增 Failure 类型：`CacheFailure`（本地读写）、`ValidationFailure`
/// （文件不是本应用的快照 / 版本太新 / 服务器没配）、`NetworkFailure` /
/// `TimeoutFailure` / `AuthFailure` / `ServerFailure`（WebDAV）。
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._local, this._webDav, this._storage);

  final BackupLocalDataSource _local;

  final WebDavDataSource _webDav;

  final LocalStorageService _storage;

  @override
  Future<Either<Failure, ({String json, int count})>> exportSnapshotJson() {
    return _guard(() async {
      final snapshot = await _local.read();
      return (json: jsonEncode(snapshot.toJson()), count: snapshot.count);
    });
  }

  @override
  Future<Either<Failure, BackupImportResult>> importSnapshotJson(String json) {
    return _guard(() => _merge(json));
  }

  @override
  Future<Either<Failure, BackupImportResult>> sync() {
    return _guard(() async {
      final config = _readConfig();
      if (!config.isConfigured) {
        throw const FormatException('WebDAV is not configured');
      }

      final local = await _local.read();
      final remoteJson = await _webDav.fetch(config);
      // 远端还没有文件 = 空快照，等价于首次推送。
      final remote = remoteJson == null
          ? (snapshot: BackupSnapshot.empty(), skipped: 0)
          : _decode(remoteJson);

      final merged = BackupSnapshot.merge(local, remote.snapshot);

      // 先落本地再上传：上传失败只是「这次没同步出去」，本地数据已经安全，
      // 下一次同步会重试（合并是幂等的）。
      final writeSkipped = await _local.write(merged.merged);
      await _webDav.upload(config, jsonEncode(merged.merged.toJson()));
      await _writeConfig(config.copyWith(lastSyncAt: DateTime.now()));

      return BackupImportResult(
        inserted: merged.result.inserted,
        updated: merged.result.updated,
        skipped: remote.skipped + writeSkipped,
      );
    });
  }

  @override
  Future<Either<Failure, Unit>> testConnection(WebDavConfig config) {
    return _guard(() async {
      if (!config.isConfigured) {
        throw const FormatException('WebDAV is not configured');
      }
      await _webDav.ping(config);
      return unit;
    });
  }

  @override
  Future<Either<Failure, WebDavConfig>> loadConfig() {
    return _guard(() async => _readConfig());
  }

  @override
  Future<Either<Failure, Unit>> saveConfig(WebDavConfig config) {
    return _guard(() => _writeConfig(config));
  }

  /// 解码一份快照 JSON → 合并 → 写库。导入与同步共用。
  Future<BackupImportResult> _merge(String json) async {
    final decoded = _decode(json);
    final local = await _local.read();
    final merged = BackupSnapshot.merge(local, decoded.snapshot);
    final writeSkipped = await _local.write(merged.merged);
    return BackupImportResult(
      inserted: merged.result.inserted,
      updated: merged.result.updated,
      skipped: decoded.skipped + writeSkipped,
    );
  }

  /// 解码。坏 JSON / 版本高于当前支持 → 抛 [FormatException]（由 [_guard] 映射
  /// 成 `ValidationFailure`）。
  ///
  /// ⚠️ **不静默降级解析**：读不懂的未来格式会造出一堆缺字段的半残数据，那比
  /// 「导入不了」难收拾得多。版本低（老格式）照读 —— 只有加字段、没有改语义。
  ({BackupSnapshot snapshot, int skipped}) _decode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('not a snapshot file');
    }

    if (decoded is! Map) {
      throw const FormatException('not a snapshot file');
    }
    final version = decoded['version'];
    if (version is int && version > backupSnapshotVersion) {
      throw FormatException('snapshot version $version is too new');
    }
    return BackupSnapshot.parse(decoded);
  }

  /// 同步读配置。不返回 `Either`：读失败直接抛，交给 [_guard]。
  WebDavConfig _readConfig() {
    final raw = _storage.getObject(webDavConfigStorageKey);
    if (raw is! Map) return const WebDavConfig();
    return _configFromJson(raw.cast<String, Object?>());
  }

  Future<Unit> _writeConfig(WebDavConfig config) async {
    await _storage.setObject(webDavConfigStorageKey, _configToJson(config));
    return unit;
  }

  /// 异常 → Failure 的统一出口。
  ///
  /// ⚠️ [FormatException] 在这里同时承担「文件不是快照」「服务器没配」两种语义，
  /// 都是「用户给的输入不对」→ `ValidationFailure`。不为此新增一个 Exception 类型。
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on DioException catch (e) {
      return Left(_mapDio(e));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on FormatException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  Failure _mapDio(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return AuthFailure(message: 'WebDAV: ${e.message}', statusCode: code);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => TimeoutFailure(
        message: 'WebDAV: ${e.message}',
        statusCode: code,
      ),
      DioExceptionType.badResponse => ServerFailure(
        message: 'WebDAV: ${e.message}',
        statusCode: code,
      ),
      _ => NetworkFailure(message: 'WebDAV: ${e.message}', statusCode: code),
    };
  }
}

Map<String, Object?> _configToJson(WebDavConfig c) => <String, Object?>{
  'url': c.url,
  'username': c.username,
  'password': c.password,
  'remoteFile': c.remoteFile,
  'autoSyncOnStart': c.autoSyncOnStart,
  'lastSyncAt': c.lastSyncAt?.toIso8601String(),
};

/// 逐字段回落：单个字段类型错只让该字段回默认，其余照读。
WebDavConfig _configFromJson(Map<String, Object?> json) {
  const defaults = WebDavConfig();
  return WebDavConfig(
    url: switch (json['url']) {
      final String v => v,
      _ => defaults.url,
    },
    username: switch (json['username']) {
      final String v => v,
      _ => defaults.username,
    },
    password: switch (json['password']) {
      final String v => v,
      _ => defaults.password,
    },
    remoteFile: switch (json['remoteFile']) {
      final String v when v.trim().isNotEmpty => v,
      _ => WebDavConfig.kDefaultRemoteFile,
    },
    autoSyncOnStart: switch (json['autoSyncOnStart']) {
      final bool v => v,
      _ => defaults.autoSyncOnStart,
    },
    lastSyncAt: switch (json['lastSyncAt']) {
      final String v => DateTime.tryParse(v),
      _ => null,
    },
  );
}
