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
/// ⛔ **不提供重命名 / 删除入口**：D4 无长按菜单、无多选态（Q11 / Q12 未答）。
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次（TASK-008）。
class FolderManagerScreen extends ConsumerWidget {
  const FolderManagerScreen({super.key});

  /// 行间距（D4 实测 ≈8dp）。
  ///
  /// ⚠️ `AppSpacing.gridRow`(12dp) 是 D1 的值，两者不同；8dp 只有 P4 一个调用点，
  /// 故留在页面内不进 `core/theme/tokens/`（只有一个调用点的值不是 token）。
  static const double rowGap = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final folders = ref.watch(folderProvider).value ?? const [];
    final uncategorized = ref.watch(uncategorizedCountProvider).value ?? 0;
    // TODO(Q31/Q33): 空状态 / 加载态 / 错误态均无设计稿，不建视觉（与 P1 / P2 一致）。
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
              actions: <Widget>[
                // D4 上有这个图标，但语义未知（删除选中 / 批量管理 / 无用）——
                // 稿上有就照常画出来，点不动。
                // TODO(Q11): 顶栏 trash 的作用未知，待设计确认。
                AppIconButton(
                  icon: AppIcons.trash,
                  tooltip: l10n.delete,
                  onPressed: null,
                ),
              ],
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageH,
                ),
                itemCount: folders.length + 3,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: rowGap),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FolderRow(
                      name: l10n.all,
                      count: total,
                      isSelected: selected == null,
                      onTap: () => context.go(AppRoutes.notes),
                    );
                  }
                  if (index == folders.length + 1) {
                    return FolderRow(
                      name: l10n.uncategorized,
                      count: uncategorized,
                      isSelected: selected == kFolderFilterUncategorized,
                      onTap: () => context.go(
                        '${AppRoutes.notes}?'
                        '${AppRoutes.folderQueryKey}=$kFolderFilterUncategorized',
                      ),
                    );
                  }
                  if (index == folders.length + 2) {
                    return CreateFolderRow(
                      onTap: () => _promptCreateFolder(context, ref),
                    );
                  }
                  final item = folders[index - 1];
                  return FolderRow(
                    name: item.folder.name,
                    count: item.count,
                    isSelected: selected == item.folder.id,
                    onTap: () => context.go(
                      '${AppRoutes.notes}?'
                      '${AppRoutes.folderQueryKey}=${item.folder.id}',
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

  /// 新建文件夹。**弹窗视觉无稿（Q13）**：用 `showDialog` + Material 默认样式，
  /// ⛔ 不建 `AppDialog` / `AppBottomSheet`（§8 的「不建」清单）。
  /// TODO(Q13): 输入弹窗视觉无稿，补稿后替换。
  ///
  /// 校验（空名 / 超长 / 重名）全在 `CreateFolderUseCase` 里，页面只负责把
  /// `InputFailure` 的文案弹出来。
  // TODO(Q34): Snackbar 视觉无稿，当前用既有 `AppUtils.showSnackBar` 顶着。
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
