// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 笔记列表的多选状态（长按进入）。
///
/// **选中集非空 = 处于多选模式**，不另设 `isSelecting` 标志位：第二个真相源
/// 必然会漂移（清空了集合还亮着选择顶栏，或反过来）。长按一张卡 = toggle，
/// 取消唯一选中项即自然退出模式。
///
/// ⛔ 只存 id，不存 `Note`：列表流刷新后实体会换代，缓存实体只会造成
/// 「选中卡显示的是旧数据」。置顶 / 收藏的翻转语义由 UI 拿当前列表现算。

@ProviderFor(NoteSelection)
final noteSelectionProvider = NoteSelectionProvider._();

/// 笔记列表的多选状态（长按进入）。
///
/// **选中集非空 = 处于多选模式**，不另设 `isSelecting` 标志位：第二个真相源
/// 必然会漂移（清空了集合还亮着选择顶栏，或反过来）。长按一张卡 = toggle，
/// 取消唯一选中项即自然退出模式。
///
/// ⛔ 只存 id，不存 `Note`：列表流刷新后实体会换代，缓存实体只会造成
/// 「选中卡显示的是旧数据」。置顶 / 收藏的翻转语义由 UI 拿当前列表现算。
final class NoteSelectionProvider
    extends $NotifierProvider<NoteSelection, Set<String>> {
  /// 笔记列表的多选状态（长按进入）。
  ///
  /// **选中集非空 = 处于多选模式**，不另设 `isSelecting` 标志位：第二个真相源
  /// 必然会漂移（清空了集合还亮着选择顶栏，或反过来）。长按一张卡 = toggle，
  /// 取消唯一选中项即自然退出模式。
  ///
  /// ⛔ 只存 id，不存 `Note`：列表流刷新后实体会换代，缓存实体只会造成
  /// 「选中卡显示的是旧数据」。置顶 / 收藏的翻转语义由 UI 拿当前列表现算。
  NoteSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteSelectionHash();

  @$internal
  @override
  NoteSelection create() => NoteSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$noteSelectionHash() => r'8df838c0d26e48d676a311b3cfa623e876c501ff';

/// 笔记列表的多选状态（长按进入）。
///
/// **选中集非空 = 处于多选模式**，不另设 `isSelecting` 标志位：第二个真相源
/// 必然会漂移（清空了集合还亮着选择顶栏，或反过来）。长按一张卡 = toggle，
/// 取消唯一选中项即自然退出模式。
///
/// ⛔ 只存 id，不存 `Note`：列表流刷新后实体会换代，缓存实体只会造成
/// 「选中卡显示的是旧数据」。置顶 / 收藏的翻转语义由 UI 拿当前列表现算。

abstract class _$NoteSelection extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
