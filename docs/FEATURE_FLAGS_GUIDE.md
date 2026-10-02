# 功能开关系统指南

本指南介绍如何在 Flutter Riverpod Clean Architecture 模板中使用功能开关系统。

## 概述

功能开关系统提供以下能力：

- 运行时功能开关切换
- 本地配置，用于开发和测试
- 远程配置接口（Firebase Remote Config 集成待实现）
- 支持多种值类型（布尔值、字符串、整数、浮点数、颜色）
- A/B 测试能力
- 分析集成

## 目录结构

```dart
lib/core/feature_flags/
├── feature_flag_service.dart      # Service interface
├── feature_flag_providers.dart    # Riverpod providers
├── local_feature_flag_service.dart # Local implementation
└── remote_feature_flag_service.dart # Remote implementation with Firebase
```

## 使用方法

### 检查功能是否启用

```dart
final isAnalyticsEnabled = ref.watch(
  featureFlagProvider('enable_analytics', defaultValue: true)
);

if (isAnalyticsEnabled) {
  // Enable analytics tracking
} else {
  // Disable analytics tracking
}
```

### 获取配置值

```dart
// String config
final apiBaseUrl = ref.watch(
  stringConfigProvider('api_base_url', defaultValue: 'https://api.example.com')
);

// Int config
final cacheTime = ref.watch(
  intConfigProvider('cache_ttl_seconds', defaultValue: 3600)
);

// Double config
final cornerRadius = ref.watch(
  doubleConfigProvider('corner_radius', defaultValue: 8.0)
);

// Color config
final primaryColor = ref.watch(
  colorConfigProvider('primary_color', defaultValue: Colors.blue)
);
```

### 条件渲染组件

使用 `FeatureFlag` 组件，根据功能开关条件性地渲染 UI：

```dart
FeatureFlag(
  featureKey: 'enable_premium_features',
  defaultValue: false,
  child: PremiumFeaturesSection(),
  fallback: UpgradePrompt(), // Optional fallback widget
)
```

## 默认配置

默认值在 `feature_flag_providers.dart` 中定义：

```dart
const Map<String, dynamic> kDefaultFeatureFlags = {
  // Feature flags
  'enable_analytics': true,
  'enable_push_notifications': true,
  'enable_biometric_login': true,
  'use_debug_biometrics': false,
  'force_firebase_analytics': false,
  // ...other defaults
};
```

## 实现细节

### 开发环境与生产环境

- 在 debug 构建中，使用 `LocalFeatureFlagService` 以支持快速迭代
- 在 release 构建中，使用 `RemoteFeatureFlagService` 从 Firebase Remote Config 获取值
- 两种实现共享相同的接口，确保使用方式一致

### 远程配置设置

> **注意**：Firebase Remote Config 集成当前为 stub 实现。要启用远程配置：
> 1. 按照 [FlutterFire 文档](https://firebase.flutter.dev/docs/overview/) 将 Firebase 添加到项目中
> 2. 在 Firebase 控制台中设置 Remote Config
> 3. 定义与代码中使用的键匹配的参数
4. 为 A/B 测试或分阶段发布设置条件

## 高级用法

### 功能开关监听器

注册监听器，当功能开关变更时收到通知：

```dart
final service = ref.watch(featureFlagServiceProvider);
service.addListener(() {
  // Handle flag changes
  print('Feature flags updated');
});
```

### 手动获取

强制刷新远程配置：

```dart
final service = ref.watch(featureFlagServiceProvider);
await service.fetchAndActivate();
```

### 调试工具

在开发环境中，可以运行时覆盖功能开关的值：

```dart
// Only works with LocalFeatureFlagService
if (service is LocalFeatureFlagService) {
  service.setValue('enable_dark_mode', false);
}
```

## 分析集成

功能开关的变更会自动追踪到分析系统中：

```dart
// In feature_flag_providers.dart
service.addListener(() {
  analytics.logUserAction(
    action: 'feature_flags_updated',
    category: 'config',
  );
});
```

## 测试

测试特定的功能配置：

```dart
// In test files
final mockService = MockFeatureFlagService();
when(mockService.getBool('feature_key', defaultValue: false))
  .thenReturn(true);
```

## 最佳实践

1. 使用清晰、描述性的功能开关名称
2. 为所有开关设置合理的默认值
3. 避免过深嵌套的功能开关条件
4. 在代码注释中记录所有功能开关
5. 功能完全发布后及时清理旧的开关
6. 测试功能的启用和禁用两种状态
7. 考虑远程切换功能的安全影响
