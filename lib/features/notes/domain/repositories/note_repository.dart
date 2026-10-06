import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_background.dart';
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

  /// 只改纸张背景（null = 无背景）。实现内部**不刷新 `updatedAt`** ——
  /// 换背景只改外观，不算一次编辑。
  Future<Either<Failure, Unit>> updateBackground(
    String noteId,
    NoteBackground? background,
  );

  /// 删除（**软删除**）：把笔记移进「最近删除」，不物理删除。
  /// 实现内部写 `deleted_at = now()`，不刷新 `updatedAt`。
  Future<Either<Failure, Unit>> delete(String noteId);

  /// 订阅「最近删除」列表，按删除时间倒序。流错误以
  /// `Stream.error(CacheException)` 传播（与 [watch] 同约定）。
  Stream<List<Note>> watchDeleted();

  /// 从「最近删除」恢复（`deleted_at` 置回 null）。
  Future<Either<Failure, Unit>> restore(String noteId);

  /// 永久删除（物理 DELETE，不可恢复）。
  Future<Either<Failure, Unit>> purge(String noteId);

  /// 清空「最近删除」（物理删除全部已软删的行）。
  Future<Either<Failure, Unit>> purgeAll();
}
