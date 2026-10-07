import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';

import '../entities/webdav_config.dart';
import '../repositories/backup_repository.dart';

/// 保存 WebDAV 配置（含「启动时自动同步」与上次同步时间）。全量写。
class SaveWebDavConfigUseCase {
  const SaveWebDavConfigUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, Unit>> call(WebDavConfig config) {
    return _repository.saveConfig(config);
  }
}
