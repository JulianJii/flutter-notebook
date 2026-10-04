import 'package:equatable/equatable.dart';

/// `RenameFolderUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class RenameFolderParams extends Equatable {
  const RenameFolderParams({required this.folderId, required this.name});

  final String folderId;

  final String name;

  @override
  List<Object?> get props => [folderId, name];
}
