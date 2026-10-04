import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';

/// 笔记的领域抽象。实现在 data 层（`TASK-022`）。
abstract class NoteRepository {
  /// 按查询条件订阅笔记列表。[NoteQuery.folder] 为 `AllFolders` 时表示不过滤。
  ///
  /// 流错误：Repository 实现负责把 `CacheException` 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<Note>> watch(NoteQuery query);

  /// 读单条。找不到时返回 `Left(CacheFailure(message: 'Note not found: $id'))`。
  Future<Either<Failure, Note>> getById(String noteId);

  /// 新建。[Note.id] 为空时由实现内部生成 uuid v4。
  Future<Either<Failure, Note>> create(Note note);

  /// 更新。实现内部刷新 `updatedAt`。
  Future<Either<Failure, Note>> update(Note note);

  /// 删除。
  ///
  /// ⚠️ 语义取决于 CONFLICT-10 裁决（软删 vs 硬删），两种实现的签名完全相同，
  /// 只是内部不同。当前裁决为**硬删除、无 `deleted_at`**，迁移清单见
  /// `specs/tasks/TASK-015-drift-tables.md` 的 Context 与
  /// `specs/docs/PROJECT-STATUS.md` §6。
  Future<Either<Failure, Unit>> delete(String noteId);
}
