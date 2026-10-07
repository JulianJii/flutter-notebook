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
- **用例**：封装单个业务操作（例如 `UpdateNoteUseCase`、`CreateFolderUseCase`）。

**用例示例：**
```dart
class UpdateNoteUseCase {
  final NoteRepository _repository; // Depends on interface, not implementation

  UpdateNoteUseCase(this._repository);

  Future<Either<Failure, Note>> execute(Note note) {
    return _repository.updateNote(note);
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
class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource _localDataSource;

  // Error handling happens here!
  @override
  Future<Either<Failure, Note>> updateNote(Note note) async {
    try {
      final model = await _localDataSource.updateNote(NoteModel.fromEntity(note));
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
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
class ExampleNotifier extends Notifier<ExampleState> {
  @override
  ExampleState build() => const ExampleState();

  Future<void> save(Note note) async {
    state = state.copyWith(isSaving: true);

    // Use Case injected via Riverpod
    final updateNoteUseCase = ref.read(updateNoteUseCaseProvider);
    final result = await updateNoteUseCase.execute(note);

    state = result.fold(
      (failure) => state.copyWith(isSaving: false, lastFailure: failure),
      (saved) => state.copyWith(isSaving: false, note: saved),
    );
  }
}
```

### 🟣 DI 层（粘合剂）
**路径：** `lib/features/[feature]/providers/`

使用 Riverpod 连接各层。
- **依赖**：Data、Domain、Presentation。

```dart
// features/notes/providers/notes_providers.dart —— 注解式 codegen
@riverpod
NoteRepository noteRepository(Ref ref) {
  return NoteRepositoryImpl(ref.watch(noteLocalDataSourceProvider));
}
```

---

## 3. 核心概念与模式

### 函数式错误处理（`fpdart`）
我们不在 Domain 层抛出异常，而是返回 `Either<Failure, Success>`。

- **用户**："我要保存这条笔记。"
- **用例**：返回 `Either<Failure, Note>`。
- **UI**：
  ```dart
  result.fold(
    (failure) => showSnackBar(failure.message),
    (note) => showSaved(note),
  );
  ```

### 框架无关性
为保持 Data 层的可测试性，我们避免 `flutter` 导入。
- **日志**：使用 `core/logging` 的 `Logger`/`loggerProvider`，而非 `debugPrint`（`avoid_print` lint 会拦）。
- **Context**：永远不要将 `BuildContext` 传递给用例或仓库。

### Provider 组织方式
我们将数据 DI 与 UI 状态分离：
- **`features/<f>/providers/<f>_providers.dart`**：用 `@riverpod` codegen 装配数据源、仓库、用例。provider 体只做装配（无 `if`、无业务逻辑、无 try/catch）。
- **`features/<f>/presentation/providers/`**：UI 状态的 `Notifier` / `AsyncNotifier`（不用 `StateProvider` / `ChangeNotifier`）。
- **约定**：`build()` 里用 `ref.watch`（触发重建），回调 / 一次性操作用 `ref.read`。

---

## 4. 测试策略

### 单元测试（Domain/Data）
隔离测试逻辑。使用 `mocktail` 模拟依赖。
```dart
test('should return Note when update is successful', () async {
  // Arrange
  when(() => mockRepo.updateNote(any()))
    .thenAnswer((_) async => Right(tNote));

  // Act
  final result = await useCase.execute(tNote);

  // Assert
  expect(result, Right(tNote));
});
```

### Golden 测试（Presentation）
逐像素验证 UI 渲染，用 `zoloto`；`dart_test.yaml` 定义了 `golden` tag，可 `flutter test --tags golden` 单独跑。
```dart
testGoldens('NoteListScreen renders correctly', (tester) async {
  await tester.pumpWidgetBuilder(const NoteListScreen());
  await screenMatchesGolden(tester, 'note_list_screen');
});
```
