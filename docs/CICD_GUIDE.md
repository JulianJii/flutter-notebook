# CI/CD 配置指南

本指南介绍如何使用 Flutter Riverpod Clean Architecture 模板中的 CI/CD 配置来自动化构建、测试和部署流程。

## 目录

- [简介](#introduction)
- [GitHub Actions 配置](#github-actions-configuration)
- [Fastlane 集成](#fastlane-integration)
- [环境变量和密钥](#environment-variables-and-secrets)
- [手动部署](#manual-deployment)
- [环境特定配置](#environment-specific-configuration)
- [最佳实践](#best-practices)

## 简介

持续集成和持续部署（CI/CD）自动化了应用的构建、测试和部署过程。该模板包含：

- GitHub Actions 工作流用于 CI/CD
- Fastlane 配置用于简化部署
- 环境特定的配置
- 密钥管理

## GitHub Actions 配置

该模板包含位于 `.github/workflows/` 目录下的 GitHub Actions 工作流文件：

- `flutter_ci_cd.yml`：主 CI/CD 工作流
- `flutter_ci.yml`：CI 工作流
- `docs.yml`：文档部署工作流

### Push/PR 自动触发

工作流在以下情况下自动触发：
- Push 到 `main` 和 `develop` 分支
- Pull request 到 `main` 和 `develop` 分支

### 静态分析

```yaml
analyze:
  name: Static Analysis
  # Configuration for running Flutter analyze and format check
```

### 测试

```yaml
test:
  name: Run Tests
  # Configuration for running unit and widget tests
  # Includes code coverage report generation
```

### Android 构建

```yaml
build_android:
  name: Build Android App
  # Configuration for building Android APK and App Bundle
  # Only runs on push to main
```

### iOS 构建

```yaml
build_ios:
  name: Build iOS App
  # Configuration for building iOS IPA
  # Only runs on push to main
```

### 部署

```yaml
deploy_android:
  name: Deploy Android to Play Store
  # Configuration for deploying to Play Store
  # Only runs on push to main

deploy_ios:
  name: Deploy iOS to TestFlight
  # Configuration for deploying to TestFlight
  # Only runs on push to main
```

## Fastlane 集成

> **注意**：当前项目仅包含基本的 `fastlane/Fastfile` 配置。完整的 Fastlane 设置（包括 `Gemfile`、`Appfile` 和平台特定目录）待后续添加。

### Android 命令

```bash
# Build for development
fastlane android build env:development

# Build for production
fastlane android build env:production

# Deploy to Google Play internal track
fastlane android deploy env:production track:internal

# Deploy to Google Play production
fastlane android deploy env:production track:production
```

### iOS 命令

```bash
# Build for development
fastlane ios build env:development

# Build for production
fastlane ios build env:production

# Deploy to TestFlight
fastlane ios deploy env:production
```

## 环境变量和密钥

### 必需的密钥（GitHub）

在 GitHub 仓库设置中添加以下密钥：

#### Android
- `ANDROID_KEYSTORE_BASE64`: Base64-encoded Android keystore
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_ALIAS`: Key alias
- `ANDROID_KEY_PASSWORD`: Key password
- `PLAY_STORE_JSON_KEY`: Google Play service account JSON key

#### iOS
- `APPLE_ID`: Apple ID email
- `APP_SPECIFIC_PASSWORD`: App-specific password
- `TEAM_ID`: Apple developer team ID

### 环境文件

项目使用 `flutter_dotenv` 管理环境变量。在项目根目录中创建 `.env` 文件：

```
APP_VERSION_NAME=1.0.0
APP_VERSION_CODE=1
API_URL=https://api.example.com
```

## 手动部署

### 首次设置 Fastlane

```bash
# Install Fastlane
gem install fastlane

# For Android, set up Google Play credentials
fastlane supply init

# For iOS, set up App Store Connect credentials
fastlane pilot init
```

### Android 手动部署

```bash
cd android
fastlane android deploy env:production track:internal
```

### iOS 手动部署

```bash
cd ios
fastlane ios deploy env:production
```

## 环境特定配置

### Flutter 环境配置

> **注意**：当前项目不使用 flavor 系统。环境配置通过 `flutter_dotenv` 和 `.env` 文件管理。所有环境共享单个 `lib/main.dart` 入口。

## 最佳实践

1. **绝不提交密钥**：始终使用环境变量或密钥管理
2. **将 CI/CD 配置纳入版本控制**：将工作流文件纳入版本控制
3. **部署前先测试**：确保所有测试通过后再部署
4. **使用 feature flags**：将部署与功能发布解耦
5. **语义化版本**：使用正确的版本号规范（MAJOR.MINOR.PATCH）
6. **自动化一切**：避免部署过程中的手动步骤
7. **监控发布**：部署后跟踪崩溃和问题
8. **保持构建快速**：优化并缓存依赖
9. **编写发布说明**：为用户记录变更
10. **规划回滚方案**：准备回退到之前版本的策略

通过遵循这些实践，你可以构建一个强大的 CI/CD 流水线，简化开发流程并降低生产环境中的错误风险。
