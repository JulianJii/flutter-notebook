# 待设计确认清单（Open Design Questions）

设计稿（`UI-IMPLEMENTATION-SPEC.md` / D1~D5 / `ARCHITECTURE-DESIGN.md`）没有覆盖的地方，实现时一律**不造视觉**、留一个 `Q` 编号。本文件是这些编号的**唯一台账**——代码里只留一行指针（`// Q21 → docs/OPEN-DESIGN-QUESTIONS.md`），理由与升级路径只写在这里，避免同一件事散成几十段注释。

规则：

- **拿到稿就改实现**，改完把该行从本表移到「已定稿」小节。
- **新增无稿决策**先在本表登记，再在代码里写指针，不要只在代码里留 TODO。
- 生成器模板（`lib/core/cli/feature_generator.dart`）里的 `// TODO: 实现 …` 是**新 feature 脚手架占位**，不属于本表。

## 待确认

| Q | 问题 | 现状决策 / 升级路径 |
|---|---|---|
| Q11 | D4 文件夹行无重命名 / 删除入口，顶栏 trash 语义未知 | 入口已在 `FolderManagerScreen` 落地（P4 独立页），顶栏 trash 保持删除全部；语义待稿确认后校准图标 |
| Q13 | 输入类弹窗（新建文件夹 / 新建待办 / 编辑待办）视觉无稿 | 统一 `showDialog` + Material 默认 `AlertDialog`；补稿后只改弹窗构造处 |
| Q14 | 二级页（弹层、笔记列表的列表模式）视觉无稿 | 弹层沿用 Material 默认；列表模式按「宫格同一张 `NoteCard` 单列通栏」实现，补稿后只校排布 |
| Q18 | 分类 tab 顺序（全部恒首位 → 文件夹 `createdAt ASC` → 未分类恒最后）；「未分类」是否真实文件夹 | 顺序真相源在 `folder_dao` 的 `ORDER BY created_at ASC`，改顺序只改 DAO；「未分类」当前是筛选哨兵而非系统行 |
| Q19b | 瀑布流分列算法无稿 | 用 `MasonryGridView` 默认「更短列优先」，零自绘；补稿后再定 |
| Q20 | 卡片「无附加文案」是占位还是用户数据 | 占位文案；Q20 答后可能整条分支删除 |
| Q23 | 「35 字」统计口径无稿 | 剔除所有空白后按字符计（由 D3 反推）；补稿后只改 `WordCounter` |
| Q24 | 自动保存指示器无稿 | `NoteEditorState.isSaving` 保留但不写中间态（无消费方却多一次整页重建）；做指示器时在 `flush()` 加回 |
| Q25b | D4 未选中行没有 leading 图标，导致「全部」行名称左边界不齐 | `FolderRow` 传空槽保 32dp 对齐 |
| Q25c | 选中行是否需要底色高亮无稿 | 不加底色，靠琥珀勾区分；补稿后只改 `FolderRow` |
| Q26b | D5 只画了 Switch 的 off 态 | 沿用 Material 默认 on 态；补稿后只改 `AppTheme` 的 `switchTheme` |
| Q28 | SafeArea 按「非 edge-to-edge」实现是否正确 | `AppTopBar` / `NotesShell` 均已包 SafeArea；若改 edge-to-edge，此两处最先动 |
| Q29 | 深色模式配色表无稿 | `AppColors.dark()` 整体回落浅色值；补稿后只改这一个构造器 |
| Q31 | 空状态视觉无稿（P1 宫格 / P2 待办 / P3 详情 / 回收站） | 已落地的三处（回收站 / 待办 / 笔记搜索无结果）都是内联 `Center + Text(subtitle/textTertiary)`；⛔ 不抽 `AppEmptyView` |
| Q32 | 首屏读库的 Loading 视觉无稿 | 由 `AsyncValue` 承载 loading/error，UI 不额外画骨架屏 |
| Q33 | 读库 / 保存失败的用户可见反馈无稿 | 已落地：待办勾选失败、自动保存失败（`NoteEditorState.lastFailure`）→ `AppUtils.showSnackBar`。**未落地**：设置偏好保存失败（`_write` 是 fire-and-forget、state 不变 ⇒ 没有 UI 事件源；补反馈要新增 `lastFailure` 状态源，而偏好的可恢复路径只有「重启 App」，判定不值得） |
| Q34 | Snackbar / Toast / Dialog 整类视觉无稿 | 一律沿用既有 `AppUtils.showSnackBar` + Material 默认弹窗，不建 `AppDialog` / `AppBottomSheet` |
| Q35 | 全稿无按压态 / 禁用态 | 沿用 `IconButton` / `InkWell` 默认；补稿后按组件逐个校 |
| Q-§2.2 | §2.2 的 13 个字阶里没有「分组标题」这一级 | `AppSectionHeader` 暂取最接近的 `text.subtitle`（13sp / w400），按 D5 量取后修正该行 |
| Q-新 | 待办排序覆盖 D2 稿「本页无排序入口」 | 用户已确认覆盖：`TodoDao.watchAll` 的 `ORDER BY is_done ASC, created_at DESC`（未完成置顶 + 同组创建时间倒序），「已完成 N」折叠分组复用这条顺序 |

## 已定稿（本轮落地）

| Q | 结论 | 落点 |
|---|---|---|
| Q21 | 已完成态：卡片标题变灰 + 删除线；已完成项沉到列表底部「已完成 N」可折叠分组；顶栏可一键清除全部已完成（二次确认） | `TodoCard` / `todo_list_screen.dart` / `TodoDao.deleteCompleted` |
| Q1 | 笔记搜索落地：常驻搜索框 + `NoteQuery.searchTerm`（参数化 LIKE，非 FTS5） | `note_search_provider.dart` / `note_dao.dart` |
| Q33 | 自动保存失败不再静默：`NoteEditorState.lastFailure` + `clearFailure()`，详情页弹 Snackbar | `note_editor_provider.dart` / `note_detail_screen.dart` |

升级路径速查：搜索超过约 1 万条笔记且输入掉帧 → 加 250ms debounce 或改 FTS5；待办量到万级 → 再考虑清理乐观覆盖 map。