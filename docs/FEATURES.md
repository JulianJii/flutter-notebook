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
- **图片**：正文工具条右端的图片按钮 → 系统文件选择器（`file_picker`，`FileType.image`，支持多选）→ 在当前光标处插入。图片**不落文件系统**，而是 base64 的 data-URI 内嵌进 Quill 的 image embed（`NoteImage.embedData`），随 `notes.content` 一起落库 —— 因此不存在「笔记还在、图片没了」的悬挂引用。设置里「图片压缩」开启时（默认开），每张图都会先压成 JPEG（短边 1600px / quality 85，`flutter_image_compress`），不看原始大小；关掉则原图直嵌。
- **文件夹管理** `/notes/folders`：新建 / 拖拽排序 / **长按文件夹弹菜单删除**，显示每个文件夹的笔记数。删除入口是长按而非行内图标 —— `trailing` 已被拖拽手柄占满（`FolderRow` 有测试钉住布局），而多选态要新增一整套选中 UI。长按 → 底部菜单（⚠️ 视觉无稿，`showModalBottomSheet` 默认形态）→ 二次确认框 → 软删除进回收站。⛔ 仍**不提供重命名入口**：`renameFolderUseCase` 在库里有也有测试，但设计稿没有它的位置，无稿不画。
- **最近删除** `/notes/trash`：**笔记 / 文件夹 / 待办三类**，各自成段（`AppSpacing.lg` 的段标题，空段整个不渲染），不使用 TabBar —— 回收站量级是「几十条」，翻页比滚动慢，而 TabBar 要新增选中态与切换逻辑，零收益。每行两个动作：恢复 / 永久删除（均二次确认）。顶栏「清空」跨三类依次清空，**不是事务**（三类分属三个 feature，没有共同事务）：任一步失败就停下报错，绝不报「已清空」。
- **回收站里的永久删除 = 物理删**，不跨设备传播（见「已知限制」）。恢复文件夹时若原名已被占用，返回 `InputFailure` 并**保留让出版** —— 不悄悄改名，用户要恢复的是原文件夹不是一个同名的空壳。

> 筛选是 `sealed NoteFolderFilter` 三态；列表由 `StreamProvider.family(NoteQuery)` 驱动，筛选 / 排序变化即自动重查。

> ⚠️ **图片内嵌的三条代价**（用户选择带来的天花板，不是 bug）：① 正文比二进制原图大 ~1/3；② 每次按键是全量序列化整份 Delta（`_onContentChanged`），带若干张图的长笔记上会出现卡顿 —— 真到那天再换成 `controller.changes` 增量合并 + debounce；③ 单张上限 10MB、一次最多 20MB（`NoteImage` 里的常量），超限直接拒绝并提示。列表摘要走 `NoteDelta.plainText`，它跳过 embed，图片不会变成乱码。

### 待办（`lib/features/todos/`）

新建、编辑、勾选完成（完成态灰字删除线）、删除（二次确认，**软删除进回收站**）；未完成置顶，已完成沉入可折叠的「已完成 N」，顶栏可一键清除全部已完成（也是软删除，所以跨设备能传播）。排序真相源在 `TodoDao.watchAll` 的 `ORDER BY is_done ASC, created_at DESC` + `WHERE deleted_at IS NULL`。

- **点卡片 → 详情小窗**（`todo_reminder_sheet.dart`）：只读标题 + 提醒时间 + 完成；标题旁的铅笔回落到原来的编辑弹窗（改标题 / 删除只有一个入口）。
- **提醒**：小窗里点时钟图标 → 从下往上弹「设置提醒时间」（内置 `showDatePicker` / `showTimePicker`，⛔ 无农历）。确定后由 `todoReminderProvider` **先落库 `reminder_at` 再注册系统通知**（`flutter_local_notifications`），清除则反过来先取消通知。没授予通知权限时不落库 —— 存了也提醒不了。

| 入口 | 位置 |
|---|---|
| `todoReminderProvider` | `features/todos/presentation/providers/todo_reminder_provider.dart`（编排：落库 + 调度） |
| `reminderSchedulerProvider` | `core/notifications/reminder_scheduler.dart`（平台通知的唯一出入口） |

> ⚠️ 通知 id 由 `todo.id.hashCode` 掩码到 31 位派生，不另存列；**不做**重复提醒、不做重启后恢复（重启后已设的提醒不会响）。

### 设置（`lib/features/settings/`）

笔记字号、默认排序、列表布局、深色模式（跟随系统 / 浅色 / 深色）、**图片压缩**（见上「图片」）、最近删除入口、隐私政策 / 用户协议、**关于**（`/settings/about`：版本号 + 检测更新 + 仓库主页 + 开源许可）。偏好持久化在 SharedPreferences，由 `settingsProvider` 承载。

