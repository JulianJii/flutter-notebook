import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/backup/domain/entities/backup_import_result.dart';
import 'package:mynote/features/backup/domain/entities/backup_version_entry.dart';
import 'package:mynote/features/backup/domain/repositories/backup_repository.dart';

/// 把某个历史版本**合并**进本地（找回内容，不是回滚状态）。
///
/// ⛔ 二次确认在 UI 层：这里只表达「落库意图」。用户必须先被告知「当时删掉的
/// 东西不会回来」再点确认 —— 那句话不是技术细节，是这个功能的**语义边界**。
class RestoreBackupVersionUseCase {
  const RestoreBackupVersionUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, BackupImportResult>> call(
    BackupVersionEntry entry,
  ) {
    return _repository.restoreVersion(entry);
  }
}