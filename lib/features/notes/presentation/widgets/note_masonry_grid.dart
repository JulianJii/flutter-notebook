import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/app_bottom_nav.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/entities/note.dart';
import 'note_card.dart';

/// 笔记列表稿的笔记列表容器：自适应列数的瀑布流。
///
/// 接收**已就绪的** `List<Note>`，自己不 `ref.watch` 任何 provider ——
/// 数据订阅归 `NoteListScreen`。
class NoteMasonryGrid extends StatelessWidget {
  const NoteMasonryGrid({
    required this.notes,
    super.key,
    this.onTapNote,
    this.onLongPressNote,
    this.onContextMenuNote,
    this.selectedIds = const <String>{},
  });

  final List<Note> notes;

  /// null → 卡片静态（按压态沿用 Material 默认）。
  final ValueChanged<Note>? onTapNote;

  /// 长按回调（多选入口）。null → 卡片无长按行为。
  final ValueChanged<Note>? onLongPressNote;

  /// 右键（桌面）：第二参是**全局坐标**，菜单在指针处弹出。
  final void Function(Note note, Offset globalPosition)? onContextMenuNote;

  /// 多选选中的笔记 id 集合（多选模式下卡片描边 + 勾选角标）。
  final Set<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      // 空状态不建视觉（回收站 / 待办 / 搜索无结果同理，都是内联几行）。
      return const SizedBox.shrink();
    }

    // 列数按**本组件拿到的可用宽度**现算，而不是读屏幕宽度：
    // 双栏布局下这里只是 380dp 的侧栏，用窗口宽度会算出 4 列、卡片挤成纸条。
    // ⚠️ `LayoutBuilder` 的宽度**含**左右页面边距，故先减掉再算卡宽。
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - AppSpacing.pageH * 2;
        final columns = (usable / _minColumnWidth).floor().clamp(2, 6);

        return MasonryGridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.gridRow,
          crossAxisSpacing: AppSpacing.gridGutter,
          padding: _padding(context),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return NoteCard(
              key: ValueKey<String>(note.id),
              note: note,
              selected: selectedIds.contains(note.id),
              onTap: onTapNote == null ? null : () => onTapNote!(note),
              onLongPress: onLongPressNote == null
                  ? null
                  : () => onLongPressNote!(note),
              onSecondaryTapDown: onContextMenuNote == null
                  ? null
                  : (details) =>
                        onContextMenuNote!(note, details.globalPosition),
            );
          },
        );
      },
    );
  }

  /// 单列目标宽度。取 220dp：手机 360dp 屏 (336 可用) 除下来是 1.5 → 夹到 2 列，
  /// 与设计稿的 2 列**逐像素一致**；660dp 起真 3 列，880dp 起 4 列。
  static const double _minColumnWidth = 220;

  /// 底部留白必须补 `navBottomInsetOf` ——笔记列表稿里卡片被底部导航与 FAB
  /// 直接裁切，那是**设计稿缺陷**。同一个值也用于笔记列表/待办的 FAB 定位，
  /// 宽屏无底栏时自动归零。
  EdgeInsets _padding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      AppSpacing.pageH,
      0,
      AppSpacing.pageH,
      listBottomInsetOf(context),
    );
  }
}

// 分列交给 MasonryGridView 默认的「更短列优先」，零自绘。
