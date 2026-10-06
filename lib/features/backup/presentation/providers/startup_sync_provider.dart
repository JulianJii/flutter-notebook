import 'package:init/core/logging/logger_provider.dart';
import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/backup/domain/entities/webdav_config.dart';
import 'package:init/features/backup/providers/backup_providers.dart';
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
}
