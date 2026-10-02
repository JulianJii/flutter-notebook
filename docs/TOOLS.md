---
title: Utility Tools & Scripts
---

# 实用工具与脚本

Flutter Riverpod Clean Architecture 模板包含多个实用脚本，可帮助简化开发工作流程。

## 应用重命名

通过单个命令轻松跨所有平台重新命名你的应用：

```bash
./rename_app.sh --app-name "Your App Name" --package-name com.yourcompany.appname
```

Windows（PowerShell）等价的 `rename_app.ps1` 参数一致：

```powershell
powershell -ExecutionPolicy Bypass -File .\rename_app.ps1 --app-name "Your App Name" --package-name com.yourcompany.appname
```

该脚本更新：

- Android、iOS、macOS、Windows、Linux 和 Web 中的应用显示名称
- 所有平台的包/束标识符
- 文件结构和导入引用
- 所有支持平台的构建配置

## 图标生成

通过一个命令生成所有平台的原生应用图标：

1. 将你的图标文件 (1024x1024) 放在 `assets/icon/app_icon.png`。
2. 运行生成器脚本：

```bash
./generate_icons.sh
```

这将更新：
- Android `mipmap` 资源
- iOS `Assets.xcassets`
- Web `manifest.json` 和图标
- Windows/macOS/Linux 图标文件

## 语言生成

使用本地化助手添加新语言或更新翻译：

```bash
./generate_language.sh --add fr,es,de  # Add French, Spanish, and German
./generate_language.sh --sync           # Synchronize all ARB files with the base English file
./generate_language.sh --gen            # Generate Dart code from ARB files
```

## Feature 生成

快速搭建具有所有必要文件的新 feature：

```bash
./generate_feature.sh --name feature_name        # Create a new feature structure
```

这将按照 Clean Architecture 原则创建包含 data、domain 和 presentation 层的新 feature 文件夹。

## 测试文件生成器

为 feature 生成测试文件：

```bash
./test_generator.sh feature_name
```

Windows（PowerShell）等价版本：`powershell -ExecutionPolicy Bypass -File .\test_generator.ps1 --target test/features/auth/`（也支持 `--no-coverage` / `--no-report`）。

该脚本为指定的 feature 创建必要的测试文件并包含适当的样板代码。

## 文档构建器

构建文档网站：

```bash
cd docs && ./build_docs.sh
```

该脚本将 Markdown 文档文件转换为 HTML 并生成漂亮的文档网站。

## 高级用法示例

### 创建新 Feature 和测试

```bash
# Create a new feature called "user_profile"
./generate_feature.sh --name user_profile

# Generate test files for the user_profile feature
./test_generator.sh user_profile
```

### 为生产环境重命名应用

```bash
# Rename your app for production release
./rename_app.sh --app-name "My Awesome App" --package-name com.mycompany.awesomeapp
```
