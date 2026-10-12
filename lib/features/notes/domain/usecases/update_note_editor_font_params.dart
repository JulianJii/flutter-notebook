import 'package:equatable/equatable.dart';

/// `UpdateNoteEditorFontUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class UpdateNoteEditorFontParams extends Equatable {
  const UpdateNoteEditorFontParams({
    required this.noteId,
    required this.fontId,
  });

  final String noteId;

  /// `core/fonts` 目录里的字体 id。null = 换回系统默认字体。
  /// **必填无默认**：有默认值就分不清「显式换回默认」与「没传」。
  final String? fontId;

  @override
  List<Object?> get props => [noteId, fontId];
}
