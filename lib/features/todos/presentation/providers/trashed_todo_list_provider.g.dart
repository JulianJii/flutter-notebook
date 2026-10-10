// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trashed_todo_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅回收站里的待办（软删除的，按删除时间倒序）。
///
/// 与 `todoListProvider` 同约定：drift watch 推流，恢复 / 永久删除后 UI 自动
/// 重建，调用方无需手动 invalidate。
///
/// ⛔ 放在 features/todos 而不是 notes：数据源是 `TodoRepository`，让 notes 的
/// 屏反向依赖 todos 的 provider 就成了 feature 之间的耦合。回收站屏**主动**
/// import 它（见 `RecentlyDeletedScreen`）—— 页面复用是允许的方向。

@ProviderFor(trashedTodoList)
final trashedTodoListProvider = TrashedTodoListProvider._();

/// 订阅回收站里的待办（软删除的，按删除时间倒序）。
///
/// 与 `todoListProvider` 同约定：drift watch 推流，恢复 / 永久删除后 UI 自动
/// 重建，调用方无需手动 invalidate。
///
/// ⛔ 放在 features/todos 而不是 notes：数据源是 `TodoRepository`，让 notes 的
/// 屏反向依赖 todos 的 provider 就成了 feature 之间的耦合。回收站屏**主动**
/// import 它（见 `RecentlyDeletedScreen`）—— 页面复用是允许的方向。

final class TrashedTodoListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Todo>>,
          List<Todo>,
          Stream<List<Todo>>
        >
    with $FutureModifier<List<Todo>>, $StreamProvider<List<Todo>> {
  /// 订阅回收站里的待办（软删除的，按删除时间倒序）。
  ///
  /// 与 `todoListProvider` 同约定：drift watch 推流，恢复 / 永久删除后 UI 自动
  /// 重建，调用方无需手动 invalidate。
  ///
  /// ⛔ 放在 features/todos 而不是 notes：数据源是 `TodoRepository`，让 notes 的
  /// 屏反向依赖 todos 的 provider 就成了 feature 之间的耦合。回收站屏**主动**
  /// import 它（见 `RecentlyDeletedScreen`）—— 页面复用是允许的方向。
  TrashedTodoListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trashedTodoListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trashedTodoListHash();

  @$internal
  @override
  $StreamProviderElement<List<Todo>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Todo>> create(Ref ref) {
    return trashedTodoList(ref);
  }
}

String _$trashedTodoListHash() => r'3f59a8922915f08c46f2c2f5629f342087e122c9';
