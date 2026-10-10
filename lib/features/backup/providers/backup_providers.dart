import 'package:dio/dio.dart';
import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/data/datasources/webdav_data_source.dart';
import 'package:mynote/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:mynote/features/backup/domain/repositories/backup_repository.dart';
import 'package:mynote/features/backup/domain/usecases/export_backup_use_case.dart';
import 'package:mynote/features/backup/domain/usecases/get_webdav_config_use_case.dart';
import 'package:mynote/features/backup/domain/usecases/import_backup_use_case.dart';
import 'package:mynote/features/backup/data/datasources/lan_discovery.dart';
import 'package:mynote/features/backup/data/repositories/lan_sync_repository_impl.dart';
import 'package:mynote/features/backup/domain/repositories/lan_sync_repository.dart';
import 'package:mynote/features/backup/domain/usecases/lan_sync_use_cases.dart';

import 'package:mynote/features/backup/domain/usecases/list_backup_history_use_case.dart';
import 'package:mynote/features/backup/domain/usecases/restore_backup_version_use_case.dart';
import 'package:mynote/features/backup/domain/usecases/save_webdav_config_use_case.dart';
import 'package:mynote/features/backup/domain/usecases/sync_with_webdav_use_case.dart';
import 'package:mynote/features/backup/domain/usecases/test_webdav_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_providers.g.dart';

// ⛔ provider 体只做装配，不放逻辑。

/// WebDAV 专用 Dio 实例。
///
/// ⛔ **不复用 `dioProvider`**：那一份 `baseUrl` 是占位 API 域名、带着
/// `LogInterceptor`（会把 Basic Auth 头打进日志）。这里每次请求都传完整 URL，
/// 不需要 baseUrl。
@Riverpod(keepAlive: true)
Dio webDavDio(Ref ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      // 快照可能有几 MB，收得慢；15s 连不上才是真连不上。
      sendTimeout: const Duration(seconds: 60),
    ),
  );
}

@Riverpod(keepAlive: true)
BackupLocalDataSource backupLocalDataSource(Ref ref) {
  return BackupLocalDataSource(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
WebDavDataSource webDavDataSource(Ref ref) {
  return WebDavDataSource(ref.watch(webDavDioProvider));
}

@Riverpod(keepAlive: true)
BackupRepository backupRepository(Ref ref) {
  return BackupRepositoryImpl(
    ref.watch(backupLocalDataSourceProvider),
    ref.watch(webDavDataSourceProvider),
    ref.watch(localStorageServiceProvider),
  );
}

// ---- use case ----
@Riverpod(keepAlive: true)
ExportBackupUseCase exportBackupUseCase(Ref ref) {
  return ExportBackupUseCase(ref.watch(backupRepositoryProvider));
}

@Riverpod(keepAlive: true)
ImportBackupUseCase importBackupUseCase(Ref ref) {
  return ImportBackupUseCase(ref.watch(backupRepositoryProvider));
}

@Riverpod(keepAlive: true)
SyncWithWebDavUseCase syncWithWebDavUseCase(Ref ref) {
  return SyncWithWebDavUseCase(ref.watch(backupRepositoryProvider));
}

// ---- 局域网同步 ----

/// 局域网传输的数据源。⛔ **不是** provider：它持有 `HttpServer` / UDP socket，
/// 生命周期由 [lanSyncUseCases] 统一管，单独暴露会让两份 socket 实例并存。
LanDiscovery lanDiscovery(Ref ref) => LanDiscovery(deviceName: '本机');

@Riverpod(keepAlive: true)
LanSyncRepository lanSyncRepository(Ref ref) {
  return LanSyncRepositoryImpl(
    ref.watch(backupLocalDataSourceProvider),
    lanDiscovery(ref),
  );
}

/// ⛔ **必须 keepAlive**：它间接持有 `HttpServer` 与 UDP socket。被回收就等于
/// 「服务莫名其妙停了」，而且 provider 重建会起一个**新**端口，广播出去的端口与
/// 实际监听的对不上 —— 症状是「开了服务但别人连不上」。
@Riverpod(keepAlive: true)
LanSyncUseCases lanSyncUseCases(Ref ref) {
  return LanSyncUseCases(ref.watch(lanSyncRepositoryProvider));
}

@Riverpod(keepAlive: true)
ListBackupHistoryUseCase listBackupHistoryUseCase(Ref ref) {
  return ListBackupHistoryUseCase(ref.watch(backupRepositoryProvider));
}

@Riverpod(keepAlive: true)
RestoreBackupVersionUseCase restoreBackupVersionUseCase(Ref ref) {
  return RestoreBackupVersionUseCase(ref.watch(backupRepositoryProvider));
}

@Riverpod(keepAlive: true)
TestWebDavUseCase testWebDavUseCase(Ref ref) {
  return TestWebDavUseCase(ref.watch(backupRepositoryProvider));
}

@Riverpod(keepAlive: true)
GetWebDavConfigUseCase getWebDavConfigUseCase(Ref ref) {
  return GetWebDavConfigUseCase(ref.watch(backupRepositoryProvider));
}

@Riverpod(keepAlive: true)
SaveWebDavConfigUseCase saveWebDavConfigUseCase(Ref ref) {
  return SaveWebDavConfigUseCase(ref.watch(backupRepositoryProvider));
}
