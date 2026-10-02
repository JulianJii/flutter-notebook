# 为 Flutter Riverpod Clean Architecture 贡献

感谢你有兴趣为 Flutter Riverpod Clean Architecture 项目做出贡献！本文档提供了贡献的指南和说明。

## 行为准则

请阅读并遵守我们的[行为准则](CODE_OF_CONDUCT.md)，共同营造一个包容和尊重的社区环境。

## 如何贡献

### 报告 Bug

如果你在项目中发现了 bug，请在我们的 GitHub 仓库中创建一个 issue，并包含以下信息：

- 清晰、描述性的标题
- 重现 bug 的详细步骤
- 预期行为和实际发生的情况
- 如适用，请附上截图
- 环境详情（Flutter 版本、设备/模拟器信息等）

### 建议功能

我们欢迎功能建议！请创建一个 issue 并包含：

- 功能的清晰描述
- 添加此功能的理由
- 如有可能，概述该功能可能的实现方式
- 该功能的使用示例

### Pull Request

我们欢迎你的 pull request：

1. Fork 仓库
2. 创建你的功能分支（`git checkout -b feature/amazing-feature`）
3. 提交你的更改（`git commit -m 'Add some amazing feature'`）
4. 推送到分支（`git push origin feature/amazing-feature`）
5. 创建 Pull Request

#### 对于 pull request，请确保：

- 你的代码遵循项目的代码风格指南
- 你为新功能添加了测试
- 你的提交格式规范且描述清晰
- 你已按需更新了文档
- PR 描述清晰地说明了更改内容

## 开发环境配置

1. Fork 并克隆仓库
2. 安装 Flutter SDK（3.10.0 或更高版本）
3. 安装依赖：
   ```bash
   flutter pub get
   ```
4. 运行测试以确保一切配置正确：
   ```bash
   flutter test
   ```

## 代码风格指南

- 遵循 [Effective Dart 风格指南](https://dart.dev/guides/language/effective-dart)
- 使用有意义的变量和函数名
- 为公共 API 编写文档
- 保持函数小而专注
- 使用 `dart format` 格式化代码

## 测试

所有新功能和 bug 修复都应包含测试：

```bash
# 运行所有测试
flutter test

# 运行特定 feature 的测试
flutter test test/features/auth
```

## 文档

进行更改时请更新文档：

- 更新 `docs` 目录中相关的 markdown 文件
- 为复杂代码添加行内注释
- 如相关，请更新示例代码

## 版本控制

我们使用 [SemVer](http://semver.org/) 进行版本管理：

- MAJOR 版本号用于不兼容的 API 变更
- MINOR 版本号用于向后兼容的功能新增
- PATCH 版本号用于向后兼容的 bug 修复

## 许可证

贡献即表示你同意你的贡献将在项目的 [MIT 许可证](LICENSE) 下授权。

## 有疑问？

如有任何问题或需要帮助，请随时联系项目维护者。
