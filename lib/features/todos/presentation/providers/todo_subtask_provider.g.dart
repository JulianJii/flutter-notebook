// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_subtask_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅某条待办的子项。
///
/// ⛔ 不按 todoId 做 `autoDispose`：编辑弹窗开着时页面可能重建，让流断掉会让
/// 弹窗里的清单闪一下。子项列表是弹窗的局部状态，它的生命周期跟着弹窗走就够了。

@ProviderFor(todoSubtasks)
final todoSubtasksProvider = TodoSubtasksFamily._();

/// 订阅某条待办的子项。
///
/// ⛔ 不按 todoId 做 `autoDispose`：编辑弹窗开着时页面可能重建，让流断掉会让
/// 弹窗里的清单闪一下。子项列表是弹窗的局部状态，它的生命周期跟着弹窗走就够了。

final class TodoSubtasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TodoSubtask>>,
          List<TodoSubtask>,
          Stream<List<TodoSubtask>>
        >
    with
        $FutureModifier<List<TodoSubtask>>,
        $StreamProvider<List<TodoSubtask>> {
  /// 订阅某条待办的子项。
  ///
  /// ⛔ 不按 todoId 做 `autoDispose`：编辑弹窗开着时页面可能重建，让流断掉会让
  /// 弹窗里的清单闪一下。子项列表是弹窗的局部状态，它的生命周期跟着弹窗走就够了。
  TodoSubtasksProvider._({
    required TodoSubtasksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'todoSubtasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todoSubtasksHash();

  @override
  String toString() {
    return r'todoSubtasksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TodoSubtask>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TodoSubtask>> create(Ref ref) {
    final argument = this.argument as String;
    return todoSubtasks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodoSubtasksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todoSubtasksHash() => r'398b323ce7dd2b7c63a95266af9799257e008da0';

/// 订阅某条待办的子项。
///
/// ⛔ 不按 todoId 做 `autoDispose`：编辑弹窗开着时页面可能重建，让流断掉会让
/// 弹窗里的清单闪一下。子项列表是弹窗的局部状态，它的生命周期跟着弹窗走就够了。

final class TodoSubtasksFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TodoSubtask>>, String> {
  TodoSubtasksFamily._()
    : super(
        retry: null,
        name: r'todoSubtasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 订阅某条待办的子项。
  ///
  /// ⛔ 不按 todoId 做 `autoDispose`：编辑弹窗开着时页面可能重建，让流断掉会让
  /// 弹窗里的清单闪一下。子项列表是弹窗的局部状态，它的生命周期跟着弹窗走就够了。

  TodoSubtasksProvider call(String todoId) =>
      TodoSubtasksProvider._(argument: todoId, from: this);

  @override
  String toString() => r'todoSubtasksProvider';
}

/// 子项的增删改。
///
/// **没有乐观更新**：勾一个子项的代价是一次 SQLite 写（亚毫秒），而乐观层要处理
/// 「流回来的值比用户下一次点击更慢」这一类交错。笔记与待办的乐观层是为了扛住
/// 每次按键的全量序列化，子项没有这个量级 —— 给它加一层是把简单的事做复杂。
/// 失败信号走 [lastFailure] + 日志，与 `todoOverridesProvider` 同形。

@ProviderFor(TodoSubtaskController)
final todoSubtaskControllerProvider = TodoSubtaskControllerProvider._();

/// 子项的增删改。
///
/// **没有乐观更新**：勾一个子项的代价是一次 SQLite 写（亚毫秒），而乐观层要处理
/// 「流回来的值比用户下一次点击更慢」这一类交错。笔记与待办的乐观层是为了扛住
/// 每次按键的全量序列化，子项没有这个量级 —— 给它加一层是把简单的事做复杂。
/// 失败信号走 [lastFailure] + 日志，与 `todoOverridesProvider` 同形。
final class TodoSubtaskControllerProvider
    extends $NotifierProvider<TodoSubtaskController, TodoSubtaskState> {
  /// 子项的增删改。
  ///
  /// **没有乐观更新**：勾一个子项的代价是一次 SQLite 写（亚毫秒），而乐观层要处理
  /// 「流回来的值比用户下一次点击更慢」这一类交错。笔记与待办的乐观层是为了扛住
  /// 每次按键的全量序列化，子项没有这个量级 —— 给它加一层是把简单的事做复杂。
  /// 失败信号走 [lastFailure] + 日志，与 `todoOverridesProvider` 同形。
  TodoSubtaskControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoSubtaskControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoSubtaskControllerHash();

  @$internal
  @override
  TodoSubtaskController create() => TodoSubtaskController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoSubtaskState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoSubtaskState>(value),
    );
  }
}

String _$todoSubtaskControllerHash() =>
    r'19dd3f1051aab94e05b6589422e8f8b761e533d2';

/// 子项的增删改。
///
/// **没有乐观更新**：勾一个子项的代价是一次 SQLite 写（亚毫秒），而乐观层要处理
/// 「流回来的值比用户下一次点击更慢」这一类交错。笔记与待办的乐观层是为了扛住
/// 每次按键的全量序列化，子项没有这个量级 —— 给它加一层是把简单的事做复杂。
/// 失败信号走 [lastFailure] + 日志，与 `todoOverridesProvider` 同形。

abstract class _$TodoSubtaskController extends $Notifier<TodoSubtaskState> {
  TodoSubtaskState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TodoSubtaskState, TodoSubtaskState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TodoSubtaskState, TodoSubtaskState>,
              TodoSubtaskState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
