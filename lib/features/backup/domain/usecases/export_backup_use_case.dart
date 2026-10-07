import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';

import '../repositories/backup_repository.dart';

/// 导出：本地全量 → 快照 JSON 字符串。
///
/// 零逻辑薄封装：字节怎么落到用户手上（写临时文件 + 系统分享）是 presentation
/// 层的事，本层只产出字符串。
class ExportBackupUseCase {
  const ExportBackupUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, ({String json, int count})>> call(NoParams params) {
    return _repository.exportSnapshotJson();
  }
}
