// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// P1 的搜索词。
///
/// ⛔ **不进 URL**：搜索是**临时的查询**，不是导航状态（同 P5 偏好的裁决，
/// `ARCHITECTURE-DESIGN.md` §8.2）。真要分享 / 回访某次搜索时再加 URL 参数，
/// 那时才需要跨页恢复。
///
/// ⛔ **不 debounce**：`LIKE '%term%'` 是全表扫描（`note_dao.dart` 已注明
/// 「搜索走参数化 LIKE，不是 FTS5」），本项目的笔记量级下单次几十微秒 —— 换
/// debounce 要多付一个 `Timer` 的生命周期管理。真卡了再上。
/// ponytail: 每键一次全表扫描。超过约 1 万条笔记、输入开始掉帧时，
/// 加 250ms debounce，或改 FTS5。

@ProviderFor(NoteSearch)
final noteSearchProvider = NoteSearchProvider._();

/// P1 的搜索词。
///
/// ⛔ **不进 URL**：搜索是**临时的查询**，不是导航状态（同 P5 偏好的裁决，
/// `ARCHITECTURE-DESIGN.md` §8.2）。真要分享 / 回访某次搜索时再加 URL 参数，
/// 那时才需要跨页恢复。
///
/// ⛔ **不 debounce**：`LIKE '%term%'` 是全表扫描（`note_dao.dart` 已注明
/// 「搜索走参数化 LIKE，不是 FTS5」），本项目的笔记量级下单次几十微秒 —— 换
/// debounce 要多付一个 `Timer` 的生命周期管理。真卡了再上。
/// ponytail: 每键一次全表扫描。超过约 1 万条笔记、输入开始掉帧时，
/// 加 250ms debounce，或改 FTS5。
final class NoteSearchProvider extends $NotifierProvider<NoteSearch, String> {
  /// P1 的搜索词。
  ///
  /// ⛔ **不进 URL**：搜索是**临时的查询**，不是导航状态（同 P5 偏好的裁决，
  /// `ARCHITECTURE-DESIGN.md` §8.2）。真要分享 / 回访某次搜索时再加 URL 参数，
  /// 那时才需要跨页恢复。
  ///
  /// ⛔ **不 debounce**：`LIKE '%term%'` 是全表扫描（`note_dao.dart` 已注明
  /// 「搜索走参数化 LIKE，不是 FTS5」），本项目的笔记量级下单次几十微秒 —— 换
  /// debounce 要多付一个 `Timer` 的生命周期管理。真卡了再上。
  /// ponytail: 每键一次全表扫描。超过约 1 万条笔记、输入开始掉帧时，
  /// 加 250ms debounce，或改 FTS5。
  NoteSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteSearchHash();

  @$internal
  @override
  NoteSearch create() => NoteSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$noteSearchHash() => r'e7bb19aaa7c6fdf2d185b9872e7200c8d08b4476';

/// P1 的搜索词。
///
/// ⛔ **不进 URL**：搜索是**临时的查询**，不是导航状态（同 P5 偏好的裁决，
/// `ARCHITECTURE-DESIGN.md` §8.2）。真要分享 / 回访某次搜索时再加 URL 参数，
/// 那时才需要跨页恢复。
///
/// ⛔ **不 debounce**：`LIKE '%term%'` 是全表扫描（`note_dao.dart` 已注明
/// 「搜索走参数化 LIKE，不是 FTS5」），本项目的笔记量级下单次几十微秒 —— 换
/// debounce 要多付一个 `Timer` 的生命周期管理。真卡了再上。
/// ponytail: 每键一次全表扫描。超过约 1 万条笔记、输入开始掉帧时，
/// 加 250ms debounce，或改 FTS5。

abstract class _$NoteSearch extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
