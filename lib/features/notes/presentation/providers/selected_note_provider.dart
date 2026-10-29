import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_note_provider.g.dart';

/// 宽屏双栏「右侧正在编辑哪一篇」。null = 未选（右侧显示空态）。
///
/// ⛔ **刻意不写进 URL**：
/// - URL 已被 `?folder=` / `?tag=` 占用（分类 `TabController` 的监听器会在
///   滑动时重写它），再塞一个 `note=` 就得在「切 tab 时保留还是丢弃」上做选择，
///   等于给同一个 URL 造第二个真相源。
/// - 双栏是**同一路由内的布局变化**，不是导航：窄屏与深链仍走 `/notes/:id`
///   整页路由，那边一个字都不用改。
/// - 桌面快捷键层（`desktop_shortcuts`）要读「面板里是哪篇」，provider 比
///   URL 直接（且对 `push` 出来的页面没有过期值问题）。
///
/// 值就是 `noteId`（[kNewNoteId] 表示新建），不缓存 `Note` 实体 —— 实体由
/// `noteListProvider` 的流提供，缓存一份就多一个会过期的副本。
@riverpod
class SelectedNote extends _$SelectedNote {
  @override
  String? build() => null;

  /// 选中某篇（`kNewNoteId` = 新建）。同值时 no-op，避免无意义重建。
  ///
  /// ⚠️ 切换前**不必**在这里 `flush` 上一篇：`NoteEditor` 在 dirty 期间自己
  /// `keepAlive`，旧草稿的 debounce 定时器照常跑完并落库（见该 provider 的
  /// `_scheduleSave`）。关闭面板时才显式 `flush`。
  void select(String id) {
    if (state == id) return;
    state = id;
  }

  /// 关闭右侧面板。
  void clear() {
    if (state == null) return;
    state = null;
  }
}
