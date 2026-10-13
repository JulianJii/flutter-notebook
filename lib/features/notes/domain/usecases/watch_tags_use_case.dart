import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/notes/domain/entities/tag.dart';
import 'package:mynote/features/notes/domain/repositories/tag_repository.dart';

/// 订阅全部标签 + 各自的存活笔记数。排序在 DAO（name ASC），
/// ⛔ 不返回 Either（流有成败用 `AsyncValue` 表达），约定同
/// [WatchFolderCountsUseCase]。
class WatchTagsUseCase {
  const WatchTagsUseCase(this._repository);

  final TagRepository _repository;

  Stream<List<Tag>> call(NoParams params) => _repository.watchAll();
}
