import 'package:mynote/core/logging/logger_provider.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/backup/domain/entities/webdav_config.dart';
import 'package:mynote/features/backup/providers/backup_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_sync_provider.g.dart';

/// App 启动时的一次自动同步。
///
/// 由 `main.dart` 里 `ref.watch(startupSyncProvider)` 挂载 —— `AsyncNotifier` 的
/// [build] 只在首次监听时跑一次，正好是「启动一次」的语义。
///
/// ⛔ **不做后台定时同步**：`workmanager` 要接平台配置与任务注册，而本 App 的
/// 数据是本地的，同步只是「顺手带一把」，不值得为它引入一条后台链路。
/// ⛔ **不弹任何提示**：启动时用户可能在任何页面，一次失败的自动同步不该打断他；
/// 结果只进日志，要看结果去设置页点「立即同步」。
@Riverpod(keepAlive: true)
class StartupSync extends _$StartupSync {
  @override
  Future<void> build() async {
    await _sweepExpiredTombstones();
    final result = await ref.read(getWebDavConfigUseCaseProvider)(NoParams());
    final config = result.fold((_) => const WebDavConfig(), (c) => c);
    if (!config.autoSyncOnStart || !config.isConfigured) return;

    final synced = await ref.read(syncWithWebDavUseCaseProvider)(NoParams());
    ref.read(taggedLoggerProvider('backup')).i(
      synced.fold(
        (failure) => 'startup sync failed: ${failure.message}',
        (result) => 'startup sync: +${result.inserted} ~${result.updated}',
      ),
    );
  }

  /// 清扫过期的永久删除墓碑（`TombstoneSweeper`）。
  ///
  /// ⛔ **无条件跑，不看有没有配同步**：这是本地磁盘维护，与 WebDAV 无关 ——
  /// 没配同步的用户照样会积累墓碑行。
  /// ⛔ **best-effort**：失败只记日志。清扫是「释放磁盘」的优化，失败一次
  /// 不该让启动同步整个放弃。硬删永远发生在保留期之后，漏一次没有正确性风险。
  Future<void> _sweepExpiredTombstones() async {
    try {
      final removed = await ref.read(tombstoneSweeperProvider).sweep();
      if (removed > 0) {
        ref.read(taggedLoggerProvider('backup')).i(
          'purged $removed expired tombstones',
        );
      }
    } catch (e) {
      ref.read(taggedLoggerProvider('backup')).w('tombstone sweep failed: $e');
    }
  }
}
