import 'package:equatable/equatable.dart';

/// `UpdateNoteFlagsUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
///
/// ⚠️ 两个字段都是**可空**的：`null` = 「不动这一列」。调用方改收藏时不该把
/// 置顶一起抹掉，所以「没传」必须能与「传 false」区分开 —— 这与
/// `UpdateNoteBackgroundParams` 的 null 语义不同（那里 null 是一个真实取值）。
class UpdateNoteFlagsParams extends Equatable {
  const UpdateNoteFlagsParams({
    required this.noteId,
    this.isPinned,
    this.isFavorite,
  });

  final String noteId;

  /// null = 不动置顶列。
  final bool? isPinned;

  /// null = 不动收藏列。
  final bool? isFavorite;

  @override
  List<Object?> get props => [noteId, isPinned, isFavorite];
}