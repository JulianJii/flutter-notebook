---
title: Features
---

# 核心功能

本文档详细介绍了 Flutter Riverpod Clean Architecture 模板中的核心功能。

## 🚀 展示功能（新增！）

### 实时聊天（WebSocket）
基于 WebSocket 的聊天应用完整实现。
- **访问方式**：`Ref -> ChatProvider`
- **架构**：领域层中的 `Stream<Message>`
- **技术**：`web_socket_channel`，乐观 UI 更新
- **路径**：`lib/features/chat/`

### 复杂表单问卷
支持验证和条件逻辑的高级表单处理。
- **技术**：`flutter_form_builder`
- **功能**：
  - 异步验证（例如，用户名可用性检查）
  - 条件字段（依赖于前序答案）
  - 自定义表单输入
- **路径**：`lib/features/survey/`

---

## 分析集成

通过灵活的分析系统追踪用户交互和应用性能：

```dart
// Access analytics
final analytics = ref.watch(analyticsProvider);

// Log screen views
analytics.logScreenView('HomeScreen', parameters: {'referrer': 'deeplink'});

// Log user actions
analytics.logUserAction(
  action: 'button_tap',
  category: 'engagement',
  label: 'sign_up_button',
);
```

详情请参见[分析指南](https://jessejii.github.io/init/analytics.html)。

## 推送通知

完整的通知处理，支持深度链接和后台处理：

```dart
// Access notification service
final service = ref.watch(notificationServiceProvider);

// Request permission
final status = await service.requestPermission();

// Show a local notification
await service.showLocalNotification(
  id: 'msg-123',
  title: 'New message',
  body: 'You received a new message from John',
  action: '/chat/john',
  channel: 'messages',
);
```

## 生物识别认证

安全的指纹和人脸识别，用于保护敏感操作：

```dart
// Access biometric authentication
final biometricAuth = ref.watch(biometricAuthControllerProvider);

// Authenticate the user
if (isAvailable) {
  final result = await biometricAuth.authenticate(
    reason: 'Please authenticate to access your account',
    authReason: AuthReason.appAccess,
  );
}
```

详情请参见[生物识别认证指南](https://jessejii.github.io/init/biometric_auth.html)。

## 功能开关

用于 A/B 测试和分阶段发布的运行时功能开关：

```dart
// Check if a feature is enabled
if (service.isFeatureEnabled('premium_features')) {
  // Show premium features
}
```

详情请参见[功能开关指南](https://jessejii.github.io/init/feature_flags.html)。

## 高级图片处理

支持缓存、SVG、特效和精美占位图的优化图片加载方案。

详情请参见[图片处理指南](https://jessejii.github.io/init/image_handling.html)。

## 多语言支持

内置国际化，轻松切换语言：

```dart
// Access translated text
Text(context.tr('welcome_message'));
```

详情请参见[本地化指南](https://jessejii.github.io/init/localization.html)。

## 高级缓存系统

项目实现了健壮的两级缓存系统，支持内存和磁盘两种存储方式。

```dart
// Using the cache
final cacheManager = ref.watch(userDiskCacheProvider);
await cacheManager.setItem('user_1', userEntity);
```

## 动态主题

主题系统允许完全自定义应用外观。

```dart
// Use in MaterialApp
return MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: themeMode,
);
```

## 无障碍支持

> **注意**：`core/accessibility/` 模块当前为占位目录，待后续实现。

## 离线优先架构

让你的应用在有无网络连接的情况下都能无缝运行。

详情请参见[离线架构指南](https://jessejii.github.io/init/offline_architecture.html)。

## 应用更新流程

管理应用更新，支持自定义流程。

## 应用评价系统

从用户那里获取反馈和评分。
