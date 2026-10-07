import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';
import 'note_card.dart';

/// 笔记列表稿的笔记列表容器：2 列瀑布流。
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

  /// 设置「文字大小」的排版系数，透传给每张 [NoteCard]。⛔ 必填无默认。
  final double textScale;

  /// null → 卡片静态（按压态沿用 Material 默认）。
  final ValueChanged<Note>? onTapNote;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      // 空状态不建视觉（回收站 / 待办 / 搜索无结果同理，都是内联几行）。
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

  /// 列数。笔记列表稿实测 2 列；宽屏断点无稿，不擅自加。
  static const int _columns = 2;

  /// 底部留白必须补 `kBottomNavContentHeight` ——笔记列表稿里卡片被底部导航与 FAB
  /// 直接裁切，那是**设计稿缺陷**（`UI-IMPLEMENTATION-SPEC.md` §2.3
  /// `space.bottomSafe`「需补」）。同一个常量也用于笔记列表/待办的 FAB 定位。
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

// 分列交给 MasonryGridView 默认的「更短列优先」，零自绘。
