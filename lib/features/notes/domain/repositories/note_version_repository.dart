import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note_version.dart';

/// 单篇版本历史的领域抽象。实现在 data 层。
abstract class NoteVersionRepository {
  /// 存一版（去重：与最近一版相同则跳过；按 [limit] 淘汰最旧）。
  /// 失败静默成 `Left` —— 存版是「锦上添花」的附属写入，⛔ 不打断编辑保存。
  Future<Either<Failure, Unit>> saveVersion(NoteVersion version, int limit);

  /// 订阅一篇笔记的版本（新→旧）。流错误约定同 `NoteRepository.watch`。
  Stream<List<NoteVersion>> watchVersions(String noteId);

  /// 读单条。
  Future<Either<Failure, NoteVersion>> getById(String versionId);
}
