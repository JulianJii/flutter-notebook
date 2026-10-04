// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅待办列表。**零逻辑**：一个 `ref.watch` + 一个 `call()`。
///
/// `AsyncValue` 天然覆盖 loading / ready / error，`empty` 是 `value.isEmpty` 的
/// **派生**而非状态字段（`ARCHITECTURE-DESIGN.md` §6.2 P2 + §11 ADR 3）。
/// ⛔ 不加 `ref.invalidate` 手动刷新：drift watch 变了自动推（§8.4）。

@ProviderFor(todoList)
final todoListProvider = TodoListProvider._();

/// 订阅待办列表。**零逻辑**：一个 `ref.watch` + 一个 `call()`。
///
/// `AsyncValue` 天然覆盖 loading / ready / error，`empty` 是 `value.isEmpty` 的
/// **派生**而非状态字段（`ARCHITECTURE-DESIGN.md` §6.2 P2 + §11 ADR 3）。
/// ⛔ 不加 `ref.invalidate` 手动刷新：drift watch 变了自动推（§8.4）。

final class TodoListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Todo>>,
          List<Todo>,
          Stream<List<Todo>>
        >
    with $FutureModifier<List<Todo>>, $StreamProvider<List<Todo>> {
  /// 订阅待办列表。**零逻辑**：一个 `ref.watch` + 一个 `call()`。
  ///
  /// `AsyncValue` 天然覆盖 loading / ready / error，`empty` 是 `value.isEmpty` 的
  /// **派生**而非状态字段（`ARCHITECTURE-DESIGN.md` §6.2 P2 + §11 ADR 3）。
  /// ⛔ 不加 `ref.invalidate` 手动刷新：drift watch 变了自动推（§8.4）。
  TodoListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoListHash();

  @$internal
  @override
  $StreamProviderElement<List<Todo>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Todo>> create(Ref ref) {
    return todoList(ref);
  }
}

String _$todoListHash() => r'2967067714c09d050cceb85e1051cec377fb5ea4';

/// 乐观覆盖层：仅在 `toggle` 与落库结果不一致期间生效。
///
/// **为什么不自持列表**（照抄 `TasksNotifier.toggleTask` 的写法）：它把列表 copy
/// 进 Notifier state，与 ADR 4「数据不进 Notifier，列表由 data 层 stream 持有」
/// 冲突，同一份数据两处写必然不一致；且 P1 的 `noteListProvider` 已确立
/// 「StreamProvider + AsyncValue」范式，P2 必须与之一致。
///
/// 核心洞察：**覆盖值等于 stream 值时覆盖就是无效的**（视觉完全一致），一旦不等
/// 它就是权威的。于是「何时清除覆盖」这个问题自动消失 —— 不需要 timer、不需要
/// listener、不需要等 stream 回调。
///
/// ponytail: map 只在 toggle 期间非空，条目为待办 uuid 字符串；155 条规模下
/// 累积上限 = 用户点击次数，可忽略。待办量到万级再考虑清理。

@ProviderFor(TodoOverrides)
final todoOverridesProvider = TodoOverridesProvider._();

/// 乐观覆盖层：仅在 `toggle` 与落库结果不一致期间生效。
///
/// **为什么不自持列表**（照抄 `TasksNotifier.toggleTask` 的写法）：它把列表 copy
/// 进 Notifier state，与 ADR 4「数据不进 Notifier，列表由 data 层 stream 持有」
/// 冲突，同一份数据两处写必然不一致；且 P1 的 `noteListProvider` 已确立
/// 「StreamProvider + AsyncValue」范式，P2 必须与之一致。
///
/// 核心洞察：**覆盖值等于 stream 值时覆盖就是无效的**（视觉完全一致），一旦不等
/// 它就是权威的。于是「何时清除覆盖」这个问题自动消失 —— 不需要 timer、不需要
/// listener、不需要等 stream 回调。
///
/// ponytail: map 只在 toggle 期间非空，条目为待办 uuid 字符串；155 条规模下
/// 累积上限 = 用户点击次数，可忽略。待办量到万级再考虑清理。
final class TodoOverridesProvider
    extends $NotifierProvider<TodoOverrides, Map<String, bool>> {
  /// 乐观覆盖层：仅在 `toggle` 与落库结果不一致期间生效。
  ///
  /// **为什么不自持列表**（照抄 `TasksNotifier.toggleTask` 的写法）：它把列表 copy
  /// 进 Notifier state，与 ADR 4「数据不进 Notifier，列表由 data 层 stream 持有」
  /// 冲突，同一份数据两处写必然不一致；且 P1 的 `noteListProvider` 已确立
  /// 「StreamProvider + AsyncValue」范式，P2 必须与之一致。
  ///
  /// 核心洞察：**覆盖值等于 stream 值时覆盖就是无效的**（视觉完全一致），一旦不等
  /// 它就是权威的。于是「何时清除覆盖」这个问题自动消失 —— 不需要 timer、不需要
  /// listener、不需要等 stream 回调。
  ///
  /// ponytail: map 只在 toggle 期间非空，条目为待办 uuid 字符串；155 条规模下
  /// 累积上限 = 用户点击次数，可忽略。待办量到万级再考虑清理。
  TodoOverridesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoOverridesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoOverridesHash();

  @$internal
  @override
  TodoOverrides create() => TodoOverrides();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, bool>>(value),
    );
  }
}

String _$todoOverridesHash() => r'6cbb465ec02e3d81ea02d9441b27d3f69c494dad';

/// 乐观覆盖层：仅在 `toggle` 与落库结果不一致期间生效。
///
/// **为什么不自持列表**（照抄 `TasksNotifier.toggleTask` 的写法）：它把列表 copy
/// 进 Notifier state，与 ADR 4「数据不进 Notifier，列表由 data 层 stream 持有」
/// 冲突，同一份数据两处写必然不一致；且 P1 的 `noteListProvider` 已确立
/// 「StreamProvider + AsyncValue」范式，P2 必须与之一致。
///
/// 核心洞察：**覆盖值等于 stream 值时覆盖就是无效的**（视觉完全一致），一旦不等
/// 它就是权威的。于是「何时清除覆盖」这个问题自动消失 —— 不需要 timer、不需要
/// listener、不需要等 stream 回调。
///
/// ponytail: map 只在 toggle 期间非空，条目为待办 uuid 字符串；155 条规模下
/// 累积上限 = 用户点击次数，可忽略。待办量到万级再考虑清理。

abstract class _$TodoOverrides extends $Notifier<Map<String, bool>> {
  Map<String, bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, bool>, Map<String, bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, bool>, Map<String, bool>>,
              Map<String, bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
