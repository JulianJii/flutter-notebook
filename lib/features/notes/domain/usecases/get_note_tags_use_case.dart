import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/repositories/tag_repository.dart';

/// 读一篇笔记当前的标签名（一次性，打标弹层回填用；开弹层后的变化走
/// `WatchNoteTagsUseCase`）。
class GetNoteTagsUseCase {
  const GetNoteTagsUseCase(this._repository);

  final TagRepository _repository;

  Future<Either<Failure, List<String>>> call(String noteId) =>
      _repository.namesForNote(noteId);
}
