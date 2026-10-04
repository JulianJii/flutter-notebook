import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/logging/logger_provider.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/presentation/providers/settings_provider.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/folder_with_count.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/note_query.dart';
import '../providers/folder_provider.dart';
import '../providers/note_list_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/note_masonry_grid.dart';

/// P1 笔记列表（D1）。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// **三条 P5 偏好都在这里落地**（`ARCHITECTURE-DESIGN.md` §4 的取值来源表）：
/// `noteSort` 进 [NoteQuery]、`noteLayout` 选排布、`textScale` 逐层透传给
/// 字阶。三者都经 provider 读，改完 P5 回来即生效，不重启 App；
/// ⛔ **一律不进 URL**（§8.2：偏好不是导航状态）。
///
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次（`TASK-008`）。
/// 本 Screen 只为 FAB 定位引用 `kBottomNavContentHeight`。
/// ⛔ **不直接 watch Repository / UseCase**：数据链路固定为
/// Screen → `noteListProvider` → UseCase → Repository（`ARCHITECTURE-DESIGN.md` §4 P1）。
class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queryParameters = GoRouterState.of(context).uri.queryParameters;
    final filter = selectedFolderFilter(queryParameters);
    final settings = ref.watch(settingsProvider);
    final textScale = ref.watch(textScaleFactorProvider);
    final notes = ref.watch(
      noteListProvider(
        withAppNoteSort(noteQueryFor(filter), settings.noteSort),
      ),
    );
    final folders = ref.watch(folderProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                const _TopBar(),
                AppLargeTitle(
                  text: AppLocalizations.of(context).notes,
                  textScale: textScale,
                ),
                _FilterChipRow(
                  selected: filter,
                  folders: folders.value ?? const <FolderWithCount>[],
                  textScale: textScale,
                ),
                Expanded(
                  child: switch (settings.noteLayout) {
                    NoteLayout.grid => NoteMasonryGrid(
                      notes: notes.value ?? const <Note>[],
                      textScale: textScale,
                      onTapNote: (note) =>
                          context.go(AppRoutes.noteDetailPath(note.id)),
                    ),
                    // 列表与宫格共用同一张 NoteCard —— 两种布局的**唯一**区别
                    // 是排布方式，卡片内容逐字一致（Q14 补稿后只校这一处）。
                    // TODO(Q14): 「笔记列表布局」的列表模式视觉无稿（D1 只有
                    // 宫格模式），当前按「同一张 NoteCard 单列通栏」实现，
                    // 等设计补稿后校准。
                    NoteLayout.list => _NoteList(
                      notes: notes.value ?? const <Note>[],
                      textScale: textScale,
                      onTapNote: (note) =>
                          context.go(AppRoutes.noteDetailPath(note.id)),
                    ),
                  },
                ),
              ],
            ),
            // FAB 用 `Stack` + `Positioned` 而**不是** `Scaffold.floatingActionButton`：
            // 后者的 z 序在 `bottomNavigationBar` 之下，而 D1 里 FAB 明确叠在
            // 底部导航之上；且 Material 默认 margin 是 16dp，与稿的 12dp 不符。
            Positioned(
              right: AppSpacing.pageH,
              bottom: kBottomNavContentHeight + AppSpacing.pageH,
              child: AppFab(
                onPressed: () {
                  // TODO(Q6): FAB 落地页形态未定（空白编辑器 P3 还是独立新建页）。
                  ref
                      .read(taggedLoggerProvider('notes'))
                      .i('fab tapped, Q6 unresolved');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 当前筛选值。**唯一真相源是 URL**（`ARCHITECTURE-DESIGN.md` §8.2）：
/// null = 全部、哨兵 = 未分类、uuid = 指定文件夹。chip 选中态与列表数据同源，
/// 因此不需要任何本地 state，返回上一页时筛选态也自动恢复。
String? selectedFolderFilter(Map<String, String> queryParameters) =>
    queryParameters[AppRoutes.folderQueryKey];

/// URL → `NoteQuery` 的纯映射。SQL 语义由 domain 表达，Screen 只翻 URL。
NoteQuery noteQueryFor(String? filter) => switch (filter) {
  null => const NoteQuery(),
  kFolderFilterUncategorized => NoteQuery.uncategorized(),
  final id => NoteQuery.of(id),
};

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
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
          onPressed: () => context.go(AppRoutes.settings),
        ),
      ],
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.selected,
    required this.folders,
    required this.textScale,
  });

  /// 当前筛选值，语义同 [selectedFolderFilter]。
  final String? selected;

  final List<FolderWithCount> folders;

  /// P5「文字大小」的排版系数，透传给每个 chip。
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // TODO(Q18): chip 排序无设计稿（D1 只有 1 个真实文件夹，暴露不出规则）。
    // 当前决策：全部 恒第一位 → 真实文件夹按 createdAt ASC → 未分类 恒最后。
    // Q18 若答「chip 与 D4 是同一套分类」，此顺序仍成立（D4 是用户自建顺序）；
    // Q18 若给了新顺序，只改这一处排序表达式。
    final real = <FolderWithCount>[...folders]
      ..sort((a, b) => a.folder.createdAt.compareTo(b.folder.createdAt));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.pageH),
        child: Row(
          children: <Widget>[
            AppFilterChip(
              label: l10n.all,
              selected: selected == null,
              textScale: textScale,
              onTap: () => context.go(AppRoutes.notes),
            ),
            // 文件夹数量不可预知（P4 能无限新建），横向滚动是零成本的兜底，
            // 有稿时的静态观感不变。不用 Wrap：换行会把内容区整体下推。
            for (final item in real) ...<Widget>[
              const SizedBox(width: AppSpacing.chipGap),
              AppFilterChip(
                label: item.folder.name,
                selected: selected == item.folder.id,
                textScale: textScale,
                onTap: () => context.go(
                  '${AppRoutes.notes}?${AppRoutes.folderQueryKey}=${item.folder.id}',
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.chipGap),
            AppFilterChip(
              label: l10n.uncategorized,
              selected: selected == kFolderFilterUncategorized,
              textScale: textScale,
              onTap: () => context.go(
                '${AppRoutes.notes}?${AppRoutes.folderQueryKey}=$kFolderFilterUncategorized',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// P5「笔记列表布局 = 列表」时的单列排布。**页面内私有**（不进 `core/ui`）：
/// 带 `Note` 业务字段，且与 P1 的 chip 行同理只此一处用
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
    // TODO(Q31): 空状态无设计稿，不建视觉（与 P1 宫格 / P2 一致）。
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
