import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/notes/domain/entities/note_version.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/presentation/providers/version_providers.dart';
import 'package:mynote/features/notes/presentation/widgets/note_image_embed_builder.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 单篇笔记的版本历史（`/notes/:id/history`）：时间线（新→旧），点条目进
/// 只读预览页（真回滚的恢复入口在那里）。
///
/// ⛔ 恢复**不在时间线上做**：恢复是覆盖当前内容的破坏性动作，必须先看全文
/// 再决定 —— 两步走（时间线 → 预览 → 恢复）比在列表行上加按钮更难误触。
class NoteHistoryScreen extends ConsumerWidget {
  const NoteHistoryScreen({required this.noteId, super.key});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final versions = ref.watch(noteHistoryProvider(noteId)).value;

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
                onPressed: () => _leave(context),
              ),
              title: Text(
                l10n.noteHistory,
                style: textStyles.displayTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              showDivider: false,
            ),
            Expanded(
              child: versions == null
                  ? const SizedBox.shrink()
                  : versions.isEmpty
                  ? Center(
                      child: Text(
                        l10n.historyEmpty,
                        style: textStyles.subtitle.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageH,
                        AppSpacing.sm,
                        AppSpacing.pageH,
                        AppSpacing.pageH,
                      ),
                      itemCount: versions.length,
                      itemBuilder: (context, index) => _TimelineRow(
                        key: Key('history_row_${versions[index].id}'),
                        version: versions[index],
                        // 最后一条没有下划线（时间线到头）。
                        showLine: index < versions.length - 1,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 深链直达（栈里没有下层）时 `pop` 会抛 —— 退不回就回详情页。
  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.noteDetailPath(noteId));
    }
  }
}

/// 时间线的一行：左圆点 + 竖线，右侧时间 / 标题 / 正文纯文本两行预览。
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.version,
    required this.showLine,
    super.key,
  });

  final NoteVersion version;

  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final l10n = AppLocalizations.of(context);
    final preview = NoteDelta.plainText(version.content).trim();

    return InkWell(
      onTap: () => context.push(
        AppRoutes.noteHistoryVersionPath(version.noteId, version.id),
      ),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 时间线轨道：圆点 + 竖线。圆点用 accent —— 「这是可选点进去的」。
            SizedBox(
              width: 20,
              child: Column(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (showLine)
                    Container(width: 1.5, height: 52, color: colors.divider),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toString(),
                    ).add_Hm().format(version.createdAt),
                    style: textStyles.meta.copyWith(color: colors.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.sm / 2),
                  Text(
                    version.title.isEmpty ? l10n.noteTitleHint : version.title,
                    style: textStyles.rowTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm / 2),
                  Text(
                    preview.isEmpty ? l10n.noteSnippetPlaceholder : preview,
                    style: textStyles.meta.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const AppIcon(icon: AppIcons.chevronRight),
          ],
        ),
      ),
    );
  }
}

/// 单个版本的只读预览（`/notes/:id/history/:versionId`）。
/// 底部「恢复此版本」：二次确认（当前内容先自动存一版）→ 恢复 → 回详情页。
class NoteVersionPreviewScreen extends ConsumerWidget {
  const NoteVersionPreviewScreen({required this.versionId, super.key});

  final String versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final version = ref.watch(noteVersionProvider(versionId)).value;

    return Scaffold(
      backgroundColor: colors.surface,
      body: AppPageBody(
        bottom: false,
        child: version == null
            ? const SizedBox.shrink()
            : Column(
                children: <Widget>[
                  AppTopBar(
                    leading: AppIconButton(
                      icon: AppIcons.back,
                      tooltip: l10n.back,
                      onPressed: () => _safePop(context),
                    ),
                    title: Text(
                      DateFormat.yMMMd(
                        Localizations.localeOf(context).toString(),
                      ).add_Hm().format(version.createdAt),
                      style: textStyles.subtitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    showDivider: false,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH,
                      ),
                      child: QuillEditor(
                        controller: QuillController(
                          document: Document.fromDelta(
                            NoteDelta.decode(version.content),
                          ),
                          selection: const TextSelection.collapsed(offset: 0),
                          readOnly: true,
                        ),
                        focusNode: FocusNode(),
                        scrollController: ScrollController(),
                        config: QuillEditorConfig(
                          // 只读预览：readOnly 在 controller 上置 true
                          // （QuillEditorConfig 无此参数）；不显工具条、不抢焦点。
                          scrollable: true,
                          expands: true,
                          padding: EdgeInsets.zero,
                          showCursor: false,
                          embedBuilders: <EmbedBuilder>[
                            NoteImageEmbedBuilder(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 恢复按钮。Surface 上再垫一层 bg 分隔（无分隔线约定）。
                  Container(
                    color: colors.bg,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pageH,
                      AppSpacing.sm,
                      AppSpacing.pageH,
                      AppSpacing.pageH + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('history_restore'),
                        onPressed: () => _restore(context, ref, version),
                        child: Text(l10n.historyRestore),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    NoteVersion version,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.historyRestoreConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.historyRestore),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final limit = ref.read(settingsProvider).noteVersionLimit;
    final result = await ref
        .read(restoreNoteVersionUseCaseProvider)
        .call(version.id, limit);
    if (!context.mounted) return;
    result.fold(
      (failure) => AppUtils.showSnackBar(context, message: failure.message),
      // 恢复成功：`go` 回详情 —— 详情页的编辑器只灌一次值，`pop` 回去会看到
      // 旧内容还停在草稿里；`go` 让整页重挂、从库里重新水合恢复后的内容。
      (_) => context.go(AppRoutes.noteDetailPath(version.noteId)),
    );
  }

  static void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.notes);
    }
  }
}
