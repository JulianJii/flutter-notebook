import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';

/// 文件夹的领域抽象。实现在 data 层（`TASK-022`）。
abstract class FolderRepository {
  /// 订阅文件夹 + 每个文件夹的笔记数（一条 GROUP BY，不 N+1）。
  ///
  /// 「全部」与「未分类」**不作为** `NoteFolder` 出现在这个流里（§5.3）。
  ///
  /// 流错误：Repository 实现负责把 `CacheException` 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<FolderWithCount>> watchWithCounts();

  /// 「未分类」笔记数（`folder_id IS NULL`）。D4 的「未分类 154」就是它。
  ///
  /// ⛔ 单独一条 `COUNT(*)` 而不是「取列表再 `.length`」：后者会把全部未分类
  /// 笔记的正文（Quill Delta JSON）读进内存只为拿一个整数。
  Stream<int> watchUncategorizedCount();

  /// [NoteFolder.name] 有 UNIQUE 约束，冲突 → `Left(InputFailure)`。
  Future<Either<Failure, NoteFolder>> create(NoteFolder folder);

  /// 重命名。`name` 冲突 → `Left(InputFailure)`。
  Future<Either<Failure, NoteFolder>> rename(String folderId, String name);

  /// 删除文件夹，其下笔记的 `folderId` 落 null（「未分类」）。
  ///
  /// 依赖 `notes.folder_id` 的 `ON DELETE SET NULL` 外键 + `PRAGMA foreign_keys`
  /// 同时生效，故实现内部必须走事务（仓库里唯一需要显式 `transaction()` 的方法）。
  Future<Either<Failure, Unit>> delete(String folderId);
}
