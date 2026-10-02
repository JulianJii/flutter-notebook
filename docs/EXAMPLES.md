# 代码示例

本文档提供实用的代码示例，展示如何使用 Flutter Riverpod Clean Architecture 模板的核心功能。

## 使用扩展方法

> **注意**：以下扩展方法位于 `core/utils/extensions/`，当前为占位文件，待后续实现。

### DateTime 扩展方法

```dart
import 'package:init/core/utils/extensions/datetime_extensions.dart';

void exampleDateTimeExtensions() {
  final now = DateTime.now();
  
  // Format the date
  print(now.formatAs('MMMM d, yyyy')); // June 15, 2025
  
  // Get relative time
  print(now.subtract(Duration(minutes: 5)).timeAgo); // 5 minutes ago
  
  // Add time
  final tomorrow = now.addDays(1);
  
  // Check if date is today/tomorrow/yesterday
  print(now.isToday); // true
  print(tomorrow.isTomorrow); // true
  
  // Start/end of period
  final startOfMonth = now.startOfMonth;
  final endOfDay = now.endOfDay;
  
  // Custom week
  final weekStart = now.startOfWeek(firstDayOfWeek: DateTime.monday);
}
```

### BuildContext 扩展方法

```dart
import 'package:init/core/utils/extensions/build_context_extensions.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Screen properties
    final width = context.screenWidth;
    final height = context.screenHeight;
    final isTablet = context.isTablet;
    final isDarkMode = context.isDarkMode;
    
    // Theme shortcuts
    final primaryColor = context.colorScheme.primary;
    final bodyTextStyle = context.textTheme.bodyMedium;
    
    // Localization
    final welcomeMessage = context.tr('welcome_message');
    final formattedDate = context.formatDate(DateTime.now(), 'short');
    final formattedCurrency = context.formatCurrency(19.99);
    
    // Navigation
    context.pop();
    context.pushNamed('/details', params: {'id': '123'});
    
    // UI helpers
    context.showSnackBar('Operation successful');
    
    return Container();
  }
}
```

## 功能实现

### 认证功能

#### 领域层（实体）

```dart
// lib/features/auth/domain/entities/user_entity.dart
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });
}
```

#### 领域层（仓储）

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserEntity>> getCurrentUser();
}
```

#### 领域层（用例）

```dart
// lib/features/auth/domain/usecases/sign_in_usecase.dart
class SignInUseCase {
  final AuthRepository repository;
  
  SignInUseCase(this.repository);
  
  Future<Either<Failure, UserEntity>> call(SignInParams params) {
    return repository.signIn(params.email, params.password);
  }
}

class SignInParams {
  final String email;
  final String password;
  
  SignInParams({required this.email, required this.password});
}
```

#### 数据层（模型）

```dart
// lib/features/auth/data/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? phone;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.phone,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      phone: json['phone'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'phone': phone,
    };
  }
  
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      profilePicture: profilePicture,
      phone: phone,
    );
  }
}
```

#### 数据层（数据源）

```dart
// lib/features/auth/data/datasources/auth_remote_datasource.dart
abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;
  
  AuthRemoteDataSourceImpl(this.apiClient);
  
  @override
  Future<UserModel> signIn(String email, String password) async {
    final response = await apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
    
    return UserModel.fromJson(response.data['user']);
  }
  
  @override
  Future<void> signOut() async {
    await apiClient.post('/auth/logout', {});
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await apiClient.get('/auth/user');
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      return null;
    }
  }
}
```

#### 数据层（仓储实现）

```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  
  AuthRepositoryImpl(this.remoteDataSource, this.localDataSource);
  
  @override
  Future<Either<Failure, UserEntity>> signIn(String email, String password) async {
    try {
      final userModel = await remoteDataSource.signIn(email, password);
      await localDataSource.saveUser(userModel);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to sign in: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to sign out: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      // Try to get user from local storage first
      final localUser = await localDataSource.getUser();
      if (localUser != null) {
        return Right(localUser.toEntity());
      }
      
      // If not available locally, try to get from remote
      final remoteUser = await remoteDataSource.getCurrentUser();
      if (remoteUser != null) {
        await localDataSource.saveUser(remoteUser);
        return Right(remoteUser.toEntity());
      }
      
      return Left(AuthFailure(message: 'User not authenticated'));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get current user: ${e.toString()}'));
    }
  }
}
```

#### 表现层（Provider）

```dart
// lib/features/auth/providers/auth_providers.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final localDataSource = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource, localDataSource);
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInUseCase(repository);
});
```

#### 表现层（Notifier - Riverpod 3 模式）

```dart
// lib/features/auth/presentation/providers/auth_provider.dart
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();
  
  Future<void> checkCurrentUser() async {
    state = state.copyWith(isLoading: true);
    
    final getCurrentUserUseCase = ref.read(getCurrentUserUseCaseProvider);
    final result = await getCurrentUserUseCase(NoParams());
    
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, isAuthenticated: false),
      (user) => state.copyWith(isLoading: false, isAuthenticated: true, user: user),
    );
  }
  
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    
    final signInUseCase = ref.read(signInUseCaseProvider);
    final params = SignInParams(email: email, password: password);
    final result = await signInUseCase(params);
    
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, errorMessage: failure.message),
      (user) => state.copyWith(isLoading: false, isAuthenticated: true, user: user),
    );
  }
  
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    final signOutUseCase = ref.read(signOutUseCaseProvider);
    final result = await signOutUseCase(NoParams());
    
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, errorMessage: failure.message),
      (_) => const AuthState(),
    );
  }
}
```

#### 表现层（状态）

```dart
// lib/features/auth/presentation/providers/auth_state.dart
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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

#### 表现层（页面）

```dart
// lib/features/auth/presentation/screens/login_screen.dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).signIn(
        _emailController.text,
        _passwordController.text,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('login.title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: context.tr('login.email_label'),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return context.tr('login.email_required');
                  }
                  if (!value!.contains('@')) {
                    return context.tr('login.email_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: context.tr('login.password_label'),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return context.tr('login.password_required');
                  }
                  if ((value?.length ?? 0) < 6) {
                    return context.tr('login.password_too_short');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (authState.isLoading)
                const CircularProgressIndicator()
              else ...[
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                ElevatedButton(
                  onPressed: _handleLogin,
                  child: Text(context.tr('login.button')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

更多代码示例请参见项目中的 `lib/examples` 目录。
