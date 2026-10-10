import 'package:equatable/equatable.dart';

/// 一个用户自建的笔记文件夹（文件夹管理稿的一行）。
///
/// ⚠️ **「全部」与「未分类」不是 [NoteFolder] 的实例**（`ARCHITECTURE-DESIGN.md`
/// §5.3）：文件夹管理稿实测 `全部 155 = 词声笔记 1 + 未分类 154`，「未分类」是
/// `folder_id IS NULL` 的系统视图，不占表行。故本实体**没有** `isSystem` flag。
///
/// ⛔ **实体层不做重名校验**：[name] 的唯一性是 DB 的 UNIQUE 约束，靠
/// `InsertionConflict` 冒上来再由 repository 映射成 `Left(InputFailure)`。
/// 在实体里加 `assert` 就是第二套真相源。
/// ⛔ **不加 `parentId`**：MVP 单层文件夹（§3.2）。
/// ⛔ **不加 `color` / `icon` / `isExpanded`**（文件夹管理稿无对应视觉）。
class NoteFolder extends Equatable {
  const NoteFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;

  /// **用户看到并编辑的名字**，不含回收站的 `#id` 让出后缀 ——
  /// datasource 在 `deletedAt != null` 时把那一段剥掉（见
  /// `note_folders_table.dart` 的 `visibleFolderName`）。实体这一侧永远是干净的。
  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 软删除时刻。null = 正常文件夹；非 null = 在回收站里。
  ///
  /// ⛔ **不参与 [copyWith]**：回收站相关的写入全部由
  /// `FolderLocalDataSourceImpl` 直连 DAO 完成（要连 `name` 让出一起写，
  /// copyWith 表达不了），没有「先改实体再落库」的路径。
  final DateTime? deletedAt;

  /// 合并比较键 —— 快照合并（`BackupFolder.version`）的语义来源。
  ///
  /// ⚠️ 取 `updatedAt` 与 `deletedAt` 的**较晚者**：软删除也是一次变更，而
  /// 软删除**不刷** `updatedAt`（见 `FolderDao.markTrashed`）。
  DateTime get version => deletedAt == null || deletedAt!.isBefore(updatedAt)
      ? updatedAt
      : deletedAt!;

  NoteFolder copyWith({String? name, DateTime? updatedAt}) {
    return NoteFolder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt, deletedAt];
}
