import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note_version.dart';
import 'package:mynote/features/notes/domain/repositories/note_version_repository.dart';

/// 存一版（去重 + 按上限淘汰在数据层的事务里做）。
///
/// ⛔ **不打断编辑保存**：编辑链路在落库成功后顺手调它，存版失败只记日志、
/// 不影响正文已保存的事实（`Right`/`Left` 都照常返回，调用方自行取舍）。
/// [limit] 是设置里的版本上限（`AppSettings.noteVersionLimit`）。
class SaveNoteVersionUseCase {
  const SaveNoteVersionUseCase(this._repository);

  final NoteVersionRepository _repository;

  Future<Either<Failure, Unit>> call(NoteVersion version, int limit) {
    return _repository.saveVersion(version, limit);
  }
}
