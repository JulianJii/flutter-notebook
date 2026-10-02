# 笔记 App 产品规格（交付 AI Coding Agent 用）

> 状态：产品规划阶段，**不写代码**。
> 假设（待确认，见文末 Q1）：个人向、本地优先（local-first）的笔记 App，Markdown 原生，快速记录为第一优先级，不做多人协作。

---

## A. 产品概述

**一句话定位**
一个本地优先、Markdown 原生的个人笔记 App：打开 2 秒内能写下第一段字，之后才谈组织、搜索和同步。

**设计原则（用于砍功能）**

1. **记录优先于整理**：新建笔记的路径必须最短；文件夹/标签永远是"事后可选"，不是新建必填。
2. **本地优先**：无网络、无账号也能完整使用；云同步是增强，不是前提。
3. **Markdown 是事实来源**：存储以 Markdown 为准，渲染只是视图。不做私有二进制富文本格式。
4. **永不丢数据**：自动保存、软删除、导出通道三条兜底。
5. **一个模块一件事**：每个功能模块可独立交付、独立验收、独立回滚。

**明确不做（避免范围膨胀）**
多人协作 / 实时协同编辑 / 笔记分享链接 / 评论 / 团队空间 / 脑图画布 / 块级引用网络（双向链接图谱）/ 自建同步服务器运维。

**平台**：MVP 仅 iOS + Android（桌面/平板自适应布局在 P7 打磨）。

---

## B. 功能树

模块编号即 Agent 任务编号：`一次只实现一个模块`。每模块的验收标准见 B.10。

```
笔记 App
├─ 1. 基础基建 INF
│   ├─ INF-01 本地数据库骨架（drift + 迁移框架 + databaseProvider）
│   ├─ INF-02 应用设置与偏好（外观/默认排序/默认新建位置）
│   ├─ INF-03 路由与外壳（GoRouter + 主壳 + 侧边抽屉）
│   └─ INF-04 通用 UI 件（笔记列表项、空态、骨架屏、确认弹层）
├─ 2. 笔记核心 NOTE
│   ├─ NOTE-01 Note 实体 + drift 表 + Repository（CRUD）
│   ├─ NOTE-02 笔记列表页（排序：修改时间/创建时间/标题；置顶分组）
│   ├─ NOTE-03 Markdown 编辑器（编辑态 + 工具栏 + 预览切换）
│   ├─ NOTE-04 自动保存（去抖 + 生命周期保存 + 崩溃兜底）
│   ├─ NOTE-05 阅读视图（Markdown 渲染 + 代码高亮 + 图片）
│   ├─ NOTE-06 置顶 / 收藏
│   ├─ NOTE-07 删除与回收站（软删除 / 恢复 / 彻底删除 / 到期清理）
│   └─ NOTE-08 笔记信息面板（字数、创建/修改时间、所属位置）
├─ 3. 组织 ORG
│   ├─ ORG-01 文件夹 CRUD（MVP 单层，见 Q3）
│   ├─ ORG-02 移动笔记到文件夹（选择器 + 批量）
│   ├─ ORG-03 标签 CRUD（名称 + 颜色）
│   ├─ ORG-04 笔记打标签（多选选择器）
│   └─ ORG-05 组合筛选（文件夹 + 标签 + 收藏）
├─ 4. 搜索 SRCH
│   ├─ SRCH-01 全文搜索（FTS5 + 关键词高亮 + 结果片段）
│   └─ SRCH-02 搜索历史与快捷筛选 chips
├─ 5. 快速记录 CAP
│   ├─ CAP-01 全局快速新建（悬浮按钮 + 键盘快捷键）
│   ├─ CAP-02 外部分享导入（系统分享文本/链接进来直接建笔记）
│   └─ CAP-03 模板与待办清单（P2）
├─ 6. 媒体 MED
│   ├─ MED-01 插入图片（相机/相册 → 本地存储 → Markdown 引用）
│   └─ MED-02 附件治理（孤立文件清理 + 占用统计）
├─ 7. 数据与隐私 DAT
│   ├─ DAT-01 导出（单篇 Markdown / 全量 zip）
│   ├─ DAT-02 导入（Markdown 文件或 zip）
│   ├─ DAT-03 App 锁（复用 core/auth 生物识别）
│   └─ DAT-04 版本历史（快照 + 回滚，P2）
├─ 8. 同步 SYNC
│   ├─ SYNC-01 账号（复用 features/auth）
│   ├─ SYNC-02 同步引擎（增量拉取/推送 + 冲突检测）
│   ├─ SYNC-03 离线队列（复用 offlineSyncServiceProvider）
│   └─ SYNC-04 冲突解决 UI（并排对比 + 保留任一/保留两份）
├─ 9. AI 辅助 AI
│   ├─ AI-01 AI 配置（开关 / 模型 / Key，默认关闭）
│   ├─ AI-02 单篇 AI 动作（摘要 / 润色 / 生成标题 / 翻译）
│   ├─ AI-03 结果采纳 UI（插入 / 替换 / 丢弃）
│   └─ AI-04 语义搜索（本地 embedding，P3）
└─ 10. 体验打磨 UX
    ├─ UX-01 深色模式与字号（已有主题基建）
    ├─ UX-02 多语言（已有 l10n）
    ├─ UX-03 平板 / 桌面自适应（双栏列表 + 编辑）
    ├─ UX-04 桌面小组件与快捷方式（长按图标"新建笔记"）
    └─ UX-05 无障碍与动态字号
```

