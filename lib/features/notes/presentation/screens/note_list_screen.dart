import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/folder_with_count.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_query.dart';
import '../../providers/notes_providers.dart';
import '../providers/folder_provider.dart';
import '../providers/note_editor_provider.dart' show kNewNoteId;
import '../providers/note_list_provider.dart';
import '../providers/note_prefs_provider.dart';
import '../providers/note_search_provider.dart';
import '../providers/note_selection_provider.dart';
import '../providers/selected_note_provider.dart';
import '../widgets/folder_picker_sheet.dart';
import '../widgets/note_card.dart';
import '../widgets/note_context_menu.dart';
import '../widgets/note_masonry_grid.dart';
import '../widgets/notes_wide_layout.dart';
import '../widgets/tag_filter_sheet.dart';

/// 笔记列表。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// **两条设置偏好都在这里落地**：
/// `noteSort` 进 [NoteQuery]、`noteLayout` 选排布。两者都经 provider 读，改完设置
/// 回来即生效，不重启 App；⛔ **一律不进 URL**（偏好不是导航状态）。
///
/// **分类栏与左右滑动用官方组件**（本页新增）：分类栏 = [TabBar]，内容 =
/// [TabBarView]，两者共用一个 [TabController] —— 点 tab、左右滑、写 URL 三件事
/// 由官方组件同一套 index 驱动，不再自绘 chip 行 + 手接 `PageView`。
/// ⛔ 筛选值仍**只**来自 URL（[selectedFolderFilter]）：tab 切换只负责
/// `context.go` 出新 URL，选中态与页面数据都从这一个源派生，不会出现
/// 「滑到某页但 tab 没跟上」的第二真相源。
///
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次。
/// 本 Screen 只为 FAB 定位引用 `kBottomNavContentHeight`。
/// ⛔ **不直接 watch Repository / UseCase**：数据链路固定为
/// Screen → `noteListProvider` → UseCase → Repository。
class NoteListScreen extends ConsumerStatefulWidget {
  const NoteListScreen({super.key});

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen>
    with SingleTickerProviderStateMixin {
  /// 分类 tab 控制器（[TabBar] 与 [TabBarView] 共用）。**在 `folderProvider`
  /// 首次出值后才建**：分类数量取决于文件夹数量，长度变了 [TabController] 只能
  /// 整个重建（`length` 是 final），早建一帧就会白建一次、并让相邻页各订阅一次
  /// 查询。本地库首帧即出值，实际只是一帧空白。
  TabController? _tabController;

  /// 当前分类序列（全部 → 真实文件夹 → 未分类），与 tab 顺序逐字一致。
  /// listener 要靠它把 `TabController.index` 翻回 filter 值，故存成字段。
  List<String?> _categories = const <String?>[];

  /// 已对齐到的下标。⛔ 不用 `_tabController.index` 判重：滑动过程中它会在相邻
  /// 值之间来回通知，`animateTo` 与「URL 回写」会互相触发。
  int _syncedIndex = 0;

  /// 当前标签筛选（URL 来，build 时缓存）：换 tab 写新 URL 时要**带上**它 ——
  /// 标签与文件夹是叠加筛选，切分类不该把标签筛掉。
  String? _activeTagId;

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  /// tab 切换（滑动过半 / 点 tab）→ 写 URL。⛔ 只认两侧都落定后的通知
  /// （`indexIsChanging == false`）：换页动画途中的通知还没到目标值，
  /// 提前写 URL 会让 tab 与 URL 在动画结束前短暂打架。
  void _onTabChanged() {
    final controller = _tabController;
    if (controller == null || controller.indexIsChanging) return;
    final index = controller.index;
    if (index == _syncedIndex) return;
    _syncedIndex = index;
    context.go(filterLocation(_categories[index], tagId: _activeTagId));
  }

  /// URL（唯一真相源）→ tab 下标。不相等才 `animateTo`，因此「点 tab」与
  /// 「返回上一页恢复筛选」两条路径最终收敛到同一个下标。
  void _alignTo(int index) {
    if (index < 0 || index == _syncedIndex) return;
    _syncedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tabController?.animateTo(index);
    });
  }

  void _ensureController(int initialIndex) {
    if (_tabController?.length == _categories.length) return;
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: initialIndex,
    )..addListener(_onTabChanged);
    _syncedIndex = initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final queryParameters = GoRouterState.of(context).uri.queryParameters;
    final filter = selectedFolderFilter(queryParameters);
    // 标签筛选与文件夹筛选同层（URL 真相源），两者叠加进同一个 NoteQuery。
    final tagFilter = selectedTagFilter(queryParameters);
    _activeTagId = tagFilter;
    // 只取本页真正用到的两个字段：watch 整个 `AppSettings` 会让改 `themeMode` /
    // `locale` 等无关偏好时整页（含所有可见 NoteCard）跟着重建 —— `select` 写在
    // [noteListPrefsProvider] 内部，这里不必再管。
    final (:sort, :layout) = ref.watch(noteListPrefsProvider);
    // 搜索 + 筛选 + 排序三者叠加进同一个 [NoteQuery]（`props` 已覆盖
    // 三个字段，任一变化都会重新订阅）。
    final search = ref.watch(noteSearchProvider);
    // 空串归一为 null：datasource 也会归一（`_normalizeTerm`），但那里归一是给所有
    // 调用方兜底 —— 这里先做是为了**不产生第二个等价的 provider 实例**
    // （`NoteQuery('')` 与 `NoteQuery(null)` 的 `props` 不同，会各自订阅一次 SQL）。
    final searchTerm = search.isEmpty ? null : search;
    final folders = ref.watch(folderProvider);
    final folderList = folders.value ?? const <FolderWithCount>[];

    // 多选状态。**选中集非空 = 多选模式**（真相源只有这一个集合，
    // 见 `note_selection_provider.dart`）。全选的语义落在「当前分类的可见笔记」
    // 上，因此这里顺带 watch 当前分类的列表 —— 与 `_CategoryPage` 同一个
    // query 实例，共享同一条流。
    final selection = ref.watch(noteSelectionProvider);
    final visibleNotes =
        ref
            .watch(
              noteListProvider(
                noteQueryFor(
                  filter,
                  searchTerm: searchTerm,
                  tagId: tagFilter,
                ).copyWith(sort: sort),
              ),
            )
            .value ??
        const <Note>[];

    _categories = <String?>[
      null,
      for (final item in folderList) item.folder.id,
      kFolderFilterUncategorized,
    ];
    final currentIndex = _categories.indexOf(filter);
    // 成败都算「已就绪」：出错时按 0 个真实文件夹渲染，仍能显示全部 / 未分类，
    // 不至于把内容区整块留白（文件夹流是本地库，出错基本不可能）。
    if (folders.hasValue || folders.hasError) {
      _ensureController(currentIndex < 0 ? 0 : currentIndex);
      _alignTo(currentIndex);
    }

    // 单栏内容（顶栏 / 搜索 / 分类栏 / 列表 / FAB / 多选动作栏）。宽屏时整块
    // 塞进双栏的左栏，本函数其余部分与窄屏完全共用。
    final content = Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            _TopBar(
              selection: selection,
              visibleNoteIds: <String>{
                for (final note in visibleNotes) note.id,
              },
              activeTagId: tagFilter,
            ),
            // 多选模式下收起搜索框：搜索 + 多选的组合没有稿也没有场景
            //（先选出再搜只会缩小可选范围），留白更干净。
            if (selection.isEmpty) const _SearchField(),
            if (_tabController case final controller?) ...<Widget>[
              _CategoryTabBar(controller: controller, folders: folderList),
              // 分类栏与内容区之间留一条通用小间距：本 App 无阴影、无分隔线，
              // 胶囊紧贴卡片会糊成一片，只能靠留白分层（同顶栏无分隔线的解法）。
              const SizedBox(height: AppSpacing.sm),
            ],
            Expanded(
              child: _tabController == null
                  ? const SizedBox.shrink()
                  : TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        for (final filter in _categories)
                          _CategoryPage(
                            key: ValueKey<String>(filter ?? 'all'),
                            filter: filter,
                            noteSort: sort,
                            noteLayout: layout,
                            searchTerm: searchTerm,
                            tagId: tagFilter,
                          ),
                      ],
                    ),
            ),
          ],
        ),
        // FAB 用 `Stack` + `Positioned` 而**不是** `Scaffold.floatingActionButton`：
        // 后者的 z 序在 `bottomNavigationBar` 之下，而笔记列表稿里 FAB 明确叠在
        // 底部导航之上；且 Material 默认 margin 是 16dp，与稿的 12dp 不符。
        // 多选模式下让位给底部动作栏。
        if (selection.isEmpty)
          Positioned(
            // 相对页面边距再往左下各挪 `sm`（8dp），下方向额外再下移 10dp。
            right: AppSpacing.pageH + AppSpacing.sm,
            // 窄屏压住底栏 26dp、宽屏贴内容区右下角 —— 两种口径都由
            // `fabBottomInsetOf` 给（宽屏直接套旧算式会得到负数）。
            bottom: fabBottomInsetOf(context),
            // 落地页 = 笔记详情空白编辑器：`/notes/new` 与
            // `NoteEditorProvider(kNewNoteId)` 共用编辑页，停止输入 500ms 自动落库。
            // 「全部」与「未分类」没有真实归属，`folderId` 传 null → 落到未分类。
            child: AppFab(
              onPressed: () {
                // 宽屏双栏：新建落在**右侧面板**，不再压一张整页路由上去
                // （压上去等于把双栏糊成单栏，还得点两次才回来）。
                if (context.isTwoPane) {
                  ref.read(selectedNoteProvider.notifier).select(kNewNoteId);
                  return;
                }
                context.push(
                  AppRoutes.noteNewPath(folderId: newNoteFolderId(filter)),
                );
              },
            ),
          ),
        if (selection.isNotEmpty)
          Positioned(
            left: AppSpacing.pageH,
            right: AppSpacing.pageH,
            bottom: navBottomInsetOf(context) + AppSpacing.sm,
            child: _SelectionActionBar(selection: selection),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        bottom: false,
        child: context.isTwoPane
            ? NotesWideLayout(
                list: content,
                // 与 FAB 同一条映射：`uncategorized` 是筛选指令不是文件夹 id。
                newNoteFolderId: newNoteFolderId(filter),
              )
            : content,
      ),
    );
  }
}

