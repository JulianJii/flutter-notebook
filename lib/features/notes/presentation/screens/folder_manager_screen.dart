import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/theme/tokens/app_colors.dart';
import 'package:init/core/theme/tokens/app_spacing.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/core/utils/app_utils.dart';
import 'package:init/features/notes/domain/usecases/create_folder_params.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/folder_provider.dart';
import '../widgets/create_folder_row.dart';
import '../widgets/folder_row.dart';
import 'note_list_screen.dart' show selectedFolderFilter;

/// P4 文件夹管理（D4）。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// **行序 =「全部」→ 各真实文件夹 →「未分类」→「新建文件夹」**（D4 实测）。
/// 「全部」与「未分类」**不是文件夹行**（`ARCHITECTURE-DESIGN.md` §5.3），由本页
/// 合成：「全部」的计数 = 各文件夹 count 之和 + 未分类计数，一行算术、不额外查询。
///
/// **筛选真相源是 URL**（§8.2）：点行只写 `?folder=`，读取侧的 P1 与本页读同一个
/// query 参数（[selectedFolderFilter]），因此不需要任何本地 state，返回上一页
/// 时筛选态自动恢复。
///
/// **可拖项只有真实文件夹**：`ReorderableListView` 的 `header` / `footer` 装
/// 「全部」「未分类」「新建文件夹」三行固定项，拖动顺序写进库里的 `sort_index`
/// （覆盖 D4 稿「本页无排序入口」，见 `docs/OPEN-DESIGN-QUESTIONS.md` Q-新2）。
///
/// ⛔ **不提供重命名 / 删除入口**：无长按菜单、无多选态、顶栏也不画 trash
/// （Q11 / Q12 未答，trash 语义未知已定：删掉）。
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次（TASK-008）。
class FolderManagerScreen extends ConsumerWidget {
  const FolderManagerScreen({super.key});

  /// 行间距（D4 实测 ≈8dp）。
  ///
  /// ⚠️ `AppSpacing.gridRow`(12dp) 是 D1 的值，两者不同；8dp 只有 P4 一个调用点，
  /// 故留在页面内不进 `core/theme/tokens/`（只有一个调用点的值不是 token）。
  static const double rowGap = 8;