### B.10 模块验收标准（示例，其余同构）

| 模块 | 验收标准（可测） |
|------|------------------|
| NOTE-01 | `createNote` 返回 `Either<Failure, Note>`；无网络可写入并读出；单元测试覆盖成功 + 失败路径 |
| NOTE-03 | 输入 1 万字不卡顿；工具栏插入 `#`、`**`、`- [ ]` 光标位置正确；切预览不丢内容 |
| NOTE-04 | 停止输入 800ms 内落库；`AppLifecycleState.paused` 时强制保存；杀进程重启内容不丢 |
| SRCH-01 | 1 万篇笔记下首字响应 < 300ms；命中关键词高亮；标题命中排序高于正文命中 |
| NOTE-07 | 删除进回收站可恢复；彻底删除二次确认；30 天到期自动清理（后台任务） |
| SYNC-02 | 断网编辑 → 联网自动同步；双端同改触发冲突且不丢任何一方 |

---

## C. 页面地图

```
Splash
 └── AppShell（底部/侧边导航容器）
      ├── HomePage 笔记列表（默认落地页）
      │     ├── SearchPage 搜索（顶部入口，覆盖式）
      │     ├── FolderPage 文件夹内容（ORG-01/02）
      │     ├── TagPage 标签内容（ORG-03/04）
      │     ├── FavoritesPage 收藏
      │     └── TrashPage 回收站
      ├── EditorPage 编辑器（新建 / 编辑，含预览切换）
      │     └── InfoSheet 笔记信息面板（底部弹层）
      ├── MoveToFolderSheet / TagPickerSheet（底部弹层选择器）
      ├── SettingsPage 设置
      │     ├── 外观（主题/字号）
      │     ├── 数据与导出（DAT-01/02）
      │     ├── 隐私与 App 锁（DAT-03）
      │     ├── 同步与账号（SYNC-01，未登录跳 LoginPage）
      │     └── AI 设置（AI-01）
      └── LoginPage（P6 同步阶段才出现）

外部入口 → 系统分享 → QuickCapturePage（CAP-02，无壳极简页）
冲突 → ConflictResolvePage（SYNC-04，仅在检测到冲突时进入）
```

**页面关系约束**

- `EditorPage` 是全屏路由，可从 Home / Folder / Tag / Search / 分享入口 / 小组件进入，参数统一为 `noteId?`（空则新建）。
- 列表类页面（Home/Folder/Tag/Favorites/Trash）共用 `NoteListWidget`，仅数据源不同 → 只写一个列表组件。
- 回收站不是普通列表：默认操作是"恢复/彻底删除"，不能编辑内容。
- 平板/桌面（UX-03）：Home 与 Editor 同屏双栏，路由不变，只是壳布局切换。

---

## D. 主要用户流程

**D1 快速记录（最高频，必须最短）**
悬浮按钮 / 小组件 / 分享 → EditorPage（光标自动聚焦，标题取首行）→ 打字 → 返回即保存。

**D2 二次编辑**
列表点击 → 阅读视图或编辑态（取决于设置）→ 编辑 → 自动保存 → 返回列表（列表项时间与摘要更新）。

**D3 整理**
列表多选 → 移动文件夹 / 打标签 / 置顶 / 收藏 → 列表刷新。

**D4 检索**
搜索入口 → 输入 → 实时结果（高亮片段）→ 点击进编辑 → 返回时保留搜索上下文（不丢结果页）。

**D5 误删恢复**
列表删除 → 软删除进回收站 → 回收站恢复 → 回到原文件夹/标签。

**D6 数据迁移（导出/导入）**
设置 → 导出全量 zip → 换机 → 导入 zip → 合并（同 id 覆盖，冲突保留两份）。