/// 单个分类页。一页 = 一个 [NoteQuery]，各自 `ref.watch` 自己的 `noteListProvider`
/// —— 这是与「整页只 watch 当前筛选」的唯一区别：`TabBarView` 上相邻页同时存活，
/// 每页各持一条 `StreamProvider`（同一 query 仍复用同一个流，值相等不多订阅）。
class _CategoryPage extends ConsumerWidget {
  const _CategoryPage({
    required this.filter,
    required this.noteSort,
    required this.noteLayout,
    required this.searchTerm,
    required this.tagId,
    super.key,
  });

  /// 分类筛选值，语义同 [selectedFolderFilter]。
  final String? filter;

  final NoteSort noteSort;

  final NoteLayout noteLayout;

  final String? searchTerm;

  final String? tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(
      noteListProvider(
        noteQueryFor(
          filter,
          searchTerm: searchTerm,
          tagId: tagId,
        ).copyWith(sort: noteSort),
      ),
    );
    final items = notes.value ?? const <Note>[];
    final selection = ref.watch(noteSelectionProvider);
    final selecting = selection.isNotEmpty;
    // 宽屏双栏：左侧列表是**导航性的侧栏**，宫格在这个宽度里会把卡片挤成
    // 两张纸条（列数按 380dp 现算仍是 2 列）。故双栏下恒用单列列表，
    // 设置里的「列表布局」只在单栏（手机 / 中等宽度）生效。
    final twoPane = context.isTwoPane;
    // 当前右侧正在编辑的笔记（仅双栏有意义），用于列表里的「激活」竖条。
    final activeNoteId = twoPane ? ref.watch(selectedNoteProvider) : null;

