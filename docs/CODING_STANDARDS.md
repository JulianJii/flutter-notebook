---
title: 编码规范
---

# 编码规范
 & 最佳实践

为保持代码库的高质量，必须严格遵守以下规范。

---

## 1. 架构规则

### ❌ 禁止在 Domain 层导入 Flutter
Domain 层必须是纯 Dart。
- **错误**：`import 'package:flutter/material.dart';`
- **正确**：`import 'package:equatable/equatable.dart';`

### ❌ 禁止在 Data 层导入 Flutter（模型除外）
数据源应与框架无关。
- **错误**：`debugPrint('error')`
- **正确**：`Logger.error('error')`（来自 `core/logging`）

### ✅ 始终使用 `fpdart` 处理错误
不要在 Use Case 或 Repository 中抛出异常。
- **错误**：`Future<User>`（抛出异常）
- **正确**：`Future<Either<Failure, User>>`

---

## 2. Riverpod 模式

### ✅ 使用 `Notifier` / `AsyncNotifier`
避免对复杂状态使用 `StateProvider` 或 `ChangeNotifier`。
- **原因**：更好的可测试性和生命周期管理。

### ✅ 分离数据层 DI 与 UI 状态
- **数据 Provider**：放置在 `features/[feature]/providers/` 中，定义 Repository/UseCase/DataSource。
- **UI Provider**：放置在 `features/[feature]/presentation/providers/` 中，为页面定义 `Notifier`。

### ✅ 在 build() 中使用 `ref.watch`，在回调中使用 `ref.read`
- **watch**：用于触发重建的值。
- **read**：用于一次性操作（如按钮点击）。

---

## 3. 代码风格

### ✅ 显式类型
始终显式声明返回值和参数的类型。
```dart
// Bad
var x = 10;
getUser() { ... }

// Good
int x = 10;
Future<User> getUser() { ... }
```

### ✅ 尾逗号
始终使用尾逗号以获得更好的格式化效果。

### ✅ Feature 内部使用相对导入
同一 feature 内的文件使用相对导入。
```dart
import '../domain/entities/user.dart'; // Good
```
跨 feature 边界或 core 时使用 package 导入。
```dart
import 'package:app/core/utils/logger.dart'; // Good
```

---

## 4. 测试

### ✅ Mock 所有外部依赖
测试 Use Case 时使用 `mocktail` mock Repository，测试 Repository 时 mock RemoteDataSource。

### ✅ 100% Domain 覆盖率
理想情况下，每个 Use Case 都应有单元测试覆盖成功和失败路径。

### ✅ UI 使用 Golden 测试
对复杂页面使用 Golden 测试以防止视觉回归。
