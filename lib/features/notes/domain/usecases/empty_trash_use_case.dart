import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';

/// 清空「最近删除」：物理删除全部已软删的笔记（不可恢复）。
/// 二次确认是 UI 层的事，UseCase 不管。
class EmptyTrashUseCase {
  const EmptyTrashUseCase(this._repository);

  final NoteRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.purgeAll();
}
