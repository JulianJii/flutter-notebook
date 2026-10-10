import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_params.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_use_case.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/folder_provider.dart';
import '../widgets/create_folder_row.dart';
import '../widgets/folder_row.dart';
import 'note_list_screen.dart' show selectedFolderFilter;

/// 文件夹管理。薄编排：只 `ref.watch` + 拼装，零 `setState`、零业务判断。
///
/// **行序 = 各真实文件夹 →「新建文件夹」**，行内无计数。
/// 「全部」与「未分类」**不在本页**（`ARCHITECTURE-DESIGN.md` §5.3：两者都不是表里的
/// 行）—— 它们是笔记列表顶部的分类 tab，本页只列真实文件夹。
///
/// **筛选真相源是 URL**（§8.2）：点行只写 `?folder=`，读取侧的笔记列表与本页读同一个
/// query 参数（[selectedFolderFilter]），因此不需要任何本地 state，返回上一页
/// 时筛选态自动恢复。
///
/// **可拖项只有真实文件夹**：「新建文件夹」装在 `ReorderableListView` 的 `footer`
/// 固定行，拖动顺序写进库里的 `sort_index`（覆盖文件夹管理稿「本页无排序入口」）。
///
/// ⛔ **仍不提供重命名入口**：`renameFolderUseCaseProvider` 在库里有、也有测试，
/// 但设计稿没有它的位置（`UI-IMPLEMENTATION-SPEC.md` §4 P4 段「本页无」），无稿不画。
/// 要加的话与删除同处长按菜单加一项即可。
/// 删除入口是**长按**弹菜单：行内 `trailing` 已被拖拽手柄占满，再塞图标会挤掉
/// 拖拽区（`FolderRow` 有测试钉住布局）。
/// ⛔ **不渲染 `AppBottomNav`**：它由 `NotesShell` 渲染一次（TASK-008）。
class FolderManagerScreen extends ConsumerWidget {
  const FolderManagerScreen({super.key});

