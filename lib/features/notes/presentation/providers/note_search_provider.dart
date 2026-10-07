import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_search_provider.g.dart';

/// 笔记列表的搜索词。
///
/// ⛔ **不进 URL**：搜索是**临时的查询**，不是导航状态（同设置偏好的裁决，
/// `ARCHITECTURE-DESIGN.md` §8.2）。真要分享 / 回访某次搜索时再加 URL 参数，
/// 那时才需要跨页恢复。
///
/// ⛔ **不 debounce**：`LIKE '%term%'` 是全表扫描（`note_dao.dart` 已注明
/// 「搜索走参数化 LIKE，不是 FTS5」），本项目的笔记量级下单次几十微秒 —— 换
/// debounce 要多付一个 `Timer` 的生命周期管理。真卡了再上。
/// ponytail: 每键一次全表扫描。超过约 1 万条笔记、输入开始掉帧时，
/// 加 250ms debounce，或改 FTS5。
@riverpod
class NoteSearch extends _$NoteSearch {
  @override
  String build() => '';

  void set(String value) => state = value;
}