「数据与同步」行是进入 `features/backup/` 的跳转入口（见下节），不把 WebDAV 配置并进 `AppSettings` —— 那是「App 长什么样」的偏好，凭据是另一回事。

### 数据与同步（`lib/features/backup/`）

导出 / 导入 / WebDAV 三个动作共用**同一份快照模型** `BackupSnapshot`（`notes` + `note_folders` + `todos` 三表全量，**含回收站里的软删除行**）：

| 动作 | 链路 |
|---|---|
| 导出 | 读全量 → JSON → 写临时文件 → 系统分享面板（存到哪由用户自己选） |
| 导入 | 文件选择器选 `.json` → 按 id 合并进本地 |
| 同步 | `GET` 远端快照 → 与本地合并 → `PUT` 回去 → 合并结果落本地 |
| 历史版本 | 配置页 → 历史版本 → 列 `history/index.json` → 「找回内容」合并回本地 |
| 局域网同步 | 设置 → 局域网同步 → 打开「允许被连接」→ 另一台设备在同一 WiFi 下发现它 → 点「同步」 |

**合并规则只有一条**：逐条比 `max(updatedAt, deletedAt ?? 0)`，新的赢，一样新保留本地（避免无意义写库）。**三类实体共用这个键**（`BackupNote/Folder/Todo.version`）—— 软删除也是一次变更，所以删除靠墓碑跨设备传播，不会被一条更晚的编辑复活。

- 「永不丢数据」体现在**软删除**上：`note_folders` / `todos` 从 v6 起也有 `deleted_at`（此前两者是硬删除，A 机删掉的待办会在 B 机下次同步时原样回来）。合并仍是**并集**，只增不物理删。
- ⚠️ **回收站的「永久删除」是物理删，不跨设备传播** —— 合并是并集，没有墓碑就没有「该删掉」这个信息。同理，恢复文件夹**不会**把当初落入未分类的笔记移回去（软删除时 `folder_id` 已被显式置 NULL，不留痕迹）。见下方「已知限制」。
- 同步是**单文件快照**，不是增量队列：`GET` 到 404 就当「远端还没文件」，等价于首次推送。因此不需要冲突状态机 —— 模板自带的离线变更队列（`offline_sync_service` / `connectivity_plus`）未接线，已整体移除。
- 快照有自己的 `version`（当前 **2**），高于它的直接拒绝导入，不静默降级解析。v1 快照（无 `deletedAt`）照读 —— v2 只加字段不改语义，老备份导入后全视为未删除。
- ⚠️ **写回时不能漏列**：`BackupLocalDataSource._writeTodos` 用 `insertOrReplace`，而 SQLite 的 `INSERT OR REPLACE` 是 DELETE+INSERT，**未列出的列取默认值**。漏写 `reminder_at` 或 `deleted_at` 不是「不同步」，而是每次同步把提醒时间清零 / 把已删行复活一批。`backup_merge_test` 钉住了这三列的往返。
- **历史版本**（`/settings/webdav/history`）：同步**覆盖远端之前**的那份会被存进 `history/`，保留最近 20 条。三个设计点：
  - **只在「内容真的变了」时归档** —— 判据是快照三张表的 sha256 **内容指纹**，⛔ 不是整份 JSON 的哈希：`BackupSnapshot.merge` 每次都把 `exportedAt` 重写成 `DateTime.now()`，按整份 JSON 比会让**每次空同步都归档一次**，配额几天耗光。
  - **索引文件而非 PROPFIND 列目录**：`history/index.json` 是一份普通的 GET/PUT JSON，完全复用已跑通的传输，零新依赖、零服务器差异（PROPFIND 的 `207 Multi-Status` 在 nginx / Apache / Nextcloud / Synology 上格式各不相同，要引 XML parser 容忍差异）。
  - **先传文件、后写索引**：索引是**指针**、文件是**数据**，反过来会让索引短暂指向不存在的文件。代价是「文件传成功、索引写失败」多一个孤儿文件（用户无感），比「索引指向空气」好。