**D7 同步（P6）**
登录 → 首次全量同步 → 后台增量同步 → 冲突时进入 ConflictResolvePage → 解决后继续。

**D8 AI 辅助（P7）**
编辑页选中/整篇 → AI 动作 → 流式结果 → 采纳（插入/替换）或丢弃 → 计入历史。

---

## E. 数据模型概览

| 实体 | 关键字段 | 说明 |
|------|---------|------|
| `Note` | id(uuid)、title、content(markdown)、plainText(检索/摘要用)、folderId?、isPinned、isFavorite、createdAt、updatedAt、deletedAt?、syncState、remoteId?、revision | 标题由首行派生，可为空 |
| `Folder` | id、name、sortOrder、createdAt、deletedAt? | MVP 单层，无父子 |
| `Tag` | id、name(唯一)、colorValue | |
| `NoteTag` | noteId、tagId | 多对多关联表 |
| `Attachment` | id、noteId、localPath、type(image/file)、size、createdAt | 内容里以相对路径引用 |
| `NoteRevision` | id、noteId、content、createdAt（保留最近 N 条） | DAT-04 |
| `SyncQueueItem` | id、entityType、entityId、op(create/update/delete)、payload、retryCount | 复用离线同步框架 |
| `SearchHistory` | keyword、createdAt | SRCH-02 |
| `AppSettings` | themeMode、fontScale、sortBy、defaultFolderId?、editorDefaultMode、aiEnabled | 单条记录表 |
| `UserProfile` | id、email、tokenRef、lastSyncAt | P6，复用 features/auth |

**索引与检索**：`notes_fts` 虚拟表（FTS5）同步 title + plainText；`updatedAt`、`folderId`、`deletedAt` 建索引。
**删除语义**：所有删除为软删除（`deletedAt`），回收站视图 = `deletedAt != null`；到期清理走后台任务硬删。

---

## F. MVP 范围

目标：**一个离线可用、不会丢数据的个人笔记本**。

| 模块 | 说明 |
|------|------|
| INF-01~04 | 数据库骨架、设置、路由外壳、通用列表件 |
| NOTE-01~08 | 笔记 CRUD、列表、Markdown 编辑器、自动保存、阅读视图、置顶收藏、回收站、信息面板 |
| ORG-01~05 | 单层文件夹、移动、标签、打标签、组合筛选 |
| SRCH-01 | 全文搜索 + 高亮 |
| CAP-01 | 全局快速新建 |
| UX-01/02 | 深色模式、多语言（基建已有，主要是适配） |

**MVP 结束时的定义**：无账号、无网络，能写、能找、能整理、能恢复，导出一条 Markdown 不丢格式。

**边界外（MVP 明确不做）**：同步、AI、版本历史、App 锁、图片插入、模板、小组件。

---

## G. 第二阶段范围

| 模块 | 说明 |
|------|------|
| CAP-02 分享导入 | 系统分享文本/链接 → 直接建笔记 |
| CAP-03 模板与待办清单 | 常用模板、任务清单渲染 |
| MED-01/02 图片与附件 | 插入图片、孤立文件清理、占用统计 |
| DAT-01/02 导出导入 | 单篇 Markdown、全量 zip、导入合并 |
| DAT-03 App 锁 | 复用 `core/auth` 生物识别，冷启动/回前台校验 |
| SRCH-02 搜索历史 | 历史记录 + 快捷筛选 chips |
| UX-03 平板/桌面双栏 | 同路由，壳布局切换 |
| UX-04 小组件/快捷方式 | 一键新建 |

---

## H. 后续功能

| 模块 | 说明 |
|------|------|
| SYNC-01~04 | 账号 + 增量同步 + 离线队列 + 冲突解决 UI |
| AI-01~03 | AI 配置 + 摘要/润色/标题/翻译 + 采纳 UI |
| DAT-04 版本历史 | 快照与回滚 |
| AI-04 语义搜索 | 本地 embedding，检索"意思相近"而非关键词 |
| UX-05 无障碍与动态字号 | 屏幕阅读器标签、字号跟随系统 |

---

## I. 风险与技术难点

