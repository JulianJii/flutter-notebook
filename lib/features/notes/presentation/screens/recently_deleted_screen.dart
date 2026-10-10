import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/notes/presentation/providers/deleted_note_list_provider.dart';
import 'package:mynote/features/notes/presentation/providers/trashed_folder_list_provider.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/presentation/providers/trashed_todo_list_provider.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 「最近删除」回收站（设置入口，`/notes/trash`）。
///
/// **三类实体**：笔记 / 文件夹 / 待办，各自一段，空的段整个不渲染。
/// 分组而不是 TabBar：回收站的量级是「几十条」，翻页比滚动更慢；且 TabBar 要
/// 新增选中态与切换逻辑，零收益。
///
/// 数据链路与其他页一致：Screen → `deletedNoteListProvider` /
/// `trashedFolderListProvider` / `trashedTodoListProvider` → UseCase →
/// Repository。恢复 / 永久删除直接 `ref.read` 对应 UseCase；drift watch 会推流，
/// 操作成功后列表自动刷新，无需 invalidate。
///
/// ⛔ **行不可点**：回收站里不提供编辑入口 —— 软删除的内容不是编辑对象，
/// 要编辑先恢复。两行操作（恢复 / 永久删除）就是本页全部语义。
/// ⛔ **不渲染 `AppBottomNav`**：与文件夹管理 / 设置同理，是 `/notes` 的 push 子页。
class RecentlyDeletedScreen extends ConsumerWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(deletedNoteListProvider).value ?? const <Note>[];
    final folders =
        ref.watch(trashedFolderListProvider).value ?? const <NoteFolder>[];
    final todos = ref.watch(trashedTodoListProvider).value ?? const <Todo>[];

    final isEmpty = notes.isEmpty && folders.isEmpty && todos.isEmpty;

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
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.notes),
              ),
              centerTitle: Text(
                l10n.settingsRecentDeleted,
                style: context.textStyles.topBarTitle,
              ),
              // 清空入口只在有内容时可用 —— 空回收站上弹「确定清空吗」是噪音。
              actions: <Widget>[
                AppIconButton(
                  icon: AppIcons.trash,
                  tooltip: l10n.trashEmptyAction,
                  onPressed: isEmpty ? null : () => _emptyTrash(context, ref),
                ),
              ],
              showDivider: false,
            ),
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Text(
                        l10n.trashEmpty,
                        style: context.textStyles.subtitle.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH,
                        vertical: AppSpacing.sm,
                      ),
                      children: <Widget>[
                        if (notes.isNotEmpty) ...[
                          _GroupHeader(title: l10n.trashGroupNotes),
                          for (final note in notes)
                            _TrashRow(
                              title: _noteTitle(note),
                              deletedAt: note.deletedAt!,
                              onRestore: () => _restoreNote(context, ref, note.id),
                              onPurge: () => _purgeNote(context, ref, note.id),
                            ),
                        ],
                        if (folders.isNotEmpty) ...[
                          _GroupHeader(title: l10n.trashGroupFolders),
                          for (final folder in folders)
                            _TrashRow(
                              title: folder.name,
                              deletedAt: folder.deletedAt!,
                              onRestore: () =>
                                  _restoreFolder(context, ref, folder.id),
                              onPurge: () =>
                                  _purgeFolder(context, ref, folder.id),
                            ),
                        ],
                        if (todos.isNotEmpty) ...[
                          _GroupHeader(title: l10n.trashGroupTodos),
                          for (final todo in todos)
                            _TrashRow(
                              title: todo.title,
                              deletedAt: todo.deletedAt!,
                              onRestore: () => _restoreTodo(context, ref, todo.id),
                              onPurge: () => _purgeTodo(context, ref, todo.id),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 标题为空时用正文第一行顶上（派生值现算，不落库 —— 与 `NoteCard` 同理）。
  static String _noteTitle(Note note) {
    if (note.title.trim().isNotEmpty) return note.title;
    return NoteDelta.plainText(note.content).trim().split('\n').first.trim();
  }

  // ---- 三类实体各自的编排：形状一样，use case 不同 ----
  //
  // ⛔ 不抽「泛型 + 回调」的统一方法：三个方法的差异只有调哪个 provider，
  // 泛化后要传 3 个回调 + 类型参数，比抄三遍更难读。

  Future<void> _restoreNote(BuildContext context, WidgetRef ref, String id) {
    return _runRestore(
      context,
      () => ref.read(restoreNoteUseCaseProvider)(id),
    );
  }

  Future<void> _restoreFolder(BuildContext context, WidgetRef ref, String id) {
    return _runRestore(
      context,
      () => ref.read(restoreFolderUseCaseProvider)(id),
    );
  }

  Future<void> _restoreTodo(BuildContext context, WidgetRef ref, String id) {
    return _runRestore(context, () => ref.read(restoreTodoUseCaseProvider)(id));
  }

  /// 恢复：成功提示，失败按 Failure 原样报（恢复撞重名会回 `InputFailure`，
  /// 那必须让用户看到 —— 悄悄改名等于恢复出另一个文件夹）。
  Future<void> _runRestore(
    BuildContext context,
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final result = await action();
    if (!context.mounted) return;
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) => AppUtils.showSnackBar(context, message: l10n.restoreDone),
    );
  }

  Future<void> _purgeNote(BuildContext context, WidgetRef ref, String id) {
    return _runPurge(
      context,
      () => ref.read(purgeNoteUseCaseProvider)(id),
    );
  }

  Future<void> _purgeFolder(BuildContext context, WidgetRef ref, String id) {
    return _runPurge(
      context,
      () => ref.read(purgeFolderUseCaseProvider)(id),
    );
  }

  Future<void> _purgeTodo(BuildContext context, WidgetRef ref, String id) {
    return _runPurge(context, () => ref.read(purgeTodoUseCaseProvider)(id));
  }

  /// 永久删除：二次确认 → 物理删。确认后**不再提示成功**（列表里那行消失了，
  /// 本身就是反馈；弹「已删除」反而像还有别的事没做完）。
  Future<void> _runPurge(
    BuildContext context,
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      content: l10n.trashDeleteForeverConfirm,
      confirmLabel: l10n.trashDeleteForever,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await action();
    if (!context.mounted) return;
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) {},
    );
  }

  /// 清空回收站：二次确认 → 三类依次清。
  ///
  /// ⚠️ **不是事务**：三类分属三个 repository，跨 feature 没有共同事务可用。
  /// 中途失败会留下「清了一半」的状态，但三步都是单条 DELETE、且失败概率极低，
  /// 为它引入跨 feature 协调机制不值。当心的是别把「已清空」当成全部成功报出去
  /// —— 所以按顺序跑，任一步失败就停下并报错。
  Future<void> _emptyTrash(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      content: l10n.trashEmptyConfirm,
      confirmLabel: l10n.trashEmptyAction,
    );
    if (confirmed != true || !context.mounted) return;

    final emptiers = <Future<Either<Failure, Unit>> Function()>[
      () => ref.read(emptyTrashUseCaseProvider)(),
      () => ref.read(emptyFolderTrashUseCaseProvider)(),
      () => ref.read(emptyTodoTrashUseCaseProvider)(),
    ];

    for (final empty in emptiers) {
      final result = await empty();
      if (result.isLeft()) {
        if (context.mounted) {
          AppUtils.showSnackBar(
            context,
            message: result.fold((f) => f.message, (_) => ''),
          );
        }
        return;
      }
    }

    if (context.mounted) {
      AppUtils.showSnackBar(context, message: l10n.emptyDone);
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String content,
    required String confirmLabel,
  }) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

