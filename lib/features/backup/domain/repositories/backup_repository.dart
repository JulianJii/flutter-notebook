import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';

import '../entities/backup_import_result.dart';
import '../entities/backup_version_entry.dart';
import '../entities/webdav_config.dart';

/// 数据搬运的出入口。三个能力（导出 / 导入 / 同步）共用一份快照模型，
/// 差别只在字节从哪来、到哪去。
abstract class BackupRepository {
  /// 读本地全量 → 快照 JSON 字符串 + 记录条数（页面要报「导出了多少条」）。
  Future<Either<Failure, ({String json, int count})>> exportSnapshotJson();

  /// 把一份快照 JSON 合并进本地库。
  Future<Either<Failure, BackupImportResult>> importSnapshotJson(String json);

  /// 与 WebDAV 双向同步：拉远端 → 合并 → 推远端 → 写本地。
  ///
  /// 远端没有文件（404）视为「空快照」，等价于首次推送。
  Future<Either<Failure, BackupImportResult>> sync();

  /// 历史版本列表，**新 → 旧**。没归档过 → 空列表（不是错误）。
  ///
  /// 归档时机由 [sync] 决定：只在「这次同步真的改动了远端内容」时，归档**覆盖
  /// 前**的那一份。所以历史里的每一条都是「一次真实改动之前的最后状态」。
  Future<Either<Failure, List<BackupVersionEntry>>> listHistory();

  /// 把某个历史版本**合并**进本地。
  ///
  /// ⛔ **不是「回到当时的状态」**：删除传播（软删除墓碑）比任何历史版本都新，
  /// 当时被删掉的内容**不会回来**。用户看到的是「找回内容」。
  Future<Either<Failure, BackupImportResult>> restoreVersion(
    BackupVersionEntry entry,
  );

  /// 用**未保存**的配置探一次服务器。配置页「测试连接」用。
  Future<Either<Failure, Unit>> testConnection(WebDavConfig config);

  Future<Either<Failure, WebDavConfig>> loadConfig();

  Future<Either<Failure, Unit>> saveConfig(WebDavConfig config);
}