    // 多选态下点按 = 翻转选中；否则进详情。
    // ⛔ 窄屏必须 `push` 而非 `go`：详情是二级页，`go` 会替换整条栈 → 返回时
    // `pop` 无内容（"There is nothing to pop"），且列表滚动位置丢失。
    // 宽屏双栏则**不导航**，只把选中值交给右侧面板（见 `selectedNoteProvider`）。
    void openNote(Note note) {
      if (selecting) {
        ref.read(noteSelectionProvider.notifier).toggle(note.id);
        return;
      }
      if (twoPane) {
        ref.read(selectedNoteProvider.notifier).select(note.id);
        return;
      }
      context.push(AppRoutes.noteDetailPath(note.id));
    }

    // 长按 = 进入 / 翻转多选。集合空 ↔ 非空即「模式的进入与退出」。
    void longPressNote(Note note) =>
        ref.read(noteSelectionProvider.notifier).toggle(note.id);

    // 右键（桌面）= 单篇快捷动作。多选模式下不弹：此时批量动作栏已经在那了，
    // 两套「删除」入口同时出现只会让人犹豫删的是不是同一批。
    void contextMenuNote(Note note, Offset globalPosition) {
      if (selecting) return;
      showNoteContextMenu(
        context,
        ref: ref,
        note: note,
        position: globalPosition,
        onOpen: () => openNote(note),
        // 删掉的正好是右栏那篇才清空；删别的笔记不该把正在编辑的面板关掉。
        onDeleted: () {
          if (ref.read(selectedNoteProvider) == note.id) {
            ref.read(selectedNoteProvider.notifier).clear();
          }
        },
      );
    }