| 风险 | 影响 | 应对 |
|------|------|------|
| **编辑器体验**（最高） | Markdown 编辑器难做：光标、选区、工具栏、软键盘遮挡、大文档卡顿 | MVP 先用"纯文本 + 行内工具栏 + 预览切换"，不做所见即所得块编辑；大文档做分段渲染/懒加载 |
| **数据丢失** | 最高的产品风险，一次即毁口碑 | 自动保存去抖 + 生命周期保存 + 软删除 + 导出；写"杀进程恢复"用例 |
| **全文搜索性能** | 数据量大后卡顿 | drift + FTS5，异步查询 + 结果节流；不做实时全表扫描 |
| **离线同步冲突** | 双端改同一篇，处理不好就丢内容 | 版本号 + 冲突时保留两份，绝不静默覆盖；MVP 前不同步 |
| **数据库迁移** | 长期维护必然改 schema | INF-01 就把迁移框架和版本策略建好，后续每次 schema 变更必须带迁移测试 |
| **AI 成本与延迟** | 按次调用有成本、有延迟、结果不稳定 | 默认关闭、用户自带 Key、结果只做"建议"需用户采纳 |
| **范围膨胀** | 笔记类 App 极易功能蔓延 | 严格遵守 F/G/H 分层，新需求先对号入座再排期 |

---

## J. 推荐开发顺序

阶段内模块可并行，阶段间串行（后者依赖前者）。

```
P0 骨架      INF-01 → INF-02 → INF-03 → INF-04
P1 核心读写  NOTE-01 → NOTE-02 → NOTE-03 → NOTE-04 → NOTE-05
P2 组织      NOTE-06 → ORG-01 → ORG-02 → ORG-03 → ORG-04 → ORG-05
P3 检索      SRCH-01 → CAP-01
P4 安全兜底  NOTE-07 → NOTE-08 → UX-01 → UX-02        ← MVP 完成，可发版
P5 输入输出  CAP-02 → MED-01 → MED-02 → DAT-01 → DAT-02 → SRCH-02
P6 同步      SYNC-01 → SYNC-03 → SYNC-02 → SYNC-04
P7 智能      AI-01 → AI-02 → AI-03
P8 打磨      UX-03 → UX-04 → UX-05 → DAT-03 → DAT-04 → AI-04
```

**给 Agent 的执行约束**
1. 一次一个模块，完成即 `flutter analyze` + `flutter test` 全绿。
2. 每个模块按 `domain → data → presentation/providers → presentation/screens` 顺序落地，禁止跨层 import。
3. 新增/修改 `@riverpod`、`@freezed`、drift 表后必须 `dart run build_runner build --delete-conflicting-outputs`。
4. 每个 use case 至少覆盖成功 + 失败两条测试路径。
5. schema 变更必须带迁移，禁止删库重建。

---

## K. 待你决策的问题（决定前不进入实现）

| # | 问题 | 备选 | 建议 |
|---|------|------|------|
| Q1 | 定位是否就是"个人、本地优先、Markdown 原生"？还是有协作/团队诉求？ | 个人 / 团队协作 | 个人；协作会推翻整个 MVP |
| Q2 | 编辑器形态？ | a 纯 Markdown + 预览切换（快、稳）b 所见即所得块编辑（体验好、成本高 3~5 倍） | a；b 放 P8 之后单独立项 |
| Q3 | 文件夹层级？ | a MVP 单层 b 无限层级树 | a；树形带来移动/面包屑/循环校验一堆复杂度 |
| Q4 | 是否要富文本元素（表格、待办、代码块、@提及）？ | Markdown 扩展语法 / 不做 | MVP 支持代码块与任务清单渲染即可，表格后续 |
| Q5 | **图片插入是否进 MVP？** | 进 / 不进 | 建议不进（附件带来存储、清理、同步三重复杂度）；如你必须，挪到 MVP 末尾 |
| Q6 | 同步后端？ | 自建 API / Firebase / Supabase / 暂不同步 | 先定"暂不同步"，SYNC-01 时再选；协议按增量 + 版本号设计，后端可换 |
| Q7 | 回收站保留期？ | 30 天 / 7 天 / 永不自动清理 | 30 天，清理前可在设置里手动 |
| Q8 | 是否需要 App 锁 / 单篇加密？ | 无 / App 锁 / 单篇加密 | App 锁（P5，复用已有生物识别）；单篇加密成本高风险高，暂不做 |
| Q9 | AI 能力边界与成本承担？ | 用户自带 Key / 平台代付 / 不做 | 用户自带 Key，默认关闭 |
| Q10 | 平台范围？ | iOS+Android / +桌面 / +Web | iOS+Android；桌面在 P8 只做自适应布局，不做独立平台适配 |
| Q11 | 导入格式兼容哪些？ | Obsidian 库 / 纯 Markdown 文件 / 印象笔记导出的 .enex | 先纯 Markdown 文件；enex 是另一个量级的解析工作 |
| Q12 | 是否需要版本历史（可回滚）？ | 最近 10 条快照 / 不做 | 放 P8；MVP 靠回收站兜底已足够 |
