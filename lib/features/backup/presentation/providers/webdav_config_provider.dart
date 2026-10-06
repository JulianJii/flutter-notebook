import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/core/logging/logger_provider.dart';
import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/backup/domain/entities/webdav_config.dart';
import 'package:init/features/backup/providers/backup_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'webdav_config_provider.g.dart';

/// WebDAV 配置的读写入口。
///
/// 与 `settingsProvider` 同形态：`build()` 同步给默认值，microtask 里读盘。
/// `keepAlive: true` —— 数据与同步页、配置页、启动同步三处都要读它。
@Riverpod(keepAlive: true)
class WebDavConfigNotifier extends _$WebDavConfigNotifier {
  @override
  WebDavConfig build() {
    Future<void>.microtask(_load);
    return const WebDavConfig();
  }

  Future<void> _load() async {
    final result = await ref.read(getWebDavConfigUseCaseProvider)(NoParams());
    result.fold(
      (failure) => _log('config load failed: ${failure.message}'),
      (config) => state = config,
    );
  }

  /// 全量保存（表单页「保存」按钮）。
  Future<Either<Failure, Unit>> save(WebDavConfig config) async {
    final result = await ref.read(saveWebDavConfigUseCaseProvider)(config);
    return result.fold(
      (failure) {
        _log('config save failed: ${failure.message}');
        return Left(failure);
      },
      (_) {
        state = config;
        return const Right(unit);
      },
    );
  }

  /// 「启动时自动同步」开关。
  Future<Either<Failure, Unit>> setAutoSyncOnStart(bool value) =>
      save(state.copyWith(autoSyncOnStart: value));

  /// 用**未保存**的配置探一次服务器。
  Future<Either<Failure, Unit>> test(WebDavConfig config) =>
      ref.read(testWebDavUseCaseProvider)(config);

  void _log(String message) =>
      ref.read(taggedLoggerProvider('backup')).i(message);
}
