import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/folder_with_count.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_query.dart';
import '../providers/folder_provider.dart';
import '../providers/note_list_provider.dart';
import '../providers/note_search_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/note_masonry_grid.dart';

/// P1 笔记列表（D1）。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// **三条 P5 偏好都在这里落地**（`ARCHITECTURE-DESIGN.md` §4 的取值来源表）：
/// `noteSort` 进 [NoteQuery]、`noteLayout` 选排布、`textScale` 逐层透传给
/// 字阶。三者都经 provider 读，改完 P5 回来即生效，不重启 App；
/// ⛔ **一律不进 URL**（§8.2：偏好不是导航状态）。
///
/// **分类栏与左右滑动用官方组件**（本页新增）：分类栏 = [TabBar]，内容 =
/// [TabBarView]，两者共用一个 [TabController] —— 点 tab、左右滑、写 URL 三件事
/// 由官方组件同一套 index 驱动，不再自绘 chip 行 + 手接 `PageView`。
/// ⛔ 筛选值仍**只**来自 URL（[selectedFolderFilter]）：tab 切换只负责
/// `context.go` 出新 URL，选中态与页面数据都从这一个源派生，不会出现
/// 「滑到某页但 tab 没跟上」的第二真相源。
///
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次（`TASK-008`）。
/// 本 Screen 只为 FAB 定位引用 `kBottomNavContentHeight`。
/// ⛔ **不直接 watch Repository / UseCase**：数据链路固定为
/// Screen → `noteListProvider` → UseCase → Repository（`ARCHITECTURE-DESIGN.md` §4 P1）。
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
    context.go(filterLocation(_categories[index]));
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
    // 只取本页真正用到的两个字段：watch 整个 `AppSettings` 会让改 `themeMode` /
    // `textScale` / `locale` 等无关偏好时整页（含所有可见 NoteCard）跟着重建。
    final (noteSort, noteLayout) = ref.watch(
      settingsProvider.select((s) => (s.noteSort, s.noteLayout)),
    );
    final textScale = ref.watch(textScaleFactorProvider);
    // Q1 落地：搜索 + 筛选 + 排序三者叠加进同一个 [NoteQuery]（`props` 已覆盖
    // 三个字段，任一变化都会重新订阅）。
    final search = ref.watch(noteSearchProvider);
    // 空串归一为 null：datasource 也会归一（`_normalizeTerm`），但那里归一是给所有
    // 调用方兜底 —— 这里先做是为了**不产生第二个等价的 provider 实例**
    // （`NoteQuery('')` 与 `NoteQuery(null)` 的 `props` 不同，会各自订阅一次 SQL）。
    final searchTerm = search.isEmpty ? null : search;
    final folders = ref.watch(folderProvider);
    final folderList = folders.value ?? const <FolderWithCount>[];

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

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _TopBar(textScale: textScale),
                _SearchField(textScale: textScale),
                if (_tabController case final controller?) ...<Widget>[
                  _CategoryTabBar(
                    controller: controller,
                    folders: folderList,
                    textScale: textScale,
                  ),
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
                                noteSort: noteSort,
                                noteLayout: noteLayout,
                                searchTerm: searchTerm,
                                textScale: textScale,
                              ),
                          ],
                        ),
                ),
              ],
            ),
            // FAB 用 `Stack` + `Positioned` 而**不是** `Scaffold.floatingActionButton`：
            // 后者的 z 序在 `bottomNavigationBar` 之下，而 D1 里 FAB 明确叠在
            // 底部导航之上；且 Material 默认 margin 是 16dp，与稿的 12dp 不符。
            Positioned(
              // 相对页面边距再往左下各挪 `sm`（8dp），下方向额外再下移 10dp。
              right: AppSpacing.pageH + AppSpacing.sm,
              bottom:
                  kBottomNavContentHeight +
                  AppSpacing.pageH -
                  AppSpacing.sm -
                  30,
              // Q6 按「落地页 = P3 空白编辑器」落地：`/notes/new` 与
              // `NoteEditorProvider(kNewNoteId)` 共用编辑页，停止输入 500ms 自动落库。
              child: AppFab(onPressed: () => context.push(AppRoutes.noteNew)),
            ),
          ],
        ),
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
    required this.textScale,
    super.key,
  });

  /// 分类筛选值，语义同 [selectedFolderFilter]。
  final String? filter;

  final AppNoteSort noteSort;

  final NoteLayout noteLayout;

  final String? searchTerm;

  final double textScale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(
      noteListProvider(
        withAppNoteSort(noteQueryFor(filter, searchTerm: searchTerm), noteSort),
      ),
    );
    final items = notes.value ?? const <Note>[];

    // ⛔ 必须 `push` 而非 `go`：详情是二级页，`go` 会替换整条栈 → 返回时
    // `pop` 无内容（"There is nothing to pop"），且列表滚动位置丢失。
    void openNote(Note note) => context.push(AppRoutes.noteDetailPath(note.id));

    // 搜索无结果：内联 3 行，与 `RecentlyDeletedScreen` / P2 的空状态写法逐字一致。
    // ⛔ 只在**有搜索词**时提示 —— 无搜索词的空列表是「还没笔记」，是另一回事
    // （Q31 无稿，见 docs/OPEN-DESIGN-QUESTIONS.md）。⛔ 不抽 `AppEmptyView`。
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

    return switch (noteLayout) {
      NoteLayout.grid => NoteMasonryGrid(
        notes: items,
        textScale: textScale,
        onTapNote: openNote,
      ),
      // 列表与宫格共用同一张 NoteCard —— 两种布局的**唯一**区别是排布方式，
      // 卡片内容逐字一致（Q14 补稿后只校这一处）。
      // Q14 → docs/OPEN-DESIGN-QUESTIONS.md（列表模式视觉无稿，按单列通栏实现）
      NoteLayout.list => _NoteList(
        notes: items,
        textScale: textScale,
        onTapNote: openNote,
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

/// P1 分类栏。[TabBar]（官方组件）—— 可横向滚动、点选即切换，与 [TabBarView]
/// 共用一个 [TabController]，左右滑动开箱即用。
///
/// **选中态靠色差分层的「白块」**：本 App 无阴影（[AppElevation.card] = 0），
/// 分层只靠底色差 —— 页底 `#F2F2F2` 上放 `surface` 白块，选中项自然浮起；
/// 未选中项不加底，只靠 [AppColors.textSecondary] 灰字退到背景里。
/// ⛔ 不沿用 `chipSelectedBg`（`#EFEFEF`）：它与页底 `#F2F2F2` 只差 3 个色阶，
/// 选中态在灰底上等于消失（这正是旧 TabBar 看起来「没选中」的原因）。
///
/// Q18 → docs/OPEN-DESIGN-QUESTIONS.md（tab 顺序真相源在 `folder_dao` 的
/// `ORDER BY created_at ASC`，⛔ 不在 Dart 层重排）
class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar({
    required this.controller,
    required this.folders,
    required this.textScale,
  });

  final TabController controller;

  final List<FolderWithCount> folders;

  /// P5「文字大小」的排版系数，透传给每个 tab 的标签。
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final labelStyle = context.textStyles.chip.scaled(textScale);
    final pill = BorderRadius.circular(_kTabRadius);

    return TabBar(
      controller: controller,
      // 文件夹数量不可预知（P4 能无限新建），横向滚动是零成本的兜底。
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

/// 当前筛选值。**唯一真相源是 URL**（`ARCHITECTURE-DESIGN.md` §8.2）：
/// null = 全部、哨兵 = 未分类、uuid = 指定文件夹。tab 选中态与列表数据同源，
/// 因此不需要任何本地 state，返回上一页时筛选态也自动恢复。
String? selectedFolderFilter(Map<String, String> queryParameters) =>
    queryParameters[AppRoutes.folderQueryKey];

/// 分类筛选值 → 路由位置。**tab 点选与左右滑动共用这一处映射**，免得两处各拼
/// 一遍 `?folder=`（拼错一处就变成「点 tab 与滑页跳去不同地方」）。
String filterLocation(String? filter) => switch (filter) {
  null => AppRoutes.notes,
  kFolderFilterUncategorized =>
    '${AppRoutes.notes}?${AppRoutes.folderQueryKey}=$kFolderFilterUncategorized',
  final id => '${AppRoutes.notes}?${AppRoutes.folderQueryKey}=$id',
};

/// URL → `NoteQuery` 的纯映射。SQL 语义由 domain 表达，Screen 只翻 URL。
///
/// [searchTerm] 独立于文件夹筛选：两者是**叠加**关系（搜「标题含 X 且在文件夹 Y
/// 下的笔记」），不是互斥分支。
NoteQuery noteQueryFor(String? filter, {String? searchTerm}) =>
    switch (filter) {
      null => NoteQuery(searchTerm: searchTerm),
      kFolderFilterUncategorized => NoteQuery.uncategorized().copyWith(
        searchTerm: searchTerm,
      ),
      final id => NoteQuery.of(id).copyWith(searchTerm: searchTerm),
    };

/// P1 顶栏：左对齐页面标题「笔记」+ 右对齐图标组。
///
/// 标题**在顶栏内**（不另起一行大标题）：顶栏本来就是页面标题的位置，标题与
/// 图标同处一行，下方内容区整块上移。
class _TopBar extends StatelessWidget {
  const _TopBar({required this.textScale});

  /// P5「文字大小」的排版系数。标题原本是页面大标题时就接 `textScale`
  /// （`AppLargeTitle`），移进顶栏后语义不变 —— 仍是同一条「文字大小」的消费方。
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      // 顶栏与背景同色、无 1dp 分隔线（与设置页 / 文件夹页一致）。
      showDivider: false,
      title: Text(
        AppLocalizations.of(context).notes,
        style: context.textStyles.displayTitle
            .scaled(textScale)
            .copyWith(color: context.colors.textPrimary),
      ),
      // 图标照 D1 画出来；`folder` / `settings` 的目标页由 TASK-050 / 046 落地，
      // 现在点进去是占位页 —— 预期行为，不因「目标页还没建」就删掉图标
      // （`ROADMAP.md` §4.3）。D1 顶栏无搜索入口（Q1），不加。
      // tooltip 传 l10n：`AppIconButton` 的 tooltip 是无障碍必需，不是装饰
      // （D1~D5 稿上没有文字标签）。
      actions: <Widget>[
        AppIconButton(
          icon: AppIcons.folder,
          tooltip: AppLocalizations.of(context).folders,
          onPressed: () => context.go(AppRoutes.noteFolders),
        ),
        AppIconButton(
          icon: AppIcons.settings,
          tooltip: AppLocalizations.of(context).settings,
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

/// 行尾清空按钮的图标尺寸。`AppIcon.defaultSize`（24dp）是顶栏尺寸，搜索框里
/// 太大；提成文件私有常量而不是散落字面量（同 `settings_screen` 的同类约定）。
const double _kSearchSuffixSize = 18;

/// P1 搜索框。**页面内私有**（同 `_CategoryTabBar`，不进 `core/ui`）：只 P1 用。
///
/// ⛔ **不建 `AppTextField`**（同 P3 标题栏的裁决）：搜索框的边框 / 底色无稿，
/// 按「无边框纯文本」写一条 `InputDecoration` 就够，不值得为它开一个组件。
///
/// **controller 的唯一用途是「清空」**：没有 controller 时清空输入框只能靠换
/// `key` 强制重建，那会把焦点一起丢掉。它随 State 正常 dispose，与 P3 / P4 弹窗
/// 里「不能 dispose controller」那条约束不是一回事（那是 dialog future 提前完成
/// 导致的退场动画问题）。
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField({required this.textScale});

  final double textScale;

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
    final style = context.textStyles.body.scaled(widget.textScale);

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

/// P5「笔记列表布局 = 列表」时的单列排布。**页面内私有**（不进 `core/ui`）：
/// 带 `Note` 业务字段，且与 P1 的 tab 栏同理只此一处用
/// （`DEVELOPMENT-GUIDELINES.md` §7.3）。
///
/// ⛔ **不建自己的卡片**：直接复用 [NoteCard]，两种布局的卡片内容必须逐字一致。
/// 间距与底部留白沿用 [NoteMasonryGrid] 的同一组 token（页边距 12dp、行距
/// 12dp、底部导航高 + 12dp + 安全区），不为「只有一种布局有稿」另开一套值。
class _NoteList extends StatelessWidget {
  const _NoteList({
    required this.notes,
    required this.textScale,
    required this.onTapNote,
  });

  final List<Note> notes;

  final double textScale;

  final ValueChanged<Note> onTapNote;

  @override
  Widget build(BuildContext context) {
    // Q31 → docs/OPEN-DESIGN-QUESTIONS.md（无搜索词的空列表不建空态视觉）
    if (notes.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        0,
        AppSpacing.pageH,
        kBottomNavContentHeight +
            AppSpacing.pageH +
            MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: notes.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.gridRow),
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          key: ValueKey<String>(note.id),
          note: note,
          textScale: textScale,
          onTap: () => onTapNote(note),
        );
      },
    );
  }
}
