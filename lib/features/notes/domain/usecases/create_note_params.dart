import 'package:equatable/equatable.dart';

/// `CreateNoteUseCase` 的参数。多参数才建 params 类（`Get` / `Delete` 单参数
/// 直接收 `String`）。可构造 + 有 `==`，供测试的 `registerFallbackValue` 使用。
class CreateNoteParams extends Equatable {
  const CreateNoteParams({
    required this.title,
    required this.content,
    this.folderId,
  });

  final String title;

  final String content;

  /// null = 存进「未分类」。
  final String? folderId;

  @override
  List<Object?> get props => [title, content, folderId];
}
