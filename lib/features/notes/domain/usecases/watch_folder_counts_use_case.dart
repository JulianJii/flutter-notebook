import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';

/// 订阅文件夹 + 每个文件夹的笔记数（P4 的数据源）。
///
/// ⛔ **不做二次排序**：`ORDER BY sort_index ASC, created_at ASC` 已在 `FolderDao`
/// 的 SQL 里排完（前者是 P4 拖拽出来的顺序）。
/// ⛔ 不返回 `Either`（流有成败用 `AsyncValue` 表达）。
/// ⛔ 不继承 `UseCase` 基类，只复用它的 [NoParams]。
class WatchFolderCountsUseCase {
  const WatchFolderCountsUseCase(this._repository);

  final FolderRepository _repository;

  Stream<List<FolderWithCount>> call(NoParams params) {
    return _repository.watchWithCounts();
  }
}
