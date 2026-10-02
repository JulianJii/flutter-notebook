# Flutter Riverpod 干净架构模板

![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?style=flat&logo=flutter)
![Riverpod](https://img.shields.io/badge/Riverpod-2.0+-0175C2?style=flat)
![Architecture](https://img.shields.io/badge/Architecture-Clean-success)
![License](https://img.shields.io/badge/License-MIT-purple)

面向现代应用开发、生产就绪、高度可扩展的 Flutter 模板。本项目实现了严格类型化的**干净架构**，并使用 **Riverpod** 进行状态管理与依赖注入。

---

## 🚀 核心特性

### 核心架构
- **严格干净架构**：Domain、Data、Presentation 各层清晰分离。
- **函数式错误处理**：使用 `fpdart` 实现类型安全的错误处理（`Either<Failure, T>`）。
- **Riverpod 2.0**：使用 `Notifier` 和 `AsyncNotifier` 的现代 Provider 模式。
- **框架无关**：Domain 与 Data 层无需依赖 Flutter 即可测试。

### 开发者体验
- **特性生成器**：数秒内生成完整功能（`./generate_feature.sh`）。
- **严格 Lint**：零容忍的分析选项，保障代码质量。
- **CI/CD 就绪**：内置 GitHub Actions 自动化测试与分析。
- **类型安全**：全程空安全与严格类型化。

### 高级能力
- **实时功能**：WebSocket 集成示例（Chat）。
- **复杂表单**：带验证的高级表单处理（Survey）。
- **离线优先**：使用 SharedPreferences 的本地存储策略。
- **安全存储**：加密的凭据存储。
- **生物识别认证**：FaceID 与指纹集成。
- **本地化**：内置多语言支持。

---

## 📚 文档

- [**架构指南**](docs/ARCHITECTURE_GUIDE.md)：深入解析项目结构。
- [**编码规范**](docs/CODING_STANDARDS.md)：本项目使用的规则与模式。
- [**功能指南**](docs/FEATURES.md)：核心功能文档。
- [**CLI 工具**](docs/TOOLS.md)：如何使用生成器脚本。

---

## 🛠️ 快速开始

### 1. 环境要求
- Flutter SDK（3.7+）
- Dart SDK（3.0+）

### 2. 安装
```bash
# 克隆仓库
git clone https://github.com/jessejii/init.git

# 安装依赖
flutter pub get

# 生成代码（Freezed、Riverpod 等）
dart run build_runner build --delete-conflicting-outputs
```

### 3. 运行应用
```bash
# 开发模式
flutter run

# 生产构建
flutter build apk --release
```

---

## ⚡ 生成新功能

无需手动编写样板代码！使用内置的生成器脚本：

```bash
# 生成包含 UI、Domain 与 Data 层的完整功能
./generate_feature.sh --name my_awesome_feature
```

这将创建：
- `domain/entities/`、`repositories/`、`usecases/`
- `data/models/`、`datasources/`、`repositories/`
- `presentation/providers/`、`screens/`、`widgets/`
- `providers/`（DI 配置）
- 各层的单元测试

## 📦 应用重命名

让你的项目拥有正确的身份！使用我们的重命名工具：

```bash
./rename_app.sh --app-name "My Super App" --package-name com.company.superapp
```

这将更新：
- Android：`AndroidManifest.xml`、`build.gradle`、Kotlin 文件
- iOS：`Info.plist`、项目文件
- macOS、Windows、Linux 构建文件
- Dart 包名与导入

## 🎨 图标生成

一条命令即可生成全平台的原生应用图标：

1. 将你的图标文件（1024x1024）放到 `assets/icon/app_icon.png`。
2. 运行生成器脚本：

```bash
./generate_icons.sh
```

这将更新：
- Android `mipmap` 资源
- iOS `Assets.xcassets`
- Web `manifest.json` 与图标
- Windows/macOS/Linux 图标文件

---

## 🏗️ 项目结构

```
lib/
├── core/                       # 共享内核（错误、网络、工具）
├── features/                   # 功能模块
│   ├── auth/                   # 认证功能
│   ├── chat/                   # WebSocket 聊天功能
│   ├── survey/                 # 复杂表单功能
│   └── ...
├── main.dart                   # 入口点
└── ...
```

### 功能结构（"Screaming Architecture"）
每个功能都是一个自包含的模块：

```
feature_name/
├── domain/                     # 1. 最内层（纯 Dart）
│   ├── entities/               # 业务对象（Equatable）
│   ├── repositories/           # 抽象接口
│   └── usecases/               # 业务逻辑单元
├── data/                       # 2. 外层（实现）
│   ├── datasources/            # API/DB 客户端
│   ├── models/                 # JSON 解析与适配
│   └── repositories/           # 仓库实现
├── presentation/               # 3. UI 层（Flutter）
│   ├── providers/              # UI 状态管理（Notifiers）
│   ├── screens/                # 页面组件
│   └── widgets/                # 可复用组件
└── providers/                  # 4. DI 层（Riverpod）
    └── feature_providers.dart  # 数据层依赖注入
```

---

## 🧪 测试

我们采用全面的测试策略：

- **单元测试**：针对 Use Cases、Repositories 与 Data Sources。
- **Widget 测试**：针对可复用的 UI 组件。
- **Golden 测试**：针对页面的视觉回归测试。

```bash
# 运行全部测试
flutter test

# 刷新 Golden 文件
flutter test --update-goldens
```

---

## 🤝 参与贡献

1. Fork 本项目
2. 创建你的功能分支（`git checkout -b feature/AmazingFeature`）
3. 提交你的更改（`git commit -m 'Add some AmazingFeature'`）
4. 推送到该分支（`git push origin feature/AmazingFeature`）
5. 发起 Pull Request

## 常用命令
```

dart fix --dry-run
dart fix --apply

flutter create . --platforms=android  --org com.wode

# 删除所有生成的文件
dart run build_runner clean

# 重新生成
dart run build_runner build -d
flutter pub run build_runner watch -d

#修改包名
dart run change_app_package_name:main com.new.package.name

flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./symbols
flutter build ios --release --obfuscate --split-debug-info=./symbols

dart run flutter_native_splash:create

```


---

## 📄 许可证

基于 MIT 许可证发布。更多信息请参阅 `LICENSE`。