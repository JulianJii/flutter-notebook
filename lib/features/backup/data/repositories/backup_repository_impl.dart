import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/storage/local_storage_service.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/data/datasources/webdav_data_source.dart';
import 'package:mynote/features/backup/domain/entities/backup_import_result.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';
import 'package:mynote/features/backup/domain/entities/backup_version_entry.dart';
import 'package:mynote/features/backup/domain/entities/webdav_config.dart';
import 'package:mynote/features/backup/domain/repositories/backup_repository.dart';

/// 配置在 `SharedPreferences` 里的 key。单 key JSON（与 `app_settings` 同套路）。
const String webDavConfigStorageKey = 'webdav_config';

/// 快照 JSON 的长度上限（**UTF-16 码元**，不是字节）。
///
/// ⛔ 不是「随便挑的数」：`jsonDecode` 会把整份文本读进内存并展开成 Dart 对象图。
/// 用码元而非字节是刻意的 —— Dart 内部字符串就是 UTF-16，它比字节更贴近真实
/// 内存占用（一段中文笔记的码元数只有 UTF-8 字节数的 1/3，按字节卡会在
/// 中文内容上白白拒掉三分之二的额度）。十万条量级才逼近这个数，所以它远高于
/// 任何真实导出，作用只是拦住「误选了一个几百 MB 的视频 / 数据库」—— 那是 OOM，
/// 不是导入失败。
///
/// 守在这里（一处）而不是文件选择器：文件导入、WebDAV 远端 `GET`、局域网同步
/// 三条路径都从这里过，远端文件此前**完全**没有上限。
const int kMaxSnapshotChars = 64 * 1024 * 1024;

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
      final uploadJson = jsonEncode(merged.merged.toJson());

      // 先落本地再上传：上传失败只是「这次没同步出去」，本地数据已经安全，
      // 下一次同步会重试（合并是幂等的）。
      final writeSkipped = await _local.write(merged.merged);

      // 归档**覆盖前**的远端内容，且只在「内容真的变了」时归档 —— 否则每次
      // 空同步都往 NAS 里堆一份一模一样的快照，20 条配额几天就耗光。
      //
      // ⚠️ 归档失败**不**让同步失败：历史是辅助功能，同步才是主功能。
      if (remoteJson != null &&
          _contentHash(remote.snapshot) != _contentHash(merged.merged)) {
        await _archive(config, remoteJson, remote.snapshot);
      }

      await _webDav.upload(config, uploadJson);
      await _writeConfig(config.copyWith(lastSyncAt: DateTime.now()));

      return BackupImportResult(
        inserted: merged.result.inserted,
        updated: merged.result.updated,
        skipped: remote.skipped + writeSkipped,
      );
    });
  }

  @override
  Future<Either<Failure, List<BackupVersionEntry>>> listHistory() {
    return _guard(() async {
      final config = _requireConfig();
      return await _webDav.fetchHistoryIndex(config) ??
          const <BackupVersionEntry>[];
    });
  }

  /// 把一个历史版本**合并**进本地。
  ///
  /// ⚠️ **语义是「找回内容」，不是「回到当时的状态」**：走的是与文件导入完全
  /// 相同的合并路径。因为删除传播已经生效（软删除留墓碑），**当时被删掉的笔记 /
  /// 待办 / 文件册不会回来** —— 只有「当时存在、现在也该存在」的那部分会被补回。
  /// 墓碑比任何历史版本都新，这是有意的：要真回滚就得把墓碑也回退，那会真丢数据。
  ///
  /// 版本文件丢失（索引与文件不一致）→ `ValidationFailure`，不静默当「没变化」。
  @override
  Future<Either<Failure, BackupImportResult>> restoreVersion(
    BackupVersionEntry entry,
  ) {
    return _guard(() async {
      final config = _requireConfig();
      final json = await _webDav.fetchVersion(config, entry.file);
      if (json == null) {
        throw FormatException('history file is missing: ${entry.file}');
      }
      return _merge(json);
    });
  }

  /// 归档一份快照 + 维护索引 + 轮转。
  ///
  /// 顺序刻意是「先传文件、后写索引」：索引是**指针**，文件是**数据**。反过来
  /// （先写索引后传文件）会让索引短暂指向不存在的文件，用户点开就是报错。
  /// 代价是「文件传成功、索引写失败」→ 多一份孤儿文件（用户无感、占点空间），
  /// 比「索引指向空气」好。
  Future<void> _archive(
    WebDavConfig config,
    String json,
    BackupSnapshot snapshot,
  ) async {
    final now = DateTime.now();
    final entry = BackupVersionEntry(
      file: historyFileName(now),
      at: snapshot.exportedAt,
      hash: _contentHash(snapshot),
      count: snapshot.count,
    );

    await _webDav.uploadVersion(config, entry.file, json);

    final existing =
        await _webDav.fetchHistoryIndex(config) ?? const <BackupVersionEntry>[];
    final merged = <BackupVersionEntry>[entry, ...existing];

    // 轮转：超出的删文件、移出索引。先删后写索引 —— 反过来的话索引里就有一条
    // 指向已被删的文件的记录。
    if (merged.length > kHistoryLimit) {
      final stale = merged.sublist(kHistoryLimit);
      for (final old in stale) {
        await _webDav.deleteVersion(config, old.file);
      }
    }

    await _webDav.putHistoryIndex(
      config,
      merged.length > kHistoryLimit ? merged.sublist(0, kHistoryLimit) : merged,
    );
  }

  /// 快照**内容**的 sha256 —— 判「这次同步有没有真的改动数据」用。
///
/// ⚛️ **必须排除 `exportedAt`**：`BackupSnapshot.merge` 每次都把它写成
/// `DateTime.now()`，所以哪怕一个字的数据都没动，重序列化出来的 JSON 也**字节
/// 不同**。直接对整份 JSON 取哈希的话，每次空同步都会被判成「变了」，历史配额
/// 会被无意义地消耗光 —— 而这恰恰是这个功能最该避免的事。
///
/// 只哈希三张表的行序列化结果，`Map` 的键序由字面量固定，所以同一份内容永远得到
/// 同一个指纹。
String _contentHash(BackupSnapshot snapshot) => sha256
    .convert(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'notes': snapshot.notes.map((n) => n.toJson()).toList(growable: false),
          'folders': snapshot.folders.map((f) => f.toJson()).toList(growable: false),
          'todos': snapshot.todos.map((t) => t.toJson()).toList(growable: false),
        }),
      ),
    )
    .toString();

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

  /// 解码。坏 JSON / 超大 / 版本高于当前支持 → 抛 [FormatException]（由 [_guard]
  /// 映射成 `ValidationFailure`）。
  ///
  /// ⚠️ **不静默降级解析**：读不懂的未来格式会造出一堆缺字段的半残数据，那比
  /// 「导入不了」难收拾得多。版本低（老格式）照读 —— 只有加字段、没有改语义。
  ({BackupSnapshot snapshot, int skipped}) _decode(String raw) {
    if (raw.length > kMaxSnapshotChars) {
      throw FormatException('snapshot too large: ${raw.length} chars');
    }

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

  /// 同 [_readConfig]，但未配置时抛（历史功能不能对着一个空地址发请求）。
  WebDavConfig _requireConfig() {
    final config = _readConfig();
    if (!config.isConfigured) {
      throw const FormatException('WebDAV is not configured');
    }
    return config;
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
