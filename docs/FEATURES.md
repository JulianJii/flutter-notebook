---
title: Features
---

# 核心功能

本文档介绍本项目的两类功能：**产品功能**（`features/` 下真实存在的笔记 / 待办 / 设置）与**工程能力**（`core/` 下的基建）。

---

## 产品功能

### 笔记（`lib/features/notes/`）

- **列表** `/notes`：瀑布流卡片、按标题 / 正文搜索（无结果有空态提示）、按文件夹筛选（全部 / 未分类 / 指定文件夹）、排序（编辑时间 / 创建时间 / 标题）、字数统计。
- **详情** `/notes/:id`、`/notes/new`：标题 + 正文编辑，**自动保存**（失败弹 Snackbar，草稿不丢）、归属文件夹、删除（二次确认）。正文唯一真相源是 **Quill Delta JSON**（`flutter_quill`）。从某个分类页点 + 号进 `/notes/new?folder=<id>`（`AppRoutes.noteNewPath`），该分类随新笔记一起落库。
- **文件夹管理** `/notes/folders`：新建 / 重命名 / 删除 / 拖拽排序，显示每个文件夹的笔记数。
- **最近删除** `/notes/trash`：软删除列表，支持恢复、永久删除、清空回收站（均二次确认）。

> 筛选是 `sealed NoteFolderFilter` 三态；列表由 `StreamProvider.family(NoteQuery)` 驱动，筛选 / 排序变化即自动重查。

### 待办（`lib/features/todos/`）

新建、编辑、勾选完成（完成态灰字删除线）、删除（二次确认）；未完成置顶，已完成沉入可折叠的「已完成 N」，顶栏可一键清除全部已完成。排序真相源在 `TodoDao.watchAll` 的 `ORDER BY is_done ASC, created_at DESC`。

- **点卡片 → 详情小窗**（`todo_reminder_sheet.dart`）：只读标题 + 提醒时间 + 完成；标题旁的铅笔回落到原来的编辑弹窗（改标题 / 删除只有一个入口）。
- **提醒**：小窗里点时钟图标 → 从下往上弹「设置提醒时间」（内置 `showDatePicker` / `showTimePicker`，⛔ 无农历）。确定后由 `todoReminderProvider` **先落库 `reminder_at` 再注册系统通知**（`flutter_local_notifications`），清除则反过来先取消通知。没授予通知权限时不落库 —— 存了也提醒不了。

| 入口 | 位置 |
|---|---|
| `todoReminderProvider` | `features/todos/presentation/providers/todo_reminder_provider.dart`（编排：落库 + 调度） |
| `reminderSchedulerProvider` | `core/notifications/reminder_scheduler.dart`（平台通知的唯一出入口） |

> ⚠️ 通知 id 由 `todo.id.hashCode` 掩码到 31 位派生，不另存列；**不做**重复提醒、不做重启后恢复（重启后已设的提醒不会响）。

### 设置（`lib/features/settings/`）

笔记字号、默认排序、列表布局、深色模式（跟随系统 / 浅色 / 深色）、最近删除入口、隐私政策 / 用户协议。偏好持久化在 SharedPreferences，由 `settingsProvider` 承载。

「数据与同步」行是进入 `features/backup/` 的跳转入口（见下节），不把 WebDAV 配置并进 `AppSettings` —— 那是「App 长什么样」的偏好，凭据是另一回事。

### 数据与同步（`lib/features/backup/`）

导出 / 导入 / WebDAV 三个动作共用**同一份快照模型** `BackupSnapshot`（`notes` + `note_folders` + `todos` 三表全量，含回收站里的软删除笔记）：

| 动作 | 链路 |
|---|---|
| 导出 | 读全量 → JSON → 写临时文件 → 系统分享面板（存到哪由用户自己选） |
| 导入 | 文件选择器选 `.json` → 按 id 合并进本地 |
| 同步 | `GET` 远端快照 → 与本地合并 → `PUT` 回去 → 合并结果落本地 |

**合并规则只有一条**：逐条比 `max(updatedAt, deletedAt ?? 0)`，新的赢，一样新保留本地（避免无意义写库）。只新增不删除 —— 符合「永不丢数据」，且软删除靠 `deletedAt` 也能跨设备传播，不会被一条更晚的编辑复活。

- 同步是**单文件快照**，不是增量队列：`GET` 到 404 就当「远端还没文件」，等价于首次推送。因此不需要冲突状态机 —— 模板自带的离线变更队列（`offline_sync_service` / `connectivity_plus`）未接线，已整体移除。
- 快照有自己的 `version`（当前 1），高于它的直接拒绝导入，不静默降级解析。
- WebDAV 客户端是 **dio 手搓**的（`GET` / `PUT` / `MKCOL` / `PROPFIND` + Basic Auth），不引第三方包；该 Dio 实例独立（`webDavDioProvider`），不加 `LogInterceptor` —— 请求头里有密码。


## 工程能力

### 分析集成

