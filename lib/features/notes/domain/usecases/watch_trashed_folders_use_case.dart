import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';

/// 订阅回收站里的文件夹（`deleted_at IS NOT NULL`），按删除时间倒序。
///
/// 与 `WatchDeletedNotesUseCase` 同约定：返回 `Stream` 而非 `Either`，流错误由
/// UI 侧的 `AsyncValue.error` 表达。
class WatchTrashedFoldersUseCase {
  const WatchTrashedFoldersUseCase(this._repository);

  final FolderRepository _repository;

  Stream<List<NoteFolder>> call() => _repository.watchTrashed();
}