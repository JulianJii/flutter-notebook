import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/backup/domain/entities/backup_version_entry.dart';
import 'package:mynote/features/backup/domain/repositories/backup_repository.dart';

/// 历史版本列表（新 → 旧）。二次确认 / 文案是 UI 层的事。
class ListBackupHistoryUseCase {
  const ListBackupHistoryUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, List<BackupVersionEntry>>> call() {
    return _repository.listHistory();
  }
}