/// 分组小标题。⛔ 不是 `AppSectionHeader`：那个是设置页分隔线用的固定样式，
/// 回收站是卡片流里的行内小标题，两者视觉层级不同。
///
/// 上边距同时充当**段间距** —— 所以各段之间不需要额外的间隔 widget。
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.rowPadH,
        AppSpacing.lg,
        AppSpacing.rowPadH,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: context.textStyles.meta.copyWith(
          color: context.colors.textTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 回收站的一行：标题 + 「删除于日期」，右侧「恢复 / 永久删除」两个文字按钮。
///
/// 类型无关 —— 三类实体共用（笔记 / 文件夹 / 待办的行长得一样，只是内容不同）。
///
/// 页面内私有组件（`DEVELOPMENT-GUIDELINES.md` §7.2）：语义只属于回收站，
/// 不上提 `core/ui`。
class _TrashRow extends StatelessWidget {
  const _TrashRow({
    required this.title,
    required this.deletedAt,
    required this.onRestore,
    required this.onPurge,
  });

  final String title;

  /// 已删除时刻。**非空** —— 行出现在回收站里就意味着有墓碑（见
  /// `Note.deletedAt` 等）；传 null 会让 `trashDeletedAt(null)` 崩在格式化上。
  final DateTime deletedAt;

  final VoidCallback onRestore;

  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.rowPadH,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title.isEmpty ? l10n.noteSnippetPlaceholder : title,
                    style: context.textStyles.rowTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.trashDeletedAt(deletedAt),
                    style: context.textStyles.meta.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.chipGap),
            TextButton(
              onPressed: onRestore,
              child: Text(
                l10n.trashRestore,
                style: context.textStyles.value.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onPurge,
              child: Text(
                l10n.trashDeleteForever,
                style: context.textStyles.value.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}