    // 搜索无结果：内联 3 行，与 `RecentlyDeletedScreen` / 待办的空状态写法逐字一致。
    // ⛔ 只在**有搜索词**时提示 —— 无搜索词的空列表是「还没笔记」，是另一回事
    // （无搜索词的空列表不建空态视觉）。⛔ 不抽 `AppEmptyView`。
    if (items.isEmpty && searchTerm != null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).emptySearchResult,
          style: context.textStyles.subtitle.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      );
    }

    if (twoPane) {
      return _NoteList(
        notes: items,
        onTapNote: openNote,
        onLongPressNote: longPressNote,
        onContextMenuNote: contextMenuNote,
        selectedIds: selection,
        activeNoteId: activeNoteId,
      );
    }

    return switch (noteLayout) {
      NoteLayout.grid => NoteMasonryGrid(
        notes: items,
        onTapNote: openNote,
        onLongPressNote: longPressNote,
        onContextMenuNote: contextMenuNote,
        selectedIds: selection,
      ),
      // 列表与宫格共用同一张 NoteCard —— 两种布局的**唯一**区别是排布方式，
      // 卡片内容逐字一致（列表模式视觉无稿，按单列通栏实现）。
      NoteLayout.list => _NoteList(
        notes: items,
        onTapNote: openNote,
        onLongPressNote: longPressNote,
        onContextMenuNote: contextMenuNote,
        selectedIds: selection,
      ),
    };
  }
}

/// 分类 tab 的内容高度。旧 chip 是 28dp，这里放宽到 32dp ——
/// 点按区更大；⛔ 提成文件私有常量而不是散落字面量（同 `_kSearchSuffixSize`）。
const double _kTabHeight = 32;

/// 选中块圆角。⛔ 不取 `_kTabHeight / 2`（16dp 全圆角胶囊）：32dp 高的窄条上
/// 全圆角把两端收成半圆，视觉半径远大于 16dp 的观感，显得过圆。
const double _kTabRadius = 8;

