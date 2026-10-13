import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'tag_filter_sheet.dart';

/// 详情页的打标弹层：现值（`GetNoteTagsUseCase`）回填 → chip 翻转 / 输入即建
/// → 「完成」一次性 `SetNoteTagsUseCase`。点弹层外部 = 取消，不做任何写库。
///
/// 返回 `true` = 用户点了「完成」且落库成功（调用方据此刷新展示行）。
/// ⛔ 不逐次 toggle 落库：一次对齐是单事务，逐次写会产生 n 条同步变更。
Future<bool> showTagEditorSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String noteId,
}) async {
  final current = await ref.read(getNoteTagsUseCaseProvider)(noteId);
  if (!context.mounted) return false;
  final initial = current.fold(
    (_) => <String>[],
    (names) => names,
  );

  final result = await showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TagEditorSheet(initialNames: initial),
  );
  if (result == null || !context.mounted) return false;

  final either = await ref.read(setNoteTagsUseCaseProvider)(
    noteId,
    result.toList(),
  );
  // 失败才出提示；成功由调用方刷新展示行。
  var saved = true;
  either.fold(
    (failure) {
      saved = false;
      if (!context.mounted) return;
      AppUtils.showSnackBar(context, message: failure.message);
    },
    (_) {},
  );
  return saved;
}

class _TagEditorSheet extends ConsumerStatefulWidget {
  const _TagEditorSheet({required this.initialNames});

  final List<String> initialNames;

  @override
  ConsumerState<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends ConsumerState<_TagEditorSheet> {
  late final Set<String> _selected = <String>{...widget.initialNames};
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _toggle(String name) {
    setState(() {
      if (!_selected.remove(name)) _selected.add(name);
    });
  }

  /// 输入即建：回车把新名字加进选中集（标签行的创建延迟到「完成」的
  /// `createOrGet` 里，弹层内不做任何写库）。
  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _selected.add(name);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final textStyles = context.textStyles;
    final allTags = ref.watch(tagListProvider).value ?? const <Tag>[];

    return Padding(
      // 键盘顶起：isScrollControlled 弹层的标配。
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.tags,
                      style: textStyles.subtitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('tag_editor_done'),
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(l10n.save),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Wrap(
                  spacing: AppSpacing.chipGap,
                  runSpacing: AppSpacing.chipGap,
                  children: <Widget>[
                    // 全部已有标签（供点选），当前未挂的也在列 —— 打标是高频
                    // 复选动作。
                    for (final tag in allTags)
                      TagChip(
                        key: Key('tag_edit_${tag.id}'),
                        label: tag.name,
                        selected: _selected.contains(tag.name),
                        onTap: () => _toggle(tag.name),
                      ),
                    // 输入过但尚未保存的新名字也亮着，所见即所存。
                    for (final name in _selected)
                      if (!allTags.any((tag) => tag.name == name))
                        TagChip(
                          label: name,
                          selected: true,
                          onTap: () => _toggle(name),
                        ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: TextField(
                key: const Key('tag_editor_input'),
                controller: _controller,
                focusNode: _focus,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.tagEditorHint,
                  hintStyle: textStyles.body.copyWith(
                    color: colors.textPlaceholder,
                  ),
                  suffixIcon: IconButton(
                    tooltip: l10n.save,
                    icon: const AppIcon(icon: AppIcons.plus),
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