```dart
final analytics = ref.watch(analyticsProvider);

// Log screen views
analytics.logScreenView('NoteListScreen', parameters: {'referrer': 'deeplink'});

// Log user actions
analytics.logUserAction(
  action: 'button_tap',
  category: 'engagement',
  label: 'new_note_button',
);
```

详情请参见[分析指南](https://jessejii.github.io/init/analytics.html)。

### 推送通知

本地通知 + 深链 + 权限申请：

> ⚠️ **与待办提醒不是一回事**：提醒走 `reminderSchedulerProvider`（`flutter_local_notifications` 的定时通知，见「待办」一节）；本节的 `notificationServiceProvider` 是**推送**抽象，当前实现是 Debug 空壳。

```dart
final service = ref.watch(notificationServiceProvider);

final status = await service.requestPermission();

await service.showLocalNotification(
  id: 'note-123',
  title: '笔记已保存',
  body: '你的修改已同步',
  action: '/notes/123',
  channel: 'notes',
);
```

### 功能开关

运行时开关，用于 A/B 测试与分阶段发布。默认值集中在 `core/feature_flags/feature_flag_providers.dart` 的 `kDefaultFeatureFlags`：

```dart
if (ref.watch(featureFlagProvider('enable_dark_mode', defaultValue: true))) {
  // 深色模式入口
}
```

也可用 `FeatureFlag` widget 按开关挂载子树。详情请参见[功能开关指南](https://jessejii.github.io/init/feature_flags.html)。

### 路由

`core/router/app_router.dart` 是唯一的 `routerProvider`：`StatefulShellRoute.indexedStack` + `NotesShell` 承载 `/notes`、`/todos` 两个 Tab（切 Tab 不丢列表状态），二级页（`/notes/new`、`/notes/folders`、`/notes/trash`、`/notes/:id`、`/settings`、`/settings/theme`、`/settings/data`、`/settings/webdav`、隐私政策、用户协议）一律挂 `_rootNavigatorKey` 整屏覆盖。

> ⚠️ **注册顺序是硬约束**：`new` / `folders` / `trash` 必须注册在 `:id` 之前，否则会被当作笔记 id 吃掉。
> 路径常量只在 `AppRoutes`（唯一 SoT，`initial = '/notes'`）。router 里**不 watch** `persistentLocaleProvider`——会重建 GoRouter 并清空导航栈，语言由 `main.dart` 的 `MaterialApp.locale` 负责。

### 本地持久化

`drift`（SQLite：笔记 / 文件夹 / 待办）通过 `appDatabaseProvider`（`core/providers/database_providers.dart`）注入；设置偏好用 `shared_preferences`。**改表后必须跑 build_runner**。

导出 / 导入 / 同步**不改表、不动 schemaVersion** —— 快照是应用层的 JSON，它的 `version` 与数据库的 `schemaVersion` 是两件事。

### 高级图片处理

支持缓存、SVG、特效和占位图的图片加载方案。

详情请参见[图片处理指南](https://jessejii.github.io/init/image_handling.html)。

### 多语言支持

中英双语，取文案用 gen-l10n 生成的**强类型 getter**（key 一律 snake_case），不存在 `context.tr()`：

```dart
Text(AppLocalizations.of(context).note_title);
// 带参数的消息是生成的方法
Text(AppLocalizations.of(context).item_count(count));
```

日期 / 时间 / 货币用 `context.formatDate/formatTime/formatDateTime/formatCurrency` 扩展。

详情请参见[本地化指南](https://jessejii.github.io/init/localization.html)。

### 两级缓存

内存 + 磁盘两级缓存：

```dart
final cacheManager = ref.watch(userDiskCacheProvider);
await cacheManager.setItem('note_1', noteEntity);
```

### 主题

自建 design token：颜色 / 字阶走 `ThemeExtension`（`core/theme/tokens/` 的 `AppColors`、`AppTextStyles`），间距 / 圆角 / 阴影走常量（`AppSpacing`、`AppRadius`、`AppElevation`）。

色板由 **flex_color_scheme** 从配色方案的主色派生（`FlexSchemeColor.from` + `FlexKeyColors` + `surfaceMode` 混合），主题按「明暗 × 配色方案」缓存（`AppTheme.light(scheme)` / `dark(scheme)`）。两个维度**正交**：`AppSettings.themeMode`（浅色 / 深色 / 跟随系统）管亮度，`AppSettings.colorScheme`（琥珀 / 蓝 / 绿 / 紫）管强调色，各自持久化、互不覆盖，都在 `/settings/theme` 主题页上选。

```dart
return MaterialApp(
  theme: AppTheme.light(colorScheme),
  darkTheme: AppTheme.dark(colorScheme),
  themeMode: themeMode, // 来自 settingsProvider，main.dart 做 AppThemeMode → ThemeMode 映射
);
```

> ⚠️ `flex_color_scheme` 内部 import 的是 `package:material_ui`（与本项目的 material_ui fork 同源），因此 `FlexThemeData` 返回的就是 material_ui 的 `ThemeData`，无类型冲突。

### 应用更新

`updateServiceProvider` 检查更新与强制更新，`main.dart` 中 `UpdateChecker` 包裹 `MaterialApp.router`。