/// 笔记列表分类栏。[TabBar]（官方组件）—— 可横向滚动、点选即切换，与 [TabBarView]
/// 共用一个 [TabController]，左右滑动开箱即用。
///
/// **选中态靠色差分层的「白块」**：本 App 无阴影（[AppElevation.card] = 0），
/// 分层只靠底色差 —— 页底 `#F2F2F2` 上放 `surface` 白块，选中项自然浮起；
/// 未选中项不加底，只靠 [AppColors.textSecondary] 灰字退到背景里。
/// ⛔ 不沿用 `chipSelectedBg`（`#EFEFEF`）：它与页底 `#F2F2F2` 只差 3 个色阶，
/// 选中态在灰底上等于消失（这正是旧 TabBar 看起来「没选中」的原因）。
///
/// tab 顺序真相源在 `folder_dao` 的 `ORDER BY`（全部恒首位、文件夹按
/// `sortIndex / createdAt`、未分类恒最后），⛔ 不在 Dart 层重排
class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar({required this.controller, required this.folders});

  final TabController controller;

  final List<FolderWithCount> folders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final labelStyle = context.textStyles.chip;
    final pill = BorderRadius.circular(_kTabRadius);

    return TabBar(
      controller: controller,
      // 文件夹数量不可预知（文件夹管理能无限新建），横向滚动是零成本的兜底。
      isScrollable: true,
      // ⛔ 必填：`isScrollable: true` 时默认 `startOffset` 会在左侧留一段空白，
      // 与稿的左对齐页面边距不符。
      tabAlignment: TabAlignment.start,
      // 无下划线分隔线（与顶栏 / 设置页无分隔线一致）。
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(color: colors.surface, borderRadius: pill),
      splashBorderRadius: pill,
      // ⛔ 必须覆盖：M3 默认 overlay 取主题 primary，会在本 App 的灰白配色上
      // 留下一圈紫灰光晕；改用分隔线灰，按压反馈在灰底上刚好可辨、不脏。
      overlayColor: WidgetStatePropertyAll<Color>(colors.divider),
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textSecondary,
      // 选中再加粗一档（w500 → w600）：「选中」是同一文字的强调，不是新字阶
      // （同 `AppTextStyles.navLabel` 选中态用 `copyWith(fontWeight:)` 的约定）。
      labelStyle: labelStyle.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: labelStyle,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
      tabs: <Widget>[
        for (final label in <String>[
          l10n.all,
          for (final item in folders) item.folder.name,
          l10n.uncategorized,
        ])
          Tab(height: _kTabHeight, text: label),
      ],
    );
  }
}

/// 当前筛选值。**唯一真相源是 URL**：
/// null = 全部、哨兵 = 未分类、uuid = 指定文件夹。tab 选中态与列表数据同源，
/// 因此不需要任何本地 state，返回上一页时筛选态也自动恢复。
String? selectedFolderFilter(Map<String, String> queryParameters) =>
    queryParameters[AppRoutes.folderQueryKey];

/// 当前标签筛选值。null = 不按标签过滤；uuid = 标签 id。
String? selectedTagFilter(Map<String, String> queryParameters) =>
    queryParameters[AppRoutes.tagQueryKey];

/// 分类筛选值 → 路由位置。**tab 点选与左右滑动共用这一处映射**，免得两处各拼
/// 一遍 `?folder=`（拼错一处就变成「点 tab 与滑页跳去不同地方」）。
/// [tagId] 非 null 时叠加 `?tag=`（标签与文件夹是同层的叠加筛选）。
String filterLocation(String? filter, {String? tagId}) {
  final params = <String>[
    if (filter != null) '${AppRoutes.folderQueryKey}=$filter',
    if (tagId != null) '${AppRoutes.tagQueryKey}=$tagId',
  ];
  if (params.isEmpty) return AppRoutes.notes;
  return '${AppRoutes.notes}?${params.join('&')}';
}

/// 筛选值 → 新建笔记的落地文件夹。null = 未分类。
///
/// ⛔ 哨兵 [kFolderFilterUncategorized] 不是文件夹 id，它是「筛出 folderId 为空
/// 的笔记」的查询指令，写进新建笔记就成了把 uuid 当 id。
String? newNoteFolderId(String? filter) =>
    filter == null || filter == kFolderFilterUncategorized ? null : filter;

/// URL → `NoteQuery` 的纯映射。SQL 语义由 domain 表达，Screen 只翻 URL。
///
/// [searchTerm] / [tagId] 独立于文件夹筛选：三者是**叠加**关系（搜「标题含 X、
/// 在文件夹 Y、挂标签 Z 的笔记」），不是互斥分支。
NoteQuery noteQueryFor(String? filter, {String? searchTerm, String? tagId}) =>
    switch (filter) {
      null => NoteQuery(searchTerm: searchTerm, tagId: tagId),
      kFolderFilterUncategorized => NoteQuery.uncategorized().copyWith(
        searchTerm: searchTerm,
        tagId: tagId,
      ),
      final id => NoteQuery.of(
        id,
      ).copyWith(searchTerm: searchTerm, tagId: tagId),
    };

