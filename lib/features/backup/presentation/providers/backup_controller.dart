import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/logging/logger_provider.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/backup/domain/entities/backup_import_result.dart';
import 'package:mynote/features/backup/domain/entities/backup_version_entry.dart';
import 'package:mynote/features/backup/presentation/providers/webdav_config_provider.dart';
import 'package:mynote/features/backup/providers/backup_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'backup_file_service.dart';

part 'backup_controller.g.dart';

/// 正在进行的操作。null = 空闲（页面据此转圈并禁用入口）。
enum BackupOperation { export, import, sync }

/// 数据管理页的三个动作。
///
/// state 只表达「哪个操作在跑」，结果通过返回值交给页面 —— 成功/失败文案需要
/// l10n，Notifier 里不该产生面向用户的字符串。
@riverpod
class BackupController extends _$BackupController {
  @override
  BackupOperation? build() => null;

  /// 导出 → 系统分享面板。返回导出的记录条数。
  Future<Either<Failure, int>> export() async {
    return _run(BackupOperation.export, () async {
      final exported = await ref.read(exportBackupUseCaseProvider)(NoParams());
      return exported.fold(
        (failure) => Future<Either<Failure, int>>.value(Left(failure)),
        (snapshot) async {
          try {
            await shareSnapshotJson(
              snapshot.json,
              snapshotFileName(DateTime.now()),
            );
            return Right(snapshot.count);
          } catch (e) {
            // 分享面板是平台通道，失败原因（没装可用的分享目标等）不可枚举。
            return Left(CacheFailure(message: e.toString()));
          }
        },
      );
    });
  }

  /// 导入 → 文件选择器 → 合并。
  ///
  /// 用户在选择器里取消时返回 `Right(null)`：那是「什么都没发生」，不是失败，
  /// 不该弹错误提示。
  Future<Either<Failure, BackupImportResult?>> import() async {
    return _run(BackupOperation.import, () async {
      final json = await pickSnapshotJson();
      if (json == null) return const Right(null);
      return ref.read(importBackupUseCaseProvider)(json);
    });
  }

  /// 与 WebDAV 同步一次。
  Future<Either<Failure, BackupImportResult>> sync() async {
    return _run(BackupOperation.sync, () async {
      final result = await ref.read(syncWithWebDavUseCaseProvider)(NoParams());
      // 同步成功会写 lastSyncAt，配置页要跟着变。
      if (result.isRight()) ref.invalidate(webDavConfigProvider);
      return result;
    });
  }

  /// 读历史版本列表（新 → 旧）。
  ///
  /// ⛔ **不包在 [_run] 里**：它不写库、也没有「转圈禁用入口」的必要（历史屏自己
  /// 有加载态）。套 `_run` 只会让数据与同步页在后台读历史时无故转圈。
  Future<Either<Failure, List<BackupVersionEntry>>> loadHistory() {
    return ref.read(listBackupHistoryUseCaseProvider)();
  }

  /// 把某个历史版本合并进本地。
  ///
  /// 成功后**失效历史列表**：恢复的是本地库，历史本身没变，但用户通常接着想
  /// 再看一次「现在什么状态」—— 让屏自己重取，比在这里猜更准。
  Future<Either<Failure, BackupImportResult>> restoreVersion(
    BackupVersionEntry entry,
  ) async {
    final result = await ref.read(restoreBackupVersionUseCaseProvider)(entry);
    if (result.isRight()) ref.invalidate(webDavConfigProvider);
    return result;
  }

  Future<Either<Failure, T>> _run<T>(
    BackupOperation operation,
    Future<Either<Failure, T>> Function() body,
  ) async {
    state = operation;
    try {
      final result = await body();
      result.fold(
        (failure) => _log('${operation.name} failed: ${failure.message}'),
        (_) => _log('${operation.name} done'),
      );
      return result;
    } finally {
      state = null;
    }
  }

  void _log(String message) => ref.read(taggedLoggerProvider('backup')).i(message);
}
