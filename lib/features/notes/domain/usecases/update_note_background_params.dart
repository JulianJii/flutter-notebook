import 'package:equatable/equatable.dart';
import 'package:init/features/notes/domain/entities/note_background.dart';

/// `UpdateNoteBackgroundUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class UpdateNoteBackgroundParams extends Equatable {
  const UpdateNoteBackgroundParams({
    required this.noteId,
    required this.background,
  });

  final String noteId;

  /// null = 清除背景。**必填无默认**：有默认值就分不清「显式清除」与「没传」。
  final NoteBackground? background;

  @override
  List<Object?> get props => [noteId, background];
}
