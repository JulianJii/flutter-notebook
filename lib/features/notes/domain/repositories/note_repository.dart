import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';

/// 笔记的领域抽象。实现在 data 层。
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

  /// 改置顶 / 收藏。`null` = 不动这一列。
  ///
  /// 实现内部**不刷新 `updatedAt`**，理由同 [updateBackground]：它们是视图状态
  /// 而非内容，一次「点收藏」不该让笔记的编辑日期跳到今天。
  Future<Either<Failure, Unit>> updateFlags(
    String noteId, {
    bool? isPinned,
    bool? isFavorite,
  });

  /// 删除（**软删除**）：把笔记移进「最近删除」，不物理删除。
  /// 实现内部写 `deleted_at = now()`，不刷新 `updatedAt`。
  Future<Either<Failure, Unit>> delete(String noteId);

  /// 批量删除（**软删除**，与 [delete] 同语义）。返回实际命中的行数。
  Future<Either<Failure, int>> deleteMany(List<String> noteIds);

  /// 批量移动到文件夹（null = 未分类）。实现内部刷 `updatedAt`
  /// （归属变更必须跨设备传播）。返回实际命中的行数。
  Future<Either<Failure, int>> moveToFolderMany(
    List<String> noteIds,
    String? folderId,
  );

  /// 批量改置顶 / 收藏（`null` = 不动这一列），列语义与 [updateFlags]
  /// 完全一致（含不刷 `updatedAt` 的既有裁决）。返回实际命中的行数。
  Future<Either<Failure, int>> updateFlagsMany(
    List<String> noteIds, {
    bool? isPinned,
    bool? isFavorite,
  });

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
