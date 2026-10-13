import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_selection_provider.g.dart';

/// 笔记列表的多选状态（长按进入）。
///
/// **选中集非空 = 处于多选模式**，不另设 `isSelecting` 标志位：第二个真相源
/// 必然会漂移（清空了集合还亮着选择顶栏，或反过来）。长按一张卡 = toggle，
/// 取消唯一选中项即自然退出模式。
///
/// ⛔ 只存 id，不存 `Note`：列表流刷新后实体会换代，缓存实体只会造成
/// 「选中卡显示的是旧数据」。置顶 / 收藏的翻转语义由 UI 拿当前列表现算。
@riverpod
class NoteSelection extends _$NoteSelection {
  @override
  Set<String> build() => const <String>{};

  /// 长按 / 多选态下点按。
  void toggle(String noteId) {
    final next = <String>{...state};
    if (!next.remove(noteId)) next.add(noteId);
    state = next;
  }

  /// 全选 / 取消全选（按当前分类的可见笔记）。
  void setAll(Iterable<String> noteIds) {
    state = <String>{...noteIds};
  }

  /// 批量动作完成后退出多选。
  void clear() => state = const <String>{};
}