  /// 一行 + 它下方的 [rowGap]。
  ///
  /// `ReorderableListView` 没有 `separatorBuilder`，间距只能挂在行上；列表最后
  /// 一行（「新建文件夹」）不加，否则底部会多出一段 8dp。
  static Widget _gappedBelow(Widget child, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(bottom: rowGap),
    child: child,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final folders = ref.watch(folderProvider).value ?? const [];
    final uncategorized = ref.watch(uncategorizedCountProvider).value ?? 0;
    // Q31 / Q33 → docs/OPEN-DESIGN-QUESTIONS.md（空 / 加载 / 错误态视觉无稿）
    final selected = selectedFolderFilter(
      GoRouterState.of(context).uri.queryParameters,
    );
    final total =
        folders.fold<int>(0, (sum, item) => sum + item.count) + uncategorized;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                color: context.colors.textPrimary,
                // P4 是 `/notes` 的子路由，正常是 push 上去的 → `pop` 才能保住
                // P1 的滚动位置；直接 deep link 进来时栈里没有下层，回退到 P1。
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.notes),
              ),
              centerTitle: Text(
                l10n.folders,
                style: context.textStyles.topBarTitle,
              ),
              // D4 顶栏下方**无** 1dp 分隔线（同 P5，按稿关掉）。
              showDivider: false,
            ),
            Expanded(
              // ⚠️ 只有**真实文件夹**是可拖项：`header` / `footer` 放三行页合成的
              // 固定行，这样 `onReorderItem` 拿到的 index 就是 `folders` 的下标，
              // 不需要任何偏移换算。
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageH,
                ),
                // 关掉内置把手：桌面端它会**再加**一个右侧把手，而本页的把手
                // （`AppIcons.drag`）是行内自己画的。
                buildDefaultDragHandles: false,
                itemCount: folders.length,
                // `onReorderItem`（不是已废弃的 `onReorder`）：框架已经把
                // `newIndex` 里被拖走的那一项减掉了，本页不需要再修索引。
                onReorderItem: (oldIndex, newIndex) =>
                    _reorderFolders(context, ref, oldIndex, newIndex),
                header: _gappedBelow(
                  FolderRow(
                    name: l10n.all,
                    count: total,
                    isSelected: selected == null,
                    onTap: () => context.go(AppRoutes.notes),
                  ),
                ),
                footer: Column(
                  children: <Widget>[
                    _gappedBelow(
                      FolderRow(
                        name: l10n.uncategorized,
                        count: uncategorized,
                        isSelected: selected == kFolderFilterUncategorized,
                        onTap: () => context.go(
                          '${AppRoutes.notes}?'
                          '${AppRoutes.folderQueryKey}=$kFolderFilterUncategorized',
                        ),
                      ),
                    ),
                    CreateFolderRow(
                      onTap: () => _promptCreateFolder(context, ref),
                    ),
                  ],
                ),
                itemBuilder: (context, index) {
                  final item = folders[index];
                  return _gappedBelow(
                    // 可拖项必须有 key（`ReorderableListView` 的硬要求）。
                    key: ValueKey<String>(item.folder.id),
                    FolderRow(
                      name: item.folder.name,
                      // 计数让位给拖动图标（P4 拖拽排序）。
                      isSelected: selected == item.folder.id,
                      onTap: () => context.go(
                        '${AppRoutes.notes}?'
                        '${AppRoutes.folderQueryKey}=${item.folder.id}',
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const AppIcon(
                          icon: AppIcons.drag,
                          size: AppSpacing.rowIconSize,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 拖拽落点 → 新顺序 → `ReorderFoldersUseCase`。
  ///
  /// ⛔ **不在本地留一份顺序**：`folderProvider` 由 drift watch 驱动，`sort_index`
  /// 一变新顺序自己回来（与新建文件夹同一条路径，§8.4），本地再存一份就是
  /// 第二个真相源。
  Future<void> _reorderFolders(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    // 回调里用 `read`：`watch` 只属于 `build`。
    final folders = ref.read(folderProvider).value ?? const [];
    final ids = folders.map((item) => item.folder.id).toList();
    ids.insert(newIndex, ids.removeAt(oldIndex));

    final result = await ref.read(reorderFoldersUseCaseProvider).call(ids);
    if (!context.mounted) return;
    result.fold((failure) {
      // 写失败时列表不动（顺序的真相在库里），只把原因说出来。
      AppUtils.showSnackBar(context, message: failure.message);
    }, (_) {});
  }

  /// 新建文件夹。**弹窗视觉无稿（Q13）**：用 `showDialog` + Material 默认样式，
  /// ⛔ 不建 `AppDialog` / `AppBottomSheet`（§8 的「不建」清单）。
  /// Q13 / Q34 → docs/OPEN-DESIGN-QUESTIONS.md（弹窗与 Snackbar 沿用 Material 默认）
  ///
  /// 校验（空名 / 超长 / 重名）全在 `CreateFolderUseCase` 里，页面只负责把
  /// `InputFailure` 的文案弹出来。
  Future<void> _promptCreateFolder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // ⛔ 不用 `TextEditingController`：`showDialog` 的 future 在 `pop` 时就完成，
    // 而退出动画还在跑，立即 `dispose()` 会让仍在重建的 `TextField` 拿到已释放的
    // controller。一个字符串足够 —— 弹窗只有一个输入框。
    var entered = '';

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createFolder),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.folderName),
          onChanged: (value) => entered = value,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(entered),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final result = await ref
        .read(createFolderUseCaseProvider)
        .call(CreateFolderParams(name: name.trim()));
    // 成功路径不需要 `ref.invalidate`：drift watch 会把新行推给 `folderProvider`，
    // UI 自动重建（`ARCHITECTURE-DESIGN.md` §8.4）。
    result.fold((failure) {
      if (context.mounted) {
        AppUtils.showSnackBar(context, message: failure.message);
      }
    }, (_) {});
  }
}
