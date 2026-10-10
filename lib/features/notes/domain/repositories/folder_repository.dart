import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';

/// 文件夹的领域抽象。实现在 data 层（`TASK-022`）。
abstract class FolderRepository {
  /// 订阅文件夹 + 每个文件夹的笔记数（一条 GROUP BY，不 N+1）。
  ///
  /// 「全部」与「未分类」**不作为** `NoteFolder` 出现在这个流里（§5.3）。
  ///
  /// 流错误：Repository 实现负责把 `CacheException` 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<FolderWithCount>> watchWithCounts();

  /// 「未分类」笔记数（`folder_id IS NULL`）。文件夹管理稿的「未分类 154」就是它。
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
  /// **软删除**（进回收站）：改名让出原名 + 写 `deleted_at` + 笔记落未分类，
  /// 三步同事务（实现内部要 `transaction()` —— 读当前 `name` 才能算出让出版，
  /// 拆开就有竞态）。
  ///
  /// ⚠️ 软删除下外键 `ON DELETE SET NULL` **不触发**（行还在库里），所以笔记落
  /// 未分类必须显式做，不能指望外键。
  Future<Either<Failure, Unit>> delete(String folderId);

  /// 从回收站恢复：改名回原名 + `deleted_at` 置 null + 刷 `updatedAt`。
  /// 原名已被占用 → `Left(InputFailure)`（保留让出版，不悄悄改名）。
  Future<Either<Failure, Unit>> restore(String folderId);

  /// 回收站里的文件夹，按删除时间倒序。
  Stream<List<NoteFolder>> watchTrashed();

  /// 回收站的「永久删除」：**物理**删行。只由回收站 UI 发起。
  Future<Either<Failure, Unit>> purge(String folderId);

  /// 清空回收站：**物理**删掉全部 `deleted_at IS NOT NULL` 的文件夹。
  ///
  /// ⛔ 单条 SQL 而不是在 UI 里循环 [purge]：循环中途失败会留下删一半的
  /// 不可解释状态。命中 0 行**不抛**（没有可清的项就是已清空）。
  Future<Either<Failure, Unit>> purgeAllTrashed();

  /// 按 [orderedFolderIds] 的顺序重排（文件夹管理拖拽）。传入的是**完整顺序**，
  /// 不是增量交换；`watchWithCounts` 会在写完后推出新顺序。
  Future<Either<Failure, Unit>> reorder(List<String> orderedFolderIds);
}
