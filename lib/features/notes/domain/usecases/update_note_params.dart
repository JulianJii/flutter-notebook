import 'package:equatable/equatable.dart';

/// `UpdateNoteUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class UpdateNoteParams extends Equatable {
  const UpdateNoteParams({
    required this.noteId,
    required this.title,
    required this.content,
    this.folderId,
    this.clearFolderId = false,
  });

  final String noteId;

  final String title;

  final String content;

  /// 目标文件夹。
  final String? folderId;

  /// 「把笔记移回未分类」的显式开关。
  ///
  /// ⚠️ 为什么不用 `folderId ?? <原值>` 的写法：那样「显式置 null」与
  /// 「没传 folderId」变成同一件事，移回未分类永远做不到。沿用
  /// `TaskEntity.copyWith(clearDueDate:)` 的既有写法。
  final bool clearFolderId;

  /// 真正要写进实体的 folderId。
  String? get targetFolderId => clearFolderId ? null : folderId;

  @override
  List<Object?> get props => [noteId, title, content, folderId, clearFolderId];
}
