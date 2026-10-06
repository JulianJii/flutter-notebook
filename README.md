# 笔记本 · Notebook

![Flutter](https://img.shields.io/badge/Flutter-3.47-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?style=flat&logo=dart)
![Riverpod](https://img.shields.io/badge/Riverpod-3.4-0175C2?style=flat)
![Architecture](https://img.shields.io/badge/Architecture-Clean-success)
![License](https://img.shields.io/badge/License-MIT-purple)

一个**本地优先（local-first）的笔记本应用**：记笔记、管文件夹、勾待办。
工程上同时是一套生产就绪的 Flutter 骨架 —— **Clean Architecture** 严格分层 + **Riverpod 3**（状态管理 + 依赖注入）+ **fpdart** 函数式错误处理。

数据全部落在本地（Drift / SQLite + SharedPreferences），无登录、无账号，打开即写。

---

## 应用功能

| 页面 | 路由 | 能力 |
|------|------|------|
| 笔记列表 | `/notes` | 瀑布流卡片、按标题 / 正文搜索（无结果有空态提示）、按文件夹筛选（全部 / 未分类 / 指定文件夹）、排序（编辑时间 / 创建时间 / 标题）、字数统计 |
| 笔记详情 | `/notes/:id`、`/notes/new` | 标题 + 正文编辑，自动保存（失败弹 Snackbar，草稿不丢）、归属文件夹、删除（二次确认） |
| 文件夹管理 | `/notes/folders` | 新建 / 重命名 / 删除文件夹，显示每个文件夹的笔记数 |
| 最近删除 | `/notes/trash` | 软删除笔记列表：恢复、永久删除（二次确认）、清空回收站（二次确认） |
| 待办 | `/todos` | 新建、编辑、勾选完成（完成态灰字删除线）、删除（二次确认）；未完成置顶，已完成沉入可折叠的「已完成 N」，顶栏可一键清除全部已完成 |
| 设置 | `/settings` | 笔记字号、默认排序、列表布局、深色模式（跟随系统 / 浅色 / 深色）、强提醒开关、最近删除入口、隐私政策 / 用户协议 |

底部 `NotesShell` 用 `StatefulShellRoute.indexedStack` 承载「笔记 / 待办」两个 Tab，切换不丢列表状态；`/settings` 挂在 root navigator 上整屏覆盖。

---

## 工程特性

**架构**
- 四层分离：`domain` / `data` / `presentation` / `providers`（DI 装配）。`domain` 是纯 Dart，不依赖 Flutter，可脱离框架测试。
- 错误处理类型化：`Either<Failure, T>`；Exception→Failure 的映射只在 data 层发生，UI 永不接触原始异常。
- Riverpod 3 注解式 provider（`riverpod_generator`）+ `AsyncNotifier` / `Notifier`。

**已接入的基建**
- 本地持久化：Drift（笔记、文件夹、待办）+ SharedPreferences（设置）。
- 自建 Design Token 主题（颜色 / 字阶走 `ThemeExtension`，间距 / 圆角 / 阴影走常量），中英双语，功能开关，埋点分析，本地通知，两级缓存，应用更新检查。
- 集成示例（`core/network/integrations/`）：WebSocket、gRPC、基于 dio 的轻量 GraphQL、webhook、文件传输。

**工程化**
- 零容忍 lint（`flutter_lints` + `riverpod_lint`），`flutter analyze` 必须全绿。
- 代码生成脚本（feature / 语言 / 图标 / 重命名 / 测试脚手架），`.sh` 与 `.ps1` 双版本。
- GitHub Actions：分析、测试、覆盖率、文档站点。

---

## 快速开始

**环境**：Flutter 3.47.5 / Dart `>=3.11.0 <4.0.0`（见 `pubspec.yaml`）

```bash
git clone <your-repo-url>
cd flutter-notebook

flutter pub get                                          # 安装依赖
dart run build_runner build --delete-conflicting-outputs  # 生成 freezed / json / riverpod / drift / assets
flutter run                                              # 开发运行
```

> 新增或修改了 `@riverpod` / `@freezed` / `@JsonSerializable` / Drift 表，必须先跑 build_runner。
> 只改了 `.arb` 文案则只需 `flutter gen-l10n`（`run`/`build` 时也会自动执行）。

**生产构建**

```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./symbols
flutter build ios --release --obfuscate --split-debug-info=./symbols
```

---

## 常用命令

```bash
flutter analyze                  # 静态分析（零容忍）
flutter test                     # 全量测试
flutter test test/features/notes # 单 feature 测试
flutter test --update-goldens    # 刷新 golden 基线
dart run build_runner clean      # 清除生成物
dart run build_runner watch -d   # 监听式生成
dart fix --apply                 # 批量自动修复
```

---

## 项目结构

```
lib/
├── core/             # 共享内核
│   ├── error/        # Failure / AppException
│   ├── network/      # ApiClient(dio)、WS/gRPC/GraphQL 集成
│   ├── database/     # drift AppDatabase + appDatabaseProvider
│   ├── storage/      # 本地存储 + 两级缓存
│   ├── theme/tokens/ # AppColors / AppTextStyles / AppSpacing / AppRadius / AppElevation
│   ├── router/       # app_routes.dart（路径常量）+ app_router.dart（唯一 GoRouter）
│   ├── shell/        # NotesShell（底部 Tab 外壳）
│   ├── localization/ images/ logging/ analytics/ feature_flags/
│   ├── notifications/ updates/ background/ providers/ ui/ utils/
│   └── cli/ constants/
├── features/         # notes（笔记 + 文件夹）、todos（待办）、settings（设置）
├── examples/         # 各能力演示页
├── gen/              # 生成代码（assets.gen.dart、l10n）
├── l10n/arb/         # ARB 源（模板 intl_zh.arb）
└── main.dart         # ProviderScope + overrides
```

### Feature 结构（Screaming Architecture）

```
features/<feature>/
├── domain/           # 纯 Dart，禁止 import Flutter / data / presentation
│   ├── entities/     # 业务对象
│   ├── repositories/ # 抽象接口
│   └── usecases/     # 单个操作，返回 Future<Either<Failure, T>>
├── data/             # 禁止 import Flutter，禁止 print（用 core/logging）
│   ├── datasources/  # 远程 + 本地
│   ├── models/       # fromJson / toJson + toEntity()
│   └── repositories/ # 实现 domain 接口：Exception → Failure
├── presentation/     # UI
│   ├── providers/    # Notifier / AsyncNotifier
│   ├── screens/
│   └── widgets/
└── providers/        # DI 装配：datasource / repository / usecase
```

以 `features/notes` 为例：`Note`/`NoteFolder`/`NoteQuery` 是纯实体，筛选是 `sealed NoteFolderFilter` 三态（全部 / 未分类 / 指定文件夹），列表由 `StreamProvider.family(NoteQuery)` 驱动，改筛选即自动重查。

---

## 代码生成脚本

```bash
./generate_feature.sh --name my_feature [--no-ui] [--no-repo]   # 生成四层 feature
./generate_language.sh add fr "Français"                        # 新增语言（--sync 对齐 ARB，--gen 生成 Dart）
./generate_icons.sh                                             # 先把 1024×1024 图标放到 assets/icon/app_icon.png
./rename_app.sh --app-name "My App" --package-name com.company.app
./test_generator.sh notes                                       # 生成测试脚手架
```

Windows 用同名 `.ps1`（参数一致）；执行策略受限时：
`powershell -ExecutionPolicy Bypass -File .\generate_feature.ps1 --name my_feature`

---

## 测试

- **单元测试**：use case mock repository，repository mock datasource，用 `mocktail`。
- **Widget 测试**：Screen 级 override repository 为 mock，不接真实 drift 库。
- **Golden 测试**：`zoloto`，基线 360×778 / `pixelRatio = 1.0`。

每个 use case 覆盖成功 + 失败路径；新功能必须带测试。

---

## 文档

| 文档 | 内容 |
|------|------|
| [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) | 上手流程 |
| [docs/ARCHITECTURE_GUIDE.md](docs/ARCHITECTURE_GUIDE.md) | 分层与目录约定 |
| [docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md) | 编码规范与设计模式 |
| [docs/FEATURES.md](docs/FEATURES.md) | 核心功能说明 |
| [docs/OPEN-DESIGN-QUESTIONS.md](docs/OPEN-DESIGN-QUESTIONS.md) | 待设计确认清单（代码里的 `Q` 编号台账） |
| [docs/TOOLS.md](docs/TOOLS.md) | 生成器脚本用法 |
| [docs/CICD_GUIDE.md](docs/CICD_GUIDE.md) | CI/CD 与发布 |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | 贡献流程 |

专项指南：`LOCALIZATION_GUIDE.md`、`FEATURE_FLAGS_GUIDE.md`、`IMAGE_HANDLING_GUIDE.md`、`ANALYTICS_GUIDE.md`、`EXAMPLES.md`。

---

## 许可证

MIT，详见 [LICENSE](LICENSE)。