- **局域网设备间同步**（`/settings/lan`）：两台设备在同一 WiFi 下**一次往返即收敛**，顺带完成一次对时。零新依赖（`dart:io` 的 `HttpServer`/`HttpClient`/UDP）。
  - **协议**：`POST /sync`，请求带自己的全量快照 + `clientTime`，响应回**同一份**合并结果。**两端写同一个值 → 一轮 RTT 收敛**，不需要第二阶段或确认帧。
  - **对称**：没有「主机 / 客户端」之分，任何一端都能开服务也能主动连别人。`POST` 时随机端口（避免撞端口），端口由发现信标广播出去。
  - **发现是 UDP 广播信标**（每 2 秒一次，47653 端口），⛔ **不是 mDNS**：`multicast_dns` 只会「查」不会「发布」（源码里没有应答编码器，`MDnsClient` 也没有注册服务的 API），要用它就得手写 DNS 应答包 + Android `CHANGE_WIFI_MULTICAST_STATE` + iOS `NSBonjourServices`，而组播在公司 WiFi / 访客网络 / 省电模式下照样不通。
  - **对时是顺带的**（NTP 式三采样 `((t1-t0)+(t1-t2))/2`）：缺的 t0/t2 都在本机，不额外往返。⚠️ 只有**发起方**会被拉动 —— 两端互拉会让偏差越滚越大。
  - **离开「局域网同步」页就停止服务**：服务端开着等于把全部笔记对同网段开放，不该在用户退出该页后继续。
  - ⚠️ **广播被路由器丢弃时搜不到设备** —— 页面同时提供「手动输入地址」（IP + 端口）兜底。
- WebDAV 客户端是 **dio 手搓**的（`GET` / `PUT` / `MKCOL` / `PROPFIND` / `DELETE` + Basic Auth），不引第三方包；该 Dio 实例独立（`webDavDioProvider`），不加 `LogInterceptor` —— 请求头里有密码。


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

**切换语言**：设置 → 其他 →「语言」，三档 —— **跟随系统**（默认）/ 中文 / English。改完立即生效，
选择落在 `SharedPreferences` 的 `selected_language_code`；没选过就是「跟随系统」，取系统语言，
系统语言不是中英文时回落中文。

> 语言的**唯一真源**是 `core/providers/localization_providers.dart` 的
> `persistentLocaleProvider`（`Locale?`，null = 跟随系统）与派生的 `appLocaleProvider`
> （已解析、可直接上屏）。⛔ `AppSettings` 里**没有**语言字段 —— 两份偏好表达不出「跟随系统」。

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

最新版本来自 **GitHub Release**：`updateServiceProvider` → `UpdateService` 拉
`.../repos/{owner}/{repo}/releases/latest`，用 Release 的 `tag_name`（剥掉 `v` 前缀）
和 `PackageInfo.version` 比大小，下载页是 Release 的 `html_url`（`url_launcher` 交给浏览器）。
仓库地址在 `AppConstants.githubOwner` / `githubRepo`（当前 `JulianJii/flutter-notebook`）。

| 入口 | 行为 |
|---|---|
| 启动 | `main.dart` 的 `UpdateChecker` 查一次，有新版才弹窗（`autoPrompt`） |
| 关于页 | 设置 → 其他 →「关于」→ 点「检测更新」手动查，结果显示在按钮下方 |

> ⚠️ 弹窗用 `rootNavigatorKey.currentContext`：`UpdateChecker` 在 `MaterialApp` **之上**，自己的 context 没有 Navigator 也没有 Localizations。
> ⚠️ 未认证的 GitHub API 限 60 次/小时/IP，超限按「检查失败」处理，不做缓存。
> ⚠️ 版本号真源是 `pubspec.yaml`，发版时它必须和 Release tag 对得上，否则会一直提示更新。
> ⚠️ 应用没上架商店、无自建分发，因此**没有强制更新**（`criticalUpdateRequired` 不会出现）。

## 已知限制

用户选择 / 架构现实带来的天花板。**不是 bug**（要么有意如此，要么代价高于收益），所以没有修的排期；真到了要修的那天，从这里删掉对应条目。

### 备份与同步

