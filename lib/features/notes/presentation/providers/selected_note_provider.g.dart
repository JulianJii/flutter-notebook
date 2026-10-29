// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_note_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(SelectedNote)
final selectedNoteProvider = SelectedNoteProvider._();

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
final class SelectedNoteProvider
    extends $NotifierProvider<SelectedNote, String?> {
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
  SelectedNoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedNoteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedNoteHash();

  @$internal
  @override
  SelectedNote create() => SelectedNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedNoteHash() => r'12ab55a1b12d83e5bf62cee4dbeffd2a6ec4e00a';

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

abstract class _$SelectedNote extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