/// 笔记列表顶栏：左对齐页面标题「笔记」+ 右对齐图标组。
///
/// 标题**在顶栏内**（不另起一行大标题）：顶栏本来就是页面标题的位置，标题与
/// 图标同处一行，下方内容区整块上移。
///
/// 多选模式下整条换成选择顶栏：左退出、中「已选 n 篇」、右全选/取消全选。
/// 全选的语义落在**当前分类的可见笔记**（[visibleNoteIds]）——
/// 「全选」把看不见的笔记一起选中再批量移动，是用户意料之外的事。
class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.selection,
    required this.visibleNoteIds,
    required this.activeTagId,
  });

  final Set<String> selection;

  final Set<String> visibleNoteIds;

  /// 当前标签筛选（非 null 时顶栏标签图标用实心态区分）。
  final String? activeTagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (selection.isNotEmpty) {
      final allSelected =
          visibleNoteIds.isNotEmpty && visibleNoteIds.every(selection.contains);
      return AppTopBar(
        showDivider: false,
        leading: AppIconButton(
          key: const Key('selection_exit'),
          icon: AppIcons.close,
          tooltip: l10n.batchExit,
          onPressed: ref.read(noteSelectionProvider.notifier).clear,
        ),
        title: Text(
          l10n.batchSelectTitle(selection.length),
          style: context.textStyles.displayTitle.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
        actions: <Widget>[
          AppIconButton(
            key: const Key('selection_toggle_all'),
            icon: AppIcons.checkboxOutline,
            tooltip: allSelected ? l10n.batchSelectNone : l10n.batchSelectAll,
            onPressed: () {
              final notifier = ref.read(noteSelectionProvider.notifier);
              notifier.setAll(
                allSelected
                    ? selection.difference(visibleNoteIds)
                    : <String>{...selection, ...visibleNoteIds},
              );
            },
          ),
        ],
      );
    }

    return AppTopBar(
      // 顶栏与背景同色、无 1dp 分隔线（与设置页 / 文件夹页一致）。
      showDivider: false,
      title: Text(
        l10n.notes,
        style: context.textStyles.displayTitle.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
      // 图标照笔记列表稿画出来；`folder` / `settings` 的目标页由任务落地，
      // 现在点进去是占位页 —— 预期行为，不因「目标页还没建」就删掉图标。
      // 笔记列表稿顶栏无搜索入口，不加。
      // tooltip 传 l10n：`AppIconButton` 的 tooltip 是无障碍必需，不是装饰
      // （笔记列表稿~设置稿上没有文字标签）。
      actions: <Widget>[
        AppIconButton(
          icon: activeTagId == null ? AppIcons.tag : AppIcons.tagFilled,
          tooltip: l10n.tags,
          onPressed: () => showTagFilterSheet(
            context,
            ref: ref,
            selectedTagId: activeTagId,
            onSelected: (tagId) => context.go(
              filterLocation(
                selectedFolderFilter(
                  GoRouterState.of(context).uri.queryParameters,
                ),
                tagId: tagId,
              ),
            ),
            onManage: () => context.push(AppRoutes.noteTags),
          ),
        ),
        AppIconButton(
          icon: AppIcons.folder,
          tooltip: l10n.folders,
          onPressed: () => context.go(AppRoutes.noteFolders),
        ),
        AppIconButton(
          icon: AppIcons.settings,
          tooltip: l10n.settings,
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

/// 行尾清空按钮的图标尺寸。`AppIcon.defaultSize`（24dp）是顶栏尺寸，搜索框里
/// 太大；提成文件私有常量而不是散落字面量（同 `settings_screen` 的同类约定）。
const double _kSearchSuffixSize = 18;

/// 笔记列表搜索框。**页面内私有**（同 `_CategoryTabBar`，不进 `core/ui`）：只笔记列表用。
///
/// ⛔ **不建 `AppTextField`**（同笔记详情标题栏的裁决）：搜索框的边框 / 底色无稿，
/// 按「无边框纯文本」写一条 `InputDecoration` 就够，不值得为它开一个组件。
///
/// **controller 的唯一用途是「清空」**：没有 controller 时清空输入框只能靠换
/// `key` 强制重建，那会把焦点一起丢掉。它随 State 正常 dispose，与笔记详情 / 文件夹管理弹窗
/// 里「不能 dispose controller」那条约束不是一回事（那是 dialog future 提前完成
/// 导致的退场动画问题）。
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 从 provider 回填而非硬编码空串：Screen 被重建（热重载 / 状态恢复）时，
    // 输入框不能是一片空白而下方列表还按旧搜索词过滤。
    _controller = TextEditingController(text: ref.read(noteSearchProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 清空输入与过滤词。⛔ 不 `ref.invalidate(noteListProvider(...))`：查询词变了
  /// `NoteQuery.props` 就变了，provider 会自己重订阅。
  void _clear() {
    _controller.clear();
    ref.read(noteSearchProvider.notifier).set('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasText = ref.watch(noteSearchProvider).isNotEmpty;
    final style = context.textStyles.body;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        key: const Key('note_search_field'),
        controller: _controller,
        onChanged: ref.read(noteSearchProvider.notifier).set,
        style: style.copyWith(color: context.colors.textPrimary),
        cursorColor: context.colors.textPrimary,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: l10n.notesSearchHint,
          hintStyle: style.copyWith(color: context.colors.textPlaceholder),
          suffixIcon: hasText
              ? IconButton(
                  tooltip: l10n.notesSearchClear,
                  // ⛔ 复用 `AppIcons.trash`（`Icons.delete_outline`）当「清空」：
                  // 稿件要的是「×」，但为一个字形改 `core/ui` 不划算 —— 同
                  // `settings_screen` 用 `chevronRight` 顶替详情箭头的处理。
                  icon: const AppIcon(
                    icon: AppIcons.trash,
                    size: _kSearchSuffixSize,
                  ),
                  onPressed: _clear,
                )
              : null,
        ),
      ),
    );
  }
}

/// 设置「笔记列表布局 = 列表」时的单列排布。**页面内私有**（不进 `core/ui`）：
/// 带 `Note` 业务字段，且与笔记列表的 tab 栏同理只此一处用。
///
/// ⛔ **不建自己的卡片**：直接复用 [NoteCard]，两种布局的卡片内容必须逐字一致。
/// 间距与底部留白沿用 [NoteMasonryGrid] 的同一组 token（页边距 12dp、行距
/// 12dp、底部导航高 + 12dp + 安全区），不为「只有一种布局有稿」另开一套值。
class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.notes,
    required this.onTapNote,
    required this.onLongPressNote,
    required this.selectedIds,
    this.onContextMenuNote,
    this.activeNoteId,
  });

  final List<Note> notes;

  final ValueChanged<Note> onTapNote;

  final ValueChanged<Note> onLongPressNote;

  /// 右键（桌面）：第二参是全局坐标。
  final void Function(Note note, Offset globalPosition)? onContextMenuNote;

  final Set<String> selectedIds;

  /// 双栏模式下右侧正在编辑的那篇（用于卡片左侧的琥珀竖条）。
  /// 单栏时为 null —— 列表里没有「打开着」这个概念。
  final String? activeNoteId;

  @override
  Widget build(BuildContext context) {
    // 无搜索词的空列表不建空态视觉。
    if (notes.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        0,
        AppSpacing.pageH,
        listBottomInsetOf(context),
      ),
      itemCount: notes.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.gridRow),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          key: ValueKey<String>(note.id),
          note: note,
          selected: selectedIds.contains(note.id),
          active: note.id == activeNoteId,
          onTap: () => onTapNote(note),
          onLongPress: () => onLongPressNote(note),
          onSecondaryTapDown: onContextMenuNote == null
              ? null
              : (details) => onContextMenuNote!(note, details.globalPosition),
        );
      },
    );
  }
}

