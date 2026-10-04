import 'package:equatable/equatable.dart';

/// `CreateFolderUseCase` 的参数。可构造 + 有 `==`，供测试的
/// `registerFallbackValue` 使用。
class CreateFolderParams extends Equatable {
  const CreateFolderParams({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}
