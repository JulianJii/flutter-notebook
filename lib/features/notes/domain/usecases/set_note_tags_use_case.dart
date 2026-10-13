import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/tag_repository.dart';

/// 把一篇笔记的标签对齐到 [names]（替换式全集）。名字 trim / 去空由
/// 数据层兜底；「输入即建」的幂等建标签也在这条链路里（`createOrGet`）。
class SetNoteTagsUseCase {
  const SetNoteTagsUseCase(this._repository);

  final TagRepository _repository;

  Future<Either<Failure, Unit>> call(String noteId, List<String> names) {
    if (noteId.isEmpty) {
      return Future.value(
        const Left(InputFailure(message: 'noteId must not be empty')),
      );
    }
    return _repository.setNoteTags(noteId, names);
  }
}
