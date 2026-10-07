import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/deleted_note_list_provider.dart';

/// 「最近删除」回收站（P5 设置入口，`/notes/trash`）。
///
/// 数据链路与其他页一致：Screen → `deletedNoteListProvider` →
/// `WatchDeletedNotesUseCase` → Repository。恢复 / 永久删除直接
/// `ref.read` 对应 UseCase（同 `NoteDetailScreen._delete` 的薄编排模式）；
/// drift watch 会推流，操作成功后列表自动刷新，无需 invalidate。
///
/// ⛔ **行不可点**：回收站里不提供编辑入口 —— 软删除的内容不是编辑对象，
/// 要编辑先恢复。两行操作（恢复 / 永久删除）就是本页全部语义。
/// ⛔ **不渲染 `AppBottomNav`**：与 P4 / P5 同理，是 `/notes` 的 push 子页。
class RecentlyDeletedScreen extends ConsumerWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(deletedNoteListProvider).value ?? const <Note>[];

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
              // 清空入口只在有内容时可用 —— 空列表上弹「确定清空吗」是噪音。
              actions: <Widget>[
                AppIconButton(
                  icon: AppIcons.trash,
                  tooltip: l10n.trashEmptyAction,
                  onPressed: notes.isEmpty ? null : () => _emptyTrash(context, ref),
                ),
              ],
              showDivider: false,
            ),
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Text(
                        l10n.trashEmpty,
                        style: context.textStyles.subtitle.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: notes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _TrashRow(
                        note: notes[index],
                        onRestore: () => _restore(context, ref, notes[index].id),
                        onPurge: () => _purge(context, ref, notes[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, String noteId) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(restoreNoteUseCaseProvider)(noteId);
    result.fold(
      (failure) {
        if (context.mounted) {
          AppUtils.showSnackBar(context, message: failure.message);
        }
      },
      (_) {
        if (context.mounted) {
          AppUtils.showSnackBar(context, message: l10n.restoreDone);
        }
      },
    );
  }

  /// 永久删除：二次确认（弹窗视觉无稿，同 P3/P4 的 Material 默认形态）。
  Future<void> _purge(BuildContext context, WidgetRef ref, Note note) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.trashDeleteForeverConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trashDeleteForever),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(purgeNoteUseCaseProvider)(note.id);
    result.fold((failure) {
      if (context.mounted) {
        AppUtils.showSnackBar(context, message: failure.message);
      }
    }, (_) {});
  }

  /// 清空回收站：二次确认。
  Future<void> _emptyTrash(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.trashEmptyConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trashEmptyAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(emptyTrashUseCaseProvider)();
    result.fold((failure) {
      if (context.mounted) {
        AppUtils.showSnackBar(context, message: failure.message);
      }
    }, (_) {
      if (context.mounted) {
        AppUtils.showSnackBar(context, message: l10n.emptyDone);
      }
    });
  }
}

/// 回收站的一行：标题 + 「删除于日期」，右侧「恢复 / 永久删除」两个文字按钮。
///
/// 页面内私有组件（`DEVELOPMENT-GUIDELINES.md` §7.2）：语义只属于回收站，
/// 不上提 `core/ui`。
class _TrashRow extends StatelessWidget {
  const _TrashRow({
    required this.note,
    required this.onRestore,
    required this.onPurge,
  });

  final Note note;

  final VoidCallback onRestore;

  final VoidCallback onPurge;

  /// 标题为空时用正文第一行顶上（派生值现算，不落库 —— 与 `NoteCard` 同理）。
  String get _displayTitle {
    if (note.title.trim().isNotEmpty) return note.title;
    final firstLine = NoteDelta.plainText(
      note.content,
    ).trim().split('\n').first.trim();
    return firstLine;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return AppCard(
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
                  _displayTitle.isEmpty
                      ? l10n.noteSnippetPlaceholder
                      : _displayTitle,
                  style: context.textStyles.rowTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.trashDeletedAt(note.deletedAt!),
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
    );
  }
}