/// 多选模式的底部动作栏：移动 / 收藏(取消收藏) / 置顶(取消置顶) / 删除。
///
/// 收藏与置顶按**选中集翻转**：选中笔记全部已收藏 → 显示「取消收藏」并批量
/// 取消，否则显示「收藏」并批量设为。判断依据是选中笔记的现值（watch 全量
/// 列表现算，不缓存）。移动与删除完成后**退出多选**（卡片已离开视野）；
/// flags 动作保留多选 ——「置顶完再移动」是常见连招。
class _SelectionActionBar extends ConsumerWidget {
  const _SelectionActionBar({required this.selection});

  final Set<String> selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    // flags 的翻转语义需要选中笔记的现值。全量列表与分类页共享同一条 DAO 流。
    final allNotes =
        ref.watch(noteListProvider(const NoteQuery())).value ?? const <Note>[];
    final selectedNotes = <Note>[
      for (final note in allNotes)
        if (selection.contains(note.id)) note,
    ];
    final allFavorited =
        selectedNotes.isNotEmpty &&
        selectedNotes.every((note) => note.isFavorite);
    final allPinned =
        selectedNotes.isNotEmpty &&
        selectedNotes.every((note) => note.isPinned);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: <Widget>[
          _SelectionAction(
            icon: AppIcons.folder,
            label: l10n.batchMove,
            onTap: () => _move(context, ref),
          ),
          _SelectionAction(
            icon: allFavorited ? AppIcons.starOutline : AppIcons.starFilled,
            label: allFavorited ? l10n.batchUnfavorite : l10n.batchFavorite,
            onTap: () => _flags(context, ref, isFavorite: !allFavorited),
          ),
          _SelectionAction(
            icon: allPinned ? AppIcons.pushPin : AppIcons.pushPinFilled,
            label: allPinned ? l10n.batchUnpin : l10n.batchPin,
            onTap: () => _flags(context, ref, isPinned: !allPinned),
          ),
          _SelectionAction(
            icon: AppIcons.trash,
            label: l10n.delete,
            iconColor: colors.feedbackDanger,
            onTap: () => _delete(context, ref),
          ),
        ],
      ),
    );
  }

  void _move(BuildContext context, WidgetRef ref) {
    showFolderPickerSheet(
      context,
      ref: ref,
      onSelected: (folderId) => _fire(
        context,
        ref,
        ref.read(batchMoveNotesUseCaseProvider)(selection.toList(), folderId),
        exitSelection: true,
      ),
    );
  }

  void _flags(
    BuildContext context,
    WidgetRef ref, {
    bool? isPinned,
    bool? isFavorite,
  }) {
    _fire(
      context,
      ref,
      ref
          .read(batchUpdateNoteFlagsUseCaseProvider)
          .call(selection.toList(), isPinned: isPinned, isFavorite: isFavorite),
      // ⛔ 不清多选：flags 之后卡片不消失，用户常连做「置顶 → 移动」。
    );
  }

  void _delete(BuildContext context, WidgetRef ref) {
    _fire(
      context,
      ref,
      ref.read(batchDeleteNotesUseCaseProvider)(selection.toList()),
      exitSelection: true,
    );
  }

  /// 批量动作的统一出口：成功静默（列表自己会动），失败才出 SnackBar ——
  /// 与全 App「不出成功提示」的既有惯例一致（`deleteFolderDone` 只在跨页动作时用）。
  ///
  /// ⚠️ `messenger` 与失败文案在 await **之前**抓出来：`ScaffoldMessenger`
  /// 是全局的，不随页面 dispose 失效 —— 这是 `use_build_context_synchronously`
  /// 的正解，而不是往每个闭包里塞 `mounted` 检查。
  void _fire(
    BuildContext context,
    WidgetRef ref,
    Future<Either<Failure, int>> future, {
    bool exitSelection = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final failureText = AppLocalizations.of(context).batchOperationFailed;
    future.then((result) {
      if (exitSelection) {
        ref.read(noteSelectionProvider.notifier).clear();
      }
      result.fold(
        (_) => messenger.showSnackBar(SnackBar(content: Text(failureText))),
        (_) {},
      );
    });
  }
}

/// 动作栏的一个动作：图标 + 小字标签竖排，整块可点。
class _SelectionAction extends StatelessWidget {
  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// null = 常规图标色；删除传 `feedbackDanger`。
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(
                icon: icon,
                size: 20,
                color: iconColor ?? colors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.sm / 2),
              Text(
                label,
                style: context.textStyles.meta.copyWith(
                  color: iconColor ?? colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
