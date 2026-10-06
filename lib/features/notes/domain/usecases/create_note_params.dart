import 'package:equatable/equatable.dart';
import 'package:init/features/notes/domain/entities/note_background.dart';

/// `CreateNoteUseCase` 的参数。多参数才建 params 类（`Get` / `Delete` 单参数
/// 直接收 `String`）。可构造 + 有 `==`，供测试的 `registerFallbackValue` 使用。
class CreateNoteParams extends Equatable {
  const CreateNoteParams({
    required this.title,
    required this.content,
    this.folderId,
    this.background,
  });

  final String title;

  final String content;

  /// null = 存进「未分类」。
  final String? folderId;

  /// 新建时已选中的背景（`/notes/new` 上先选背景、后写内容）。
  /// null = 无背景。
  final NoteBackground? background;

  @override
  List<Object?> get props => [title, content, folderId, background];
}
