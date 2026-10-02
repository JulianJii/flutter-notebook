---
title: Architecture Guide
---

# 架构指南

本项目遵循严格的 **Clean Architecture** 原则，并使用 **Riverpod 3**（基于代码生成）适配 Flutter。核心目标是关注点分离和可测试性。

---

## 1. 依赖规则

本架构中最重要的规则：**源代码依赖只能指向内部。**

```mermaid
graph TD
    Presentation[Presentation Layer (Flutter)] --> Domain[Domain Layer (Pure Dart)]
    Data[Data Layer (Impl)] --> Domain
    Presentation --> Data -- DI only --> Domain
```

- **Domain 层**：对 Flutter、Data 和 Presentation 一无所知。
- **Data 层**：了解 Domain。实现 Domain 中定义的接口。
- **Presentation 层**：了解 Domain。仅通过依赖注入使用 Data 层。

---

## 2. 分层详解

### 🟡 Domain 层（核心）
**路径：** `lib/features/[feature]/domain/`

这是您功能的核心，包含业务逻辑。
- **依赖**：仅限纯 Dart。（例外：`fpdart`、`equatable`）。
- **实体**：继承 `Equatable` 的简单数据类。
- **仓库（接口）**：数据操作可能性的抽象定义。
- **用例**：封装单个业务操作（例如 `LoginUseCase`、`SendMessageUseCase`）。

**用例示例：**
```dart
class LoginUseCase {
  final AuthRepository _repository; // Depends on interface, not implementation

  LoginUseCase(this._repository);

  Future<Either<Failure, UserEntity>> execute(String email, String password) {
    return _repository.login(email, password);
  }
}
```

### 🔵 Data 层（基础设施）
**路径：** `lib/features/[feature]/data/`

处理数据的获取和存储。
- **依赖**：Domain 层、外部包（Dio、shared_preferences 等）。
- **模型**：实体的扩展，包含 `fromJson`/`toJson` 方法。
- **数据源**：底层数据访问（API 调用、数据库查询）。
- **仓库（实现）**：实现 Domain 接口。将异常映射为失败。

**仓库实现示例：**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  // Error handling happens here!
  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final model = await _remoteDataSource.login(email, password);
      return Right(model.toEntity());
    } on NetworkException {
      return Left(NetworkFailure());
    }
  }
}
```

### 🟢 Presentation 层（UI）
**路径：** `lib/features/[feature]/presentation/`

显示数据并处理用户事件。
- **依赖**：Domain 层、Flutter、Riverpod。
- **Provider**：管理 UI 状态（加载中、成功、错误）。
- **页面**：监视 Provider 的简单 Widget。
- **组件**：可复用的组件。

**Notifier 示例：**
```dart
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    
    // Use Case injected via Riverpod
    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase.execute(email, password);

    state = result.fold(
      (failure) => state.copyWith(isLoading: false, errorMessage: failure.message),
      (user) => state.copyWith(isLoading: false, isAuthenticated: true, user: user),
    );
  }
}
```

### 🟣 DI 层（粘合剂）
**路径：** `lib/features/[feature]/providers/`

使用 Riverpod 连接各层。
- **依赖**：Data、Domain、Presentation。

```dart
// connect domain interface to data implementation
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(remoteDataSourceProvider));
});
```

---

## 3. 核心概念与模式

### 函数式错误处理（`fpdart`）
我们不在 Domain 层抛出异常，而是返回 `Either<Failure, Success>`。

- **用户**："我要登录。"
- **用例**：返回 `Either<Failure, User>`。
- **UI**：
  ```dart
  result.fold(
    (failure) => showError(failure),
    (user) => navigateToHome(user),
  );
  ```

### 框架无关性
为保持 Data 层的可测试性，我们避免 `flutter` 导入。
- **日志**：使用 `core/utils/logger.dart` 中的 `Logger`，而非 `debugPrint`。
- **Context**：永远不要将 `BuildContext` 传递给用例或仓库。

### Provider 组织方式
我们将数据 DI 与 UI 状态分离：
- **`[feature]_providers.dart`**：提供仓库、用例、数据源。
- **`[feature]_provider.dart`**：提供用于 UI 状态的 `NotifierProvider`。

---

## 4. 测试策略

### 单元测试（Domain/Data）
隔离测试逻辑。使用 `mocktail` 模拟依赖。
```dart
test('should return User when login is successful', () async {
  // Arrange
  when(() => mockRepo.login(any(), any()))
    .thenAnswer((_) async => Right(tUser));
  
  // Act
  final result = await useCase.execute('test@test.com', 'pass');
  
  // Assert
  expect(result, Right(tUser));
});
```

### Golden 测试（Presentation）
逐像素验证 UI 渲染。
```dart
testGoldens('LoginScreen renders correctly', (tester) async {
  await tester.pumpWidgetBuilder(LoginScreen());
  await screenMatchesGolden(tester, 'login_screen');
});
```
