import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/tag.dart';
import '../../providers/notes_providers.dart';
import '../providers/tag_providers.dart';

/// 标签管理页（`/notes/tags`）：改名 / 删除。删除 = 从所有笔记上摘掉该标签
/// （级联墓碑，见 `NoteTagDao.softDeleteTag`），必须二次确认。
class TagManagerScreen extends ConsumerWidget {
  const TagManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagListProvider).value ?? const <Tag>[];
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: AppPageBody(
        bottom: false,
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                onPressed: () => _safePop(context),
              ),
              title: Text(
                l10n.tagManagerTitle,
                style: textStyles.displayTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              showDivider: false,
            ),
            Expanded(
              child: tags.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noTags,
                        style: textStyles.subtitle.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageH,
                        AppSpacing.sm,
                        AppSpacing.pageH,
                        AppSpacing.pageH,
                      ),
                      itemCount: tags.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        return _TagRow(
                          key: Key('tag_row_${tag.id}'),
                          tag: tag,
                          onRename: () => _promptRename(context, ref, tag),
                          onDelete: () => _confirmDelete(context, ref, tag),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 深链直达（栈里没有下层）时 `pop` 会抛 —— 与详情页 / 回收站同一兜底。
  static void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.pushReplacement(AppRoutes.notes);
    }
  }

  Future<void> _promptRename(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: tag.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tagRenameTitle),
        content: TextField(
          key: const Key('tag_rename_field'),
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == tag.name || !context.mounted) {
      return;
    }
    final result = await ref.read(renameTagUseCaseProvider)(tag.id, name);
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) {},
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.tagDeleteConfirm(tag.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('tag_delete_confirm'),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.feedbackDanger,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.tagDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref.read(deleteTagUseCaseProvider)(tag.id);
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      (_) {},
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final Tag tag;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Card(
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        title: Text(
          tag.name,
          style: textStyles.body.copyWith(color: colors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          l10n.tagNoteCount(tag.noteCount),
          style: textStyles.meta.copyWith(color: colors.textTertiary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIconButton(
              icon: AppIcons.edit,
              tooltip: l10n.tagRename,
              onPressed: onRename,
            ),
            AppIconButton(
              icon: AppIcons.trash,
              tooltip: l10n.tagDelete,
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onRename,
      ),
    );
  }
}
