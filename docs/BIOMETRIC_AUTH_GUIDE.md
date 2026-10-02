---
title: 生物识别认证指南
description: Flutter 应用中安全生物识别认证的实现指南
---

<!-- Heading defined in front matter, no need for duplicate -->

本指南介绍如何使用 Flutter Riverpod Clean Architecture 模板中的生物识别认证功能。

## 目录

- [概述](#overview)
- [功能特性](#features)
- [实现细节](#implementation)
- [使用方法](#usage)
  - [简单认证](#simple-authentication)
  - [带载荷的认证](#authentication-with-payload)
  - [高级设置](#advanced-settings)
- [最佳实践](#best-practices)
- [问题排查](#troubleshooting)

## 概述

生物识别认证模块提供了一个安全、易用的接口，用于在 Flutter 应用中实现指纹、人脸识别和其他生物识别认证方式。

该模块处理：

- 设备兼容性检测
- 安全凭证存储
- 用户友好的提示和错误消息
- 跨平台支持（iOS、Android）
- 生物识别不可用时的优雅降级

## 功能特性

### 核心功能

- **即时集成**：几分钟内即可添加生物识别认证，配置极少
- **安全存储**：凭证经加密后使用平台特定的安全机制存储
- **多种生物识别类型**：支持指纹、Face ID 及其他生物识别方式
- **可定制 UI**：可定制提示和消息以匹配应用的品牌风格
- **降级机制**：生物识别不可用时可回退到 PIN/密码
- **Riverpod 集成**：完全支持响应式状态管理

### 安全特性

- **凭证加密**：所有敏感数据在静态存储时均经过加密
- **安全传输**：传输中的数据使用安全通道
- **防篡改检测**：验证生物识别数据的完整性
- **自动失效**：凭证可在配置的时间段后过期
- **会话管理**：跨应用会话跟踪认证状态

## 实现细节

生物识别认证系统由多个组件组成：

### 核心服务

`BiometricService` 处理所有生物识别操作：

```dart
abstract class BiometricService {
  Future<bool> isAvailable();
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<BiometricResult> authenticate({
    required String localizedReason,
    required AuthReason reason,
    String? dialogTitle,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool sensitiveTransaction = false,
  });
  Future<void> storeCredentials({required String key, required String value});
  Future<String?> getCredentials(String key);
  Future<void> deleteCredentials(String key);
}
```

### 提供者

该服务通过 Riverpod providers 暴露：

```dart
/// Provider for the biometric service
final biometricServiceProvider = Provider<BiometricService>((ref) {
  final isDebug = kDebugMode;
  if (isDebug) {
    return DebugBiometricService();
  }
  return LocalBiometricService();
});

/// Provider for biometric availability
final biometricsAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.isAvailable();
});

/// Provider for biometric types
final biometricTypesProvider = FutureProvider<List<BiometricType>>((ref) async {
  final service = ref.watch(biometricServiceProvider);
  return await service.getAvailableBiometrics();
});
```

### 认证状态

`Notifier` 管理认证状态（Riverpod 3 模式）：

```dart
/// Authentication state
class BiometricAuthState {
  final bool isAuthenticated;
  final BiometricResult? lastResult;
  final DateTime? lastAuthTime;
  
  const BiometricAuthState({
    this.isAuthenticated = false,
    this.lastResult,
    this.lastAuthTime,
  });
  
  BiometricAuthState copyWith({
    bool? isAuthenticated,
    BiometricResult? lastResult,
    DateTime? lastAuthTime,
  }) {
    return BiometricAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lastResult: lastResult ?? this.lastResult,
      lastAuthTime: lastAuthTime ?? this.lastAuthTime,
    );
  }
}

/// Authentication controller (Riverpod 3 Notifier pattern)
class BiometricAuthController extends Notifier<BiometricAuthState> {
  @override
  BiometricAuthState build() => const BiometricAuthState();
  
  Future<void> authenticate(String localizedReason) async {
    final service = ref.read(biometricServiceProvider);
    
    final result = await service.authenticate(
      localizedReason: localizedReason,
      reason: AuthReason.appAccess,
    );
    
    state = state.copyWith(
      isAuthenticated: result == BiometricResult.success,
      lastResult: result,
      lastAuthTime: result == BiometricResult.success ? DateTime.now() : null,
    );
  }
  
  void reset() {
    state = const BiometricAuthState();
  }
}

/// Provider for authentication state
final biometricAuthControllerProvider = NotifierProvider<BiometricAuthController, BiometricAuthState>((ref) {
  return BiometricAuthController();
});
```

## 使用方法

### 简单认证

为应用添加生物识别认证的最简单方式：

```dart
class BiometricLoginScreen extends ConsumerWidget {
  const BiometricLoginScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(biometricAuthControllerProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authState.isAuthenticated)
              const Icon(Icons.check_circle, color: Colors.green, size: 100)
            else if (authState.lastResult == BiometricResult.failed)
              const Text('Authentication failed', style: TextStyle(color: Colors.red)),
              
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                ref.read(biometricAuthControllerProvider.notifier).authenticate(
                  'Authenticate to access the app'
                );
              },
              child: const Text('Authenticate with Biometrics'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 带载荷的认证

更高级的用法，例如通过认证来解密存储的凭证：

```dart
class ProtectedContentScreen extends ConsumerStatefulWidget {
  const ProtectedContentScreen({super.key});
  
  @override
  ConsumerState<ProtectedContentScreen> createState() => _ProtectedContentScreenState();
}

class _ProtectedContentScreenState extends ConsumerState<ProtectedContentScreen> {
  String? _secret;
  
  @override
  void initState() {
    super.initState();
    _authenticateAndLoadSecret();
  }
  
  Future<void> _authenticateAndLoadSecret() async {
    final authService = ref.read(biometricServiceProvider);
    
    // Authenticate the user
    final result = await authService.authenticate(
      localizedReason: 'Authenticate to view protected content',
      reason: AuthReason.appAccess,
    );
    
    if (result == BiometricResult.success) {
      // Retrieve the protected data
      final secret = await authService.getCredentials('protected_data');
      setState(() {
        _secret = secret;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Content')),
      body: Center(
        child: _secret != null
            ? Text('Protected content: $_secret')
            : const Text('Authenticate to view protected content'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _authenticateAndLoadSecret,
        child: const Icon(Icons.fingerprint),
      ),
    );
  }
}
```

### 高级设置

该模块提供以下自定义选项：

```dart
// Custom authentication dialog settings
final result = await biometricService.authenticate(
  localizedReason: context.tr('auth.biometric_prompt'),
  reason: AuthReason.appAccess,
  useErrorDialogs: true,
  stickyAuth: true,  // Keep authentication session active when app goes to background
);

// Manage secure credentials with expiration
final tokenService = ref.read(secureTokenServiceProvider);
await tokenService.storeWithExpiration(
  key: 'auth_token',
  value: response.token,
  expiresInHours: 24,
);
```

## 最佳实践

1. **始终提供替代方案**：并非所有设备都支持生物识别，并非所有用户都习惯使用。始终提供替代的认证方式。

2. **清晰的错误消息**：当生物识别认证失败时，提供清晰的指导说明失败原因以及用户接下来可以做什么。

3. **仅在必要时请求**：不要为每个页面或操作都请求生物识别认证，将其保留给敏感操作使用。

4. **凭证过期**：为生物识别认证后存储的敏感凭证添加过期时间。

5. **在真实设备上测试**：生物识别认证无法在模拟器中完全测试。在真实设备上测试以确保流畅的用户体验。

6. **尊重隐私设置**：如果用户拒绝了生物识别认证，请记住该偏好，不要反复请求。

## 问题排查

### 常见问题

| 问题 | 解决方案 |
|-------|----------|
| 认证始终失败 | 检查 AndroidManifest.xml 和 Info.plist 中的权限 |
| "No hardware available" 错误 | 设备没有生物识别硬件或该功能已禁用 |
| 认证对话框未显示 | 确保应用在前台且设备已解锁 |
| 认证成功但无法获取凭证 | 检查安全存储实现中的错误 |

### 设备相关注意事项

- **Android**：需要在 manifest 中声明 `USE_BIOMETRIC` 权限。
- **iOS**：需要在 Info.plist 中添加使用说明。
- **旧设备**：可能不支持最新的生物识别功能，需测试兼容性。

### 测试

测试生物识别认证：

```dart
// Mock the biometric service in tests
final mockBiometricService = MockBiometricService();
when(() => mockBiometricService.isAvailable()).thenAnswer((_) async => true);
when(() => mockBiometricService.authenticate(
  localizedReason: any(named: 'localizedReason'),
  reason: any(named: 'reason'),
)).thenAnswer((_) async => BiometricResult.success);

// Override the provider
final container = ProviderContainer(
  overrides: [
    biometricServiceProvider.overrideWithValue(mockBiometricService),
  ],
);
```
- Feature flag 控制启用/禁用生物识别认证

## 目录结构

```
lib/core/auth/
├── biometric_service.dart     # Service interface and enums
├── biometric_providers.dart   # Riverpod providers
├── debug_biometric_service.dart # Debug implementation
└── local_biometric_service.dart # Real implementation using local_auth
```

## 使用方法

### 检查生物识别是否可用

```dart
final biometricService = ref.watch(biometricServiceProvider);
final isAvailable = await biometricService.isAvailable();

if (isAvailable) {
  // Show biometric authentication option
} else {
  // Fall back to password/PIN
}
```

### 获取可用的生物识别类型

```dart
final biometricTypes = await biometricService.getAvailableBiometrics();

if (biometricTypes.contains(BiometricType.fingerprint)) {
  // Show fingerprint icon
} else if (biometricTypes.contains(BiometricType.face)) {
  // Show face ID icon
}
```

### 使用生物识别进行认证

```dart
final result = await biometricService.authenticate(
  localizedReason: 'Authenticate to access your account',
  reason: AuthReason.appAccess,
);

switch (result) {
  case BiometricResult.success:
    // Grant access
    break;
  case BiometricResult.failed:
    // Authentication failed, try again or fall back
    break;
  case BiometricResult.cancelled:
    // User cancelled, show manual login option
    break;
  case BiometricResult.notAvailable:
  case BiometricResult.notEnrolled:
    // Device doesn't support or user hasn't set up biometrics
    break;
  case BiometricResult.lockedOut:
    // Too many failed attempts, fall back to password
    break;
  default:
    // Unexpected error
    break;
}
```

### Feature Flag 控制

可通过 feature flags 启用/禁用生物识别：

```dart
final biometricsEnabled = ref.watch(
  featureFlagProvider('enable_biometric_login', defaultValue: true),
);

if (biometricsEnabled) {
  // Show biometric login option
}
```

## 平台配置

### Android

在 `android/app/src/main/AndroidManifest.xml` 中添加以下权限：

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

对于旧版 Android：
```xml
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### iOS

在 `ios/Runner/Info.plist` 中添加以下内容：

```xml
<key>NSFaceIDUsageDescription</key>
<string>Why you are using Face ID</string>
```

## 高级用法

### 敏感交易

用于金融或其他敏感操作：

```dart
final result = await biometricService.authenticate(
  localizedReason: 'Authenticate to confirm payment',
  reason: AuthReason.transaction,
  sensitiveTransaction: true,
);
```

### 自定义分析

`biometricServiceProvider` 会自动记录分析事件。你可以在分析仪表盘中查看这些事件。

## 测试

在调试构建中将 `use_debug_biometrics` feature flag 设为 `true`，即可使用 `DebugBiometricService` 进行测试。

## 问题排查

- **"No hardware available"**：设备不支持生物识别认证
- **"No biometrics enrolled"**：用户尚未在设备上设置生物识别
- **"Authentication locked out"**：失败尝试次数过多，通常 30 秒后重置
- **"Authentication permanently locked out"**：用户必须先使用 PIN/密码解锁

## 最佳实践

1. 始终提供替代的认证方式
2. 将生物识别用于低风险操作或作为第二因素
3. 透明地说明生物识别数据的使用方式（绝不远程存储）
4. 优雅地处理所有错误状态
5. 尊重用户的隐私偏好
