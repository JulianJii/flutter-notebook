# 响应式布局与桌面交互

设计稿只有手机竖屏一档，宽屏（Windows 窗口 / 横屏平板）的形态是后补的。
本文是这套形态的**唯一约定**：断点、各区域宽度、双栏的选中态、桌面交互。

## 断点

全部在 `lib/core/ui/app_breakpoints.dart`，⛔ 页面里不许再写 `600` / `1024` 字面量。

| 常量 | 值 | 含义 |
|---|---|---|
| `rail` | 600 | ≥ 用左侧导航栏，< 用底部导航 |
| `twoPane` | 1024 | ≥ 笔记页双栏（列表 + 右侧编辑） |
| `contentMaxWidth` | 840 | 二级页内容最大宽度 |
| `sheetMaxWidth` | 640 | 大屏底部弹层最大宽度 |
| `dialogMaxWidth` | 420 | 对话框最大宽度（写在 `AppTheme.dialogTheme`） |
| `railWidth` | 88 | 左侧导航栏宽度 |

读取方式：

- **在 `build` 里**：`context.usesNavRail` / `context.isTwoPane`（内部是
  `MediaQuery.sizeOf`，只订阅 size 一个 aspect）。
- **在回调里**（快捷键、`onTap` 之后）：`currentWindowWidth()`。⛔ 不要在
  build 之外用 `context.usesNavRail` —— 那会建立继承依赖，让调用方被动重建。

三档布局连续缩放时**单向收放**：三栏工作台 → 侧栏 + 单栏 → 手机。
切换只重排，不弹提示、不重置滚动位置。

## 导航

`NotesShell`（`core/shell/notes_shell.dart`）按 `usesNavRail` 二选一，
数据与回调完全共用（同一份 `AppBottomNavItem` + 同一个 `goBranch`）：

- `< 600`：`AppBottomNav`（64dp，底部安全区由它自己避让）。
- `≥ 600`：`AppNavRail`（88dp，选中项 = 白块 + 加粗文字，与分类 TabBar 同一套
  「灰底白块」语言）。**不渲染底部导航**。

⚠️ 页面里所有「为底部导航预留的空间」都必须读 `navBottomInsetOf(context)`
（FAB 定位、列表底部留白、多选动作栏三处）。宽屏它返回 0，直接用
`kBottomNavContentHeight` 会在 FAB 下面留一条 64dp 的空洞。

## 笔记双栏（≥ 1024）

```
┌──────┬─────────────────────┬──────────────────────────┐
│ 侧栏 │ 列表 380dp           │ 编辑画布 / 空态           │
│ 88dp │ 顶栏/搜索/分类/列表  │ 顶栏 + 限宽 760 的正文    │
└──────┴─────────────────────┴──────────────────────────┘
```

- 左栏：`NotesWideLayout.listWidth = 380`，内容原样复用 `NoteListScreen` 的
  单栏结构（顶栏 / 搜索 / 分类 TabBar / FAB / 多选动作栏），因此筛选、URL
  同步、多选**零改动**。
- 左栏**恒为单列列表**：380dp 里放宫格会把卡片挤成两张纸条。设置里的
  「列表布局」只在单栏（手机 / 中等宽度）生效。
- 右栏：`NoteEditorPane(embedded: true)`，与整页编辑是**同一份实现**
  （同一个 `NoteEditorProvider` family 实例，同一套自动保存）。

### 选中态不进 URL

`selectedNoteProvider`（`features/notes/presentation/providers/`）持有
「右栏是哪篇」，值是 `noteId` 或 `kNewNoteId`。

⛔ **不要把它写进 URL**：

- URL 已被 `?folder=` / `?tag=` 占用，分类 `TabController` 滑动时会重写它，
  再塞一个 `note=` 就得决定「切 tab 时保留还是丢弃」，等于造第二个真相源。
- 双栏是同一路由内的**布局变化**，不是导航；窄屏与深链仍走 `/notes/:id`
  整页路由，那边一个字都不用改。

行为对照：

| 场景 | 窄屏 | 宽屏双栏 |
|---|---|---|
| 点卡片 | `push('/notes/:id')` | `select(noteId)`，URL 不变 |
| 新建（FAB / `Ctrl+N`） | `push('/notes/new?folder=')` | `select(kNewNoteId)` |
| 全局搜索选中结果 | `push('/notes/:id')` | 当前在 `/notes` 时 `select(id)` |
| `Esc` | `maybePop` | 右栏有笔记 → 先落库再关面板 |
| 关闭右栏 | — | `flush()` 后 `clear()` |

### 草稿安全

切笔记 / 缩窗会销毁右栏的页面，`NoteEditor` 又是 `@riverpod`（autoDispose）。
因此 **dirty 期间 `ref.keepAlive()`**，`flush()` 成功后立刻释放
（`note_editor_provider.dart` 的 `_scheduleSave` / `_releaseKeepAlive`）。
关闭面板时仍显式 `flush()` —— 保活只保证「不丢」，不保证「立刻落库」。

⚠️ 落库责任在**外壳**（整页的 `_leave()` / 双栏的 `_closePane()`），
`NoteEditorPane` 自己不 flush：两处各存一次会真的发两次 update。

## 二级页与弹层

- 二级页 `Scaffold.body` 一律 `AppPageBody`（内部 = `SafeArea` + 840dp 居中）。
  它同时收掉安全区，所以每页只改一个词，不用手拼括号。
- 待办页用 `AppPageBody(maxWidth: 720)`：单列行超过 720 后，标题与右侧开关
  之间会空出一整屏。FAB 放在这层**之内**，跟随内容列贴右。
- 底部弹层一律 `showAppBottomSheet`（大屏 max 640 + 顶部 12dp 圆角；
  窄屏不传 constraints，保持 Material 原样）。
- 对话框宽度由 `AppTheme.dialogTheme.constraints` 统一限 420，调用点不用改。

## 桌面交互

- **悬停**：`AppColors.hoverOverlay`（浅 6% 黑 / 深 8% 白）。`AppCard` /
  `AppListTile` / `AppIconButton` / `AppNavRail` 都已接上。只在指针场景出现，
  窄屏与 golden 不受影响。
- **右键菜单**：`showNoteContextMenu`（`note_context_menu.dart`）在指针位置
  弹出「打开 / 置顶 / 收藏 / 移动 / 删除」。所有写操作复用**批量 use case**
  （传单元素列表），不另开单篇分支。多选模式下不弹。
- **窗口最小尺寸**：`setMinimumSize(760×560)`（`desktop_window.dart`）。
- **快捷键**：见 `docs/FEATURES.md`「桌面窗口」的表（含 `Ctrl+1/2`、
  宽屏下的 `Esc` / `Ctrl+S` / `Ctrl+N`）。

## 回归护栏

手机竖屏必须**逐像素不变**：新容器（限宽、悬停、面板）在窄屏都是零视觉影响
的包装，现有 golden 因此原样通过。改动断点或限宽后必须跑：

```bash
flutter analyze
flutter test                       # 含 24 张 golden
flutter test test/core/ui          # 断点 / 侧栏
flutter test test/features/notes   # 双栏
```
