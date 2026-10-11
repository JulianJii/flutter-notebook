import 'package:fpdart/fpdart.dart';

import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';

import '../repositories/backup_repository.dart';

/// 导出全库为**一份 Markdown 文档**。
///
/// ⛔ 与 `ExportBackupUseCase` 是两回事：那个出的是**备份**（JSON，含图片与删除
/// 墓碑，能原样还原），这个出的是**阅读件**（纯文本，用户拿去发 / 存 / 喂给别的
/// 工具）。字节从哪来、存到哪，由 presentation 处理（`shareMarkdown`）。
class ExportMarkdownUseCase {
  const ExportMarkdownUseCase(this._repository);

  final BackupRepository _repository;

  Future<Either<Failure, ({String markdown, int count})>> call(NoParams params) {
    return _repository.exportMarkdown();
  }
}