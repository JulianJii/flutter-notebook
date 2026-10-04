import 'package:equatable/equatable.dart';

/// 一个用户自建的笔记文件夹（D4 的一行）。
///
/// ⚠️ **「全部」与「未分类」不是 [NoteFolder] 的实例**（`ARCHITECTURE-DESIGN.md`
/// §5.3）：D4 实测 `全部 155 = 词声笔记 1 + 未分类 154`，「未分类」是
/// `folder_id IS NULL` 的系统视图，不占表行。故本实体**没有** `isSystem` flag。
///
/// ⛔ **实体层不做重名校验**：[name] 的唯一性是 DB 的 UNIQUE 约束，靠
/// `InsertionConflict` 冒上来再由 repository 映射成 `Left(InputFailure)`。
/// 在实体里加 `assert` 就是第二套真相源。
/// ⛔ **不加 `parentId`**：MVP 单层文件夹（§3.2）。
/// ⛔ **不加 `color` / `icon` / `isExpanded`**（D4 无对应视觉）。
class NoteFolder extends Equatable {
  const NoteFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;

  NoteFolder copyWith({String? name, DateTime? updatedAt}) {
    return NoteFolder(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt];
}