  /// 行间距（文件夹管理稿实测 ≈8dp）。
  ///
  /// ⚠️ `AppSpacing.gridRow`(12dp) 是笔记列表稿的值，两者不同；8dp 只有文件夹管理一个调用点，
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
    // 空 / 加载 / 错误态视觉无稿，由 `AsyncValue` 兜底，不额外建视觉。
    final selected = selectedFolderFilter(
      GoRouterState.of(context).uri.queryParameters,
    );

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
                // 文件夹管理是 `/notes` 的子路由，正常是 push 上去的 → `pop` 才能保住
                // 笔记列表的滚动位置；直接 deep link 进来时栈里没有下层，回退到笔记列表。
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.notes),
              ),
              centerTitle: Text(
                l10n.folders,
                style: context.textStyles.topBarTitle,
              ),
              // 文件夹管理稿顶栏下方**无** 1dp 分隔线（同设置，按稿关掉）。
              showDivider: false,
            ),
            Expanded(
              // ⚠️ 只有**真实文件夹**是可拖项：「新建文件夹」装在 `footer` 的固定行，
              // 这样 `onReorderItem` 拿到的 index 就是 `folders` 的下标，
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
                footer: CreateFolderRow(
                  onTap: () => _promptCreateFolder(context, ref),
                ),
                itemBuilder: (context, index) {
                  final item = folders[index];
                  return _gappedBelow(
                    // 可拖项必须有 key（`ReorderableListView` 的硬要求）。
                    key: ValueKey<String>(item.folder.id),
                    // 长按菜单包在 `FolderRow` 外面而不是塞进它的参数：`AppCard`
                    // 只有 `onTap`，改它就得动全部调用方与它的测试。`opaque` 让
                    // 长按命中整张卡片（含 padding 区），符合「按卡片」的手感。
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () => _showFolderMenu(context, ref, item.folder),
                      child: FolderRow(
                        name: item.folder.name,
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

  /// 新建文件夹。**弹窗视觉无稿**：用 `showDialog` + Material 默认样式，
  /// ⛔ 不建 `AppDialog` / `AppBottomSheet`（§8 的「不建」清单）。
  ///
  /// 名称校验（空 / 超长 / 重名）**在弹窗里就地判**，错误显示在输入框下方、弹窗不
  /// 关 —— 用户直接改完再提交，不用「关弹窗 → 看报错 → 重新打开」。
  /// `CreateFolderUseCase` 里同一套校验**照旧保留**：它是领域规则，也是库外调用的
  /// 唯一防线（重名的最终判据仍是库里 `name` 的 UNIQUE 索引，弹窗只是先一步拦）。
  Future<void> _promptCreateFolder(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // ⛔ 不用 `TextEditingController`：`showDialog` 的 future 在 `pop` 时就完成，
    // 而退出动画还在跑，立即 `dispose()` 会让仍在重建的 `TextField` 拿到已释放的
    // controller。一个字符串足够 —— 弹窗只有一个输入框。
    var entered = '';

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        // 校验态（错误文案）只活在这一个弹窗里，`StatefulBuilder` 够用 ——
        // 为一个输入框建一个 StatefulWidget 是把状态搬到文件级别。
        String? error;
        return StatefulBuilder(
          builder: (context, setState) {
            void submit() {
              final trimmed = entered.trim();
              final taken = ref.read(folderProvider).value ?? const [];
              if (trimmed.isEmpty) {
                setState(() => error = l10n.folderNameEmpty);
              } else if (trimmed.length > CreateFolderUseCase.maxNameLength) {
                setState(
                  () => error = l10n.folderNameTooLong(
                    CreateFolderUseCase.maxNameLength,
                  ),
                );
              } else if (taken.any((item) => item.folder.name == trimmed)) {
                setState(() => error = l10n.folderNameExists);
              } else {
                Navigator.of(dialogContext).pop(trimmed);
              }
            }

            return AlertDialog(
              title: Text(l10n.createFolder),
              content: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.folderName,
                  errorText: error,
                ),
                onChanged: (value) => entered = value,
                onSubmitted: (value) {
                  entered = value;
                  submit();
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                TextButton(onPressed: submit, child: Text(l10n.save)),
              ],
            );
          },
        );
      },
    );

    if (name == null) return;

    final result = await ref
        .read(createFolderUseCaseProvider)
        .call(CreateFolderParams(name: name));
    // 成功路径不需要 `ref.invalidate`：drift watch 会把新行推给 `folderProvider`，
    // UI 自动重建（`ARCHITECTURE-DESIGN.md` §8.4）。
    result.fold((failure) {
      if (!context.mounted) return;
      // 走到这里还撞重名 = 弹窗打开期间名字被占（导入 / 恢复）：把它翻成本地化
      // 文案，别的失败（写库出错）原样透出。**空名 / 超长**在弹窗里已拦下，
      // 所以 `InputFailure` 在本页只剩「重名」一种含义。
      AppUtils.showSnackBar(
        context,
        message: failure is InputFailure ? l10n.folderNameExists : failure.message,
      );
    }, (_) {});
  }

  /// 长按文件夹 → 底部操作菜单。
  ///
  /// ⚠️ **弹窗视觉无稿**：用 `showModalBottomSheet` 的 Material 默认形态，
  /// ⛔ 不建 `core/ui` 组件（同 `_promptCreateFolder` 的理由）。
  /// 当前只有「删除」一项 —— `renameFolderUseCase` 存在但无稿可依（见类注释）。
  Future<void> _showFolderMenu(
    BuildContext context,
    WidgetRef ref,
    NoteFolder folder,
  ) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<_FolderAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                folder.name,
                style: context.textStyles.rowTitle.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
              enabled: false,
            ),
            const AppDivider(),
            ListTile(
              leading: AppIcon(
                icon: AppIcons.trash,
                size: AppSpacing.rowIconSize,
                color: context.colors.feedbackDanger,
              ),
              title: Text(
                l10n.deleteFolderMenu,
                style: context.textStyles.rowTitle.copyWith(
                  color: context.colors.feedbackDanger,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_FolderAction.delete),
            ),
          ],
        ),
      ),
    );

    if (action != _FolderAction.delete || !context.mounted) return;
    await _confirmDeleteFolder(context, ref, folder);
  }

  /// 删除文件夹：二次确认 → 软删除（进回收站，可恢复）。
  ///
  /// ⚠️ `DeleteFolderUseCase` 的注释原写「不加二次确认（弹窗无稿）」—— 那是在
  /// 删除**没有入口**的前提下说的（无法触发的路径不需要确认框）。现在有了入口，
  /// 确认框就是必须的：误触长按不能直接删掉一个文件夹。
  /// 删除是软删除，其下的笔记落进未分类，两者都可在回收站恢复。
  Future<void> _confirmDeleteFolder(
    BuildContext context,
    WidgetRef ref,
    NoteFolder folder,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.deleteFolderConfirm(folder.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(deleteFolderUseCaseProvider)(folder.id);
    result.fold((failure) {
      if (context.mounted) {
        AppUtils.showSnackBar(context, message: failure.message);
      }
    }, (_) {
      // 成功不弹提示：文件夹从列表消失本身就是反馈。
      if (context.mounted) {
        AppUtils.showSnackBar(context, message: l10n.deleteFolderDone);
      }
    });
  }
}

/// 长按菜单里的动作。只有一项，但**用枚举而不是 `bool`**：返回 `true/false` 的话
/// 弹「取消」与弹「删除」在语义上都是 false，将来加第二项时这个 bool 就说不清它
/// 代表什么了。
enum _FolderAction { delete }
