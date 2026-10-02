import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:init/features/auth/domain/usecases/login_use_case.dart';
import 'package:init/features/auth/domain/usecases/logout_use_case.dart';
import 'package:init/features/auth/domain/usecases/register_use_case.dart';
import 'package:init/features/auth/domain/usecases/update_profile_use_case.dart';

/// 数据层依赖注入 providers
/// 这些 providers 负责创建和管理数据层实例

// 注意：authRepositoryProvider 定义在 auth_repository_impl.dart 中

// --- 用例 ---
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(authRepositoryProvider));
});
