import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/note_editor_provider.dart';
import '../providers/selected_note_provider.dart';
import 'note_editor_pane.dart';

/// 宽屏（≥ [AppBreakpoints.twoPane]）笔记工作台：**左列表 + 右编辑**。
///
/// 左栏 [listWidth] 固定，内容原样复用 `NoteListScreen` 的单栏结构（顶栏 / 搜索 /
/// 分类 TabBar / 瀑布流 / FAB / 多选动作栏），因此筛选、URL 同步、多选全部
/// 零改动；本组件只负责「右半边放什么」。
///
/// ⛔ 右侧**不是一个路由**：选中哪篇来自 [selectedNoteProvider]，不 push
/// `/notes/:id`。理由见该 provider 的注释（URL 的唯一真相源已有 folder / tag）。
class NotesWideLayout extends ConsumerWidget {
  const NotesWideLayout({
    required this.list,
    required this.newNoteFolderId,
    super.key,
  });

  /// 左栏内容（`NoteListScreen` 拼好的整块）。
  final Widget list;

  /// 新建笔记的落地分类（与 FAB 用的同一个映射结果）。选中 `kNewNoteId` 时
  /// 必须把它传给 `NoteEditorPane`，否则命中另一个 provider 实例。
  final String? newNoteFolderId;

  /// 左栏宽度。380dp：够放一行标题 + 三行摘要，又不至于把右侧编辑区挤窄。
  static const double listWidth = 380;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedNoteProvider);
    final notifier = ref.read(selectedNoteProvider.notifier);

    return Row(
      children: <Widget>[
        // key 只给测试量宽度用：左栏是「固定 380」而不是按比例，退化成比例
        // 会让 1024dp 的窗口只剩 260dp 的列表。
        SizedBox(
          key: const Key('notes_wide_list'),
          width: listWidth,
          child: list,
        ),
        // 细分隔线：本 App 无阴影，两栏之间只能靠一条 1dp 线 + 底色差分界。
        VerticalDivider(
          width: AppStroke.divider,
          thickness: AppStroke.divider,
          color: context.colors.divider,
        ),
        Expanded(
          child: selected == null
              ? const _EmptyPane()
              : NoteEditorPane(
                  // key 换笔记时整棵重建：controller / 水合状态都属于某一篇，
                  // 复用同一个 State 会把上一篇的草稿灌进新笔记。
                  key: ValueKey<String>(selected),
                  noteId: selected,
                  // 只有「新建」才看 folderId；已有笔记的归属由库读出。
                  folderId: selected == kNewNoteId ? newNoteFolderId : null,
                  embedded: true,
                  // 关闭前先落库：面板不是路由，没有 `PopScope` 兜底。
                  onClosed: () => _closePane(ref, selected),
                  onDeleted: notifier.clear,
                ),
        ),
      ],
    );
  }

  /// 关闭右侧面板：先把草稿落库，再清空选中。
  ///
  /// ⚠️ 落库必须在**清空选中之前**：`selectedNoteProvider` 一变，`NoteEditorPane`
  /// 就换 key 重建、旧 provider 失去监听者；虽然 dirty 期间有 `keepAlive` 兜底，
  /// 但那条链只保证「不丢」，不保证「立刻落库」。
  Future<void> _closePane(WidgetRef ref, String noteId) async {
    await ref
        .read(
          noteEditorProvider(
            noteId,
            folderId: noteId == kNewNoteId ? newNoteFolderId : null,
          ).notifier,
        )
        .flush();
    ref.read(selectedNoteProvider.notifier).clear();
  }
}

/// 右栏空态：一句主文案 + 一句浅色提示，垂直居中，不放插画。
class _EmptyPane extends StatelessWidget {
  const _EmptyPane();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return ColoredBox(
      // 与编辑面板同底色：选与不选之间切换时只有内容变化，没有色块跳动。
      color: colors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(
                icon: AppIcons.navNotes,
                size: 40,
                color: colors.textPlaceholder,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.notePaneEmptyTitle,
                style: context.textStyles.rowTitleStrong.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.notePaneEmptyHint,
                textAlign: TextAlign.center,
                style: context.textStyles.subtitle.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
