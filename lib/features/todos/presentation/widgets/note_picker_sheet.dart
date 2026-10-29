import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/presentation/providers/note_list_provider.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 「给待办挂笔记」的笔记选择弹层：可搜索的存活笔记列表（DAO 的 watch 只推
/// 未删除行，回收站天然不在内），点选即回调并关弹层。
///
/// 跨 feature 的边界：本组件只 import notes 的 **domain + presentation
/// provider**（经 UseCase 拿数据，不碰 notes 的 data 层）。
Future<void> showNotePickerSheet(
  BuildContext context, {
  required WidgetRef ref,
  required ValueChanged<Note> onSelected,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      // 搜索词是弹窗的临时状态 → StatefulBuilder（与待办编辑弹窗同一取舍，
      // 不为它建 StatefulWidget）。
      var term = '';
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final l10n = AppLocalizations.of(sheetContext);
          final colors = sheetContext.colors;
          final textStyles = sheetContext.textStyles;
          final notes =
              ref
                  .watch(
                    // 全量 + 本地过滤：一次选择动作不值得建一条 LIKE 流。
                    // `ponytail:` 笔记量级（百）下 `contains` 零成本；上千再改查 NoteQuery。
                    noteListProvider(const NoteQuery()),
                  )
                  .value ??
              const <Note>[];
          final filtered = term.isEmpty
              ? notes
              : notes
                    .where(
                      (note) =>
                          note.title.contains(term) ||
                          NoteDelta.plainText(note.content).contains(term),
                    )
                    .toList(growable: false);

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    l10n.todoLinkedNotePick,
                    style: textStyles.subtitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TextField(
                    key: const Key('note_picker_search'),
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.notePickerHint,
                      prefixIcon: const AppIcon(icon: AppIcons.search),
                    ),
                    onChanged: (value) => setSheetState(() => term = value),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            l10n.notePickerEmpty,
                            style: textStyles.body.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final note = filtered[index];
                            return ListTile(
                              key: Key('note_picker_${note.id}'),
                              title: Text(
                                note.title.isEmpty
                                    ? NoteDelta.plainText(note.content)
                                    : note.title,
                                style: textStyles.body.copyWith(
                                  color: colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const AppIcon(
                                icon: AppIcons.chevronRight,
                              ),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                onSelected(note);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
