import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';
import 'note_card.dart';

/// D1 的笔记列表容器：2 列瀑布流。
///
/// 接收**已就绪的** `List<Note>`，自己不 `ref.watch` 任何 provider ——
/// 数据订阅归 `NoteListScreen`（`ARCHITECTURE-DESIGN.md` §2.1 约束 6）。
class NoteMasonryGrid extends StatelessWidget {
  const NoteMasonryGrid({
    required this.notes,
    required this.textScale,
    super.key,
    this.onTapNote,
  });

  final List<Note> notes;

  /// P5「文字大小」的排版系数，透传给每张 [NoteCard]。⛔ 必填无默认。
  final double textScale;

  /// null → 卡片静态（按压态无稿，见 Q35）。
  final ValueChanged<Note>? onTapNote;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      // Q31 → docs/OPEN-DESIGN-QUESTIONS.md（空状态无稿，不建视觉）
      return const SizedBox.shrink();
    }

    return MasonryGridView.count(
      crossAxisCount: _columns,
      mainAxisSpacing: AppSpacing.gridRow,
      crossAxisSpacing: AppSpacing.gridGutter,
      padding: _padding(context),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          key: ValueKey<String>(note.id),
          note: note,
          textScale: textScale,
          onTap: onTapNote == null ? null : () => onTapNote!(note),
        );
      },
    );
  }

  /// 列数。D1 实测 2 列；宽屏断点无稿（Q27），不擅自加。
  static const int _columns = 2;

  /// 底部留白必须补 `kBottomNavContentHeight` —— D1 里卡片被底部导航与 FAB
  /// 直接裁切，那是**设计稿缺陷**（`UI-IMPLEMENTATION-SPEC.md` §2.3
  /// `space.bottomSafe`「需补」）。同一个常量也用于 P1/P2 的 FAB 定位。
  EdgeInsets _padding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      AppSpacing.pageH,
      0,
      AppSpacing.pageH,
      kBottomNavContentHeight +
          AppSpacing.pageH +
          MediaQuery.paddingOf(context).bottom,
    );
  }
}

// Q19b → docs/OPEN-DESIGN-QUESTIONS.md（用 MasonryGridView 默认的更短列优先）