- **回收站的「永久删除」是物理删，不跨设备传播。** 合并是并集，没有墓碑就没有「该删掉」这个信息 —— A 机永久删除的笔记/待办/文件夹会在 B 机下次同步时回来。要闭环得给物理删除也留墓碑表，代价是一张新表 + 快照字段 + 一套回收期（墓碑留多久）策略。
- **恢复文件夹不会把当初落入「未分类」的笔记移回去。** 软删除时 `folder_id` 被显式置 NULL（外键 `ON DELETE SET NULL` 在软删除下不触发），不留痕迹，所以恢复时无从知道该把哪些笔记移回去。笔记本身没丢，就在未分类里。
- **文件夹重名跨设备会改名而不是丢弃。** `note_folders.name` 是 UNIQUE，两台设备各建一个「工作」必然撞约束 —— 同步时后者被改成「工作 (2)」。「永不丢数据」优先于「名字必须原样」。
- **UDP 广播发现会被网络屏蔽。** 路由器关闭广播转发、AP 隔离、公司 / 访客 WiFi 都可能让两台设备互相看不见。页面提供「手动输入地址」（IP + 端口）兜底；端口由服务端随机（避免撞端口），从对方屏幕上看不到时需要让对方在信标里报出来 —— ⛔ 当前 UI **不显示**本机端口，所以这条兜底路径实际需要用户从对方那里问到端口。真要用起来，把「允许本机被连接」下面那行改成显示 IP:端口即可。
- **合并键依赖设备时钟。** 比较键是 `max(updatedAt, deletedAt)`，走的是各设备自己的墙上时钟。时钟偏差会**静默**覆盖数据：快的那台赢。缓解手段是落库时间戳统一走 `AppClock.appNow()`，局域网同步握手时按 NTP 式三次采样算出偏差并写入 offset（重启后仍生效）；**但偏差只在同步那一刻刷新一次**，之后不再校正，彻底解决要改成逻辑时钟 / 修订号（每行加 `revision` + `deviceId`，并给所有写路径打戳），代价是改表 + 三条 DAO 全过一遍。
  - `AppClock` **只影响写入时间戳的取法**：日志、动画、「15 分钟前」这类相对时间显示仍用系统时钟；待办的 `reminder_at` 也仍是系统时钟（它是对用户展示的本地时刻，不是同步键）。
  - `BackupLocalDataSource` 写回路径**刻意不走** `appNow()`：那份时间戳来自对端，重打本地戳会让每条合并进来的记录都变成「刚刚编辑过」，合并静默退化成「本地全胜」。
  - `test/core/utils/app_clock_usage_test.dart` 扫源码守住这条边界 —— 新加写路径时用了 `DateTime.now()` 没有任何编译期信号，只能靠它。
- **同一秒内的删除与编辑会打平，按「保留本地」处理。** drift 把 `DateTime` 按**秒**存，所以「A 机删除 / B 机同时编辑」时两个键相等，规则是保留本地 —— 编辑赢、删除没赢。
- **快照体积上限挡不住流式响应。** 上限（64M 码元）守在解码处，能拦住误选的大文件与已落盘的坏文件；但 WebDAV `GET` 用的是 `ResponseType.plain`，一个损坏/恶意的服务器可以在上限被检查之前就把响应 buffer 完。要真正防住得改 `ResponseType.stream` + 手动计数。
- **全量同步，没有增量。** 每次同步都是整库 GET + PUT。笔记多了会很慢且费流量 —— 但快照本身可 gzip（内容是 base64 图片，压缩比可观），先压了再说。真嫌慢再上变更日志表。
- **单文件快照，历史存成多文件。** 远端当前状态只有一份（`remoteFile`），历史在 `history/` 下轮转。误同步后可以从历史「找回内容」，但找不回的是「回到当时的状态」—— 见下条。
- **历史版本的「找回」不是「回滚」。** 走的是与文件导入完全相同的合并路径，而删除传播的墓碑比任何历史版本都新，所以**当时被删掉的内容不会回来**。UI 确认框里明说了这件事，不是免责声明而是语义边界。要真回滚就得把墓碑也回退，那会真丢数据。
- **历史索引可能与文件不一致。** 版本上传成功但索引 PUT 失败时会留下一个用户看不见的孤儿文件。不做对账修复：后果是历史少一条，不会损坏数据，而自愈要写「逐个探测文件是否存在」的对账扫描。

### 凭据与传输

- **局域网同步没有任何认证。** 同网段任何设备都能读写你的全部笔记。这是知情选择（局域网内可信、不设口令），不是疏漏。UI 上有一行常驻的明文提示。

- **WebDAV 密码明文落 SharedPreferences。** 本 App 无账号体系、无后端，设备本地存储已被系统沙箱保护；为它引入 keychain / 加密是给一个本地 App 上锁自己的门。
- **WebDAV 走明文 HTTP 时同网段可嗅探。** Basic Auth 只是 base64，笔记内容以 JSON 明文过网 —— 信任局域网内其他设备。Android 侧放行明文（`network_security_config.xml` 的 `base-config`），iOS 侧只放行私网与 `.local`（`NSAllowsLocalNetworking`，没上 `NSAllowsArbitraryLoads`），所以**公网 http 的 WebDAV 在 iOS 上会被拦、Android 上能通** —— 有意的不一致，iOS 侧更安全也更好过审核。

### 通知

- **待办提醒在设备重启后不重排。** 已设的提醒重启后不会响（没有 boot receiver，也没有全量重排 sweep）。`ReminderScheduler` 刻意只做「设 / 撤」两个动作。
- **软删除待办不撤掉已排的通知。** 进回收站只是写 `deleted_at`，平台侧通知仍会响；只有删除路径（`TodoListScreen._cancelReminder`）会撤 —— 包括「清除全部已完成」，那条路径逐条撤销，否则批量删会漏掉多条通知。
- **恢复待办不重排已撤掉的通知。** `reminder_at` 一直留在行上，但系统侧那条在删除时已被撤掉；恢复后要继续提醒得重新设一次。
