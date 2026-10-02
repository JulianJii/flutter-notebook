import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/auth/domain/entities/user_entity.dart';
import 'package:init/features/auth/providers/auth_providers.dart';

// Auth 状态
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// Auth 通知器
// Auth 通知器
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  // 检查认证状态
  Future<void> checkAuthStatus() async {
    // 这里通常会检查是否存有有效的 token，
    // 如有必要，可再向 API 校验该 token

    // 目前我们直接返回 false
    state = state.copyWith(isAuthenticated: false, user: null);
  }

  // 登录
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase.execute(email: email, password: password);

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        errorMessage: null,
      ),
    );
  }

  // 注册
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final registerUseCase = ref.read(registerUseCaseProvider);
    final result = await registerUseCase.execute(
      name: name,
      email: email,
      password: password,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        errorMessage: null,
      ),
    );
  }

  // 退出登录
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final logoutUseCase = ref.read(logoutUseCaseProvider);
    final result = await logoutUseCase.execute();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        user: null,
        errorMessage: null,
      ),
    );
  }

  // 更新用户资料
  Future<bool> updateProfile(UserEntity user) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final updateProfileUseCase = ref.read(updateProfileUseCaseProvider);
    final result = await updateProfileUseCase.execute(user);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (updatedUser) {
        state = state.copyWith(
          isLoading: false,
          user: updatedUser,
          errorMessage: null,
        );
        return true;
      },
    );
  }
}

// Auth provider 定义
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
