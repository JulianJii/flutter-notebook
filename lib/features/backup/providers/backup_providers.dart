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
