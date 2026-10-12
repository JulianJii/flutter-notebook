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

使用本地化助手添加新语言或检查翻译（子命令制，不认 `--add` 这类 flag）：

```bash
./generate_language.sh add fr     # 新增语言（如法语；只需语言码）
./generate_language.sh list       # 列出支持的语言
./generate_language.sh check      # 检查缺失的翻译键
./generate_language.sh generate   # 从 ARB 生成 Dart（即 flutter gen-l10n）
```

## Feature 生成

快速搭建具有所有必要文件的新 feature：

```bash
./generate_feature.sh --name feature_name        # Create a new feature structure
```

这将按照 Clean Architecture 原则创建包含 data、domain 和 presentation 层的新 feature 文件夹。

## 测试运行器（带覆盖率）

运行测试并可选生成 lcov 覆盖率报告 —— 它**不生成测试文件**：

```bash
./test_generator.sh                                      # 全量测试 + 覆盖率
./test_generator.sh --target test/features/notes/        # 只跑指定路径
./test_generator.sh --no-coverage                        # 不统计覆盖率
```

Windows（PowerShell）等价版本：`powershell -ExecutionPolicy Bypass -File .\test_generator.ps1 --target test/features/notes/`（也支持 `--no-coverage` / `--no-report`）。

覆盖率转 HTML 报告需要本机装有 `lcov`（`genhtml`）；未安装时只产出原始 `coverage/lcov.info`。

## 高级用法示例

### 创建新 Feature 和测试

```bash
# Create a new feature called "user_profile"
./generate_feature.sh --name user_profile

# Run tests for the user_profile feature
./test_generator.sh --target test/features/user_profile/
```

### 为生产环境重命名应用

```bash
# Rename your app for production release
./rename_app.sh --app-name "My Awesome App" --package-name com.mycompany.awesomeapp
```
