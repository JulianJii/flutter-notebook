import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';

import '../entities/backup_import_result.dart';
import '../repositories/backup_repository.dart';

/// 导入：把一份快照 JSON 按 id 合并进本地库。
///
/// 零逻辑薄封装。文件怎么读进来（file_picker）是 presentation 层的事。
class ImportBackupUseCase {
  const ImportBackupUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, BackupImportResult>> call(String json) {
    return _repository.importSnapshotJson(json);
  }
}
