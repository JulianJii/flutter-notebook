import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';

import '../entities/backup_import_result.dart';
import '../repositories/backup_repository.dart';

/// 与 WebDAV 双向同步一次。未配置服务器时由 Repository 返回 `Left`。
class SyncWithWebDavUseCase {
  const SyncWithWebDavUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, BackupImportResult>> call(NoParams params) {
    return _repository.sync();
  }
}
