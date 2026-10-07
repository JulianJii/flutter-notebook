// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅笔记列表。参数族按 [NoteQuery] 定位：相同 query 复用同一个 stream，
/// 不同 query 各自独立（依赖 `NoteQuery` 的值相等，见 `note_query.dart`）。
///
/// 排序**不在 provider 里注入**：调用方（笔记列表，`NoteListScreen`）把偏好的
/// 排序填进 `NoteQuery.sort` 再传进来。理由有二：一是本 provider 保持零偏好依赖
/// （Phase 4 的东西不因 Phase 7 变质），二是「哪个 query 在看」由页面决定，
/// provider 无从判断该不该改排序。
///
/// 文件夹筛选来自 URL（`?folder=xxx`）而不是全局 state
/// （`ARCHITECTURE-DESIGN.md` §8.2 / §8.5）：存成内存 state 会让 chip 高亮态
/// 与 URL 成为两个真相源。调用方从 `GoRouterState` 读出 query param 后组装
/// `NoteQuery` 传进来，本 provider 因此不 import `go_router`，单测零路由依赖。

@ProviderFor(noteList)
final noteListProvider = NoteListFamily._();

/// 订阅笔记列表。参数族按 [NoteQuery] 定位：相同 query 复用同一个 stream，
/// 不同 query 各自独立（依赖 `NoteQuery` 的值相等，见 `note_query.dart`）。
///
/// 排序**不在 provider 里注入**：调用方（笔记列表，`NoteListScreen`）把偏好的
/// 排序填进 `NoteQuery.sort` 再传进来。理由有二：一是本 provider 保持零偏好依赖
/// （Phase 4 的东西不因 Phase 7 变质），二是「哪个 query 在看」由页面决定，
/// provider 无从判断该不该改排序。
///
/// 文件夹筛选来自 URL（`?folder=xxx`）而不是全局 state
/// （`ARCHITECTURE-DESIGN.md` §8.2 / §8.5）：存成内存 state 会让 chip 高亮态
/// 与 URL 成为两个真相源。调用方从 `GoRouterState` 读出 query param 后组装
/// `NoteQuery` 传进来，本 provider 因此不 import `go_router`，单测零路由依赖。

final class NoteListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          Stream<List<Note>>
        >
    with $FutureModifier<List<Note>>, $StreamProvider<List<Note>> {
  /// 订阅笔记列表。参数族按 [NoteQuery] 定位：相同 query 复用同一个 stream，
  /// 不同 query 各自独立（依赖 `NoteQuery` 的值相等，见 `note_query.dart`）。
  ///
  /// 排序**不在 provider 里注入**：调用方（笔记列表，`NoteListScreen`）把偏好的
  /// 排序填进 `NoteQuery.sort` 再传进来。理由有二：一是本 provider 保持零偏好依赖
  /// （Phase 4 的东西不因 Phase 7 变质），二是「哪个 query 在看」由页面决定，
  /// provider 无从判断该不该改排序。
  ///
  /// 文件夹筛选来自 URL（`?folder=xxx`）而不是全局 state
  /// （`ARCHITECTURE-DESIGN.md` §8.2 / §8.5）：存成内存 state 会让 chip 高亮态
  /// 与 URL 成为两个真相源。调用方从 `GoRouterState` 读出 query param 后组装
  /// `NoteQuery` 传进来，本 provider 因此不 import `go_router`，单测零路由依赖。
  NoteListProvider._({
    required NoteListFamily super.from,
    required NoteQuery super.argument,
  }) : super(
         retry: null,
         name: r'noteListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteListHash();

  @override
  String toString() {
    return r'noteListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Note>> create(Ref ref) {
    final argument = this.argument as NoteQuery;
    return noteList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteListHash() => r'2c8b40fb4317254c0765d2a71adb3e0165bcf3de';

/// 订阅笔记列表。参数族按 [NoteQuery] 定位：相同 query 复用同一个 stream，
/// 不同 query 各自独立（依赖 `NoteQuery` 的值相等，见 `note_query.dart`）。
///
/// 排序**不在 provider 里注入**：调用方（笔记列表，`NoteListScreen`）把偏好的
/// 排序填进 `NoteQuery.sort` 再传进来。理由有二：一是本 provider 保持零偏好依赖
/// （Phase 4 的东西不因 Phase 7 变质），二是「哪个 query 在看」由页面决定，
/// provider 无从判断该不该改排序。
///
/// 文件夹筛选来自 URL（`?folder=xxx`）而不是全局 state
/// （`ARCHITECTURE-DESIGN.md` §8.2 / §8.5）：存成内存 state 会让 chip 高亮态
/// 与 URL 成为两个真相源。调用方从 `GoRouterState` 读出 query param 后组装
/// `NoteQuery` 传进来，本 provider 因此不 import `go_router`，单测零路由依赖。

final class NoteListFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Note>>, NoteQuery> {
  NoteListFamily._()
    : super(
        retry: null,
        name: r'noteListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 订阅笔记列表。参数族按 [NoteQuery] 定位：相同 query 复用同一个 stream，
  /// 不同 query 各自独立（依赖 `NoteQuery` 的值相等，见 `note_query.dart`）。
  ///
  /// 排序**不在 provider 里注入**：调用方（笔记列表，`NoteListScreen`）把偏好的
  /// 排序填进 `NoteQuery.sort` 再传进来。理由有二：一是本 provider 保持零偏好依赖
  /// （Phase 4 的东西不因 Phase 7 变质），二是「哪个 query 在看」由页面决定，
  /// provider 无从判断该不该改排序。
  ///
  /// 文件夹筛选来自 URL（`?folder=xxx`）而不是全局 state
  /// （`ARCHITECTURE-DESIGN.md` §8.2 / §8.5）：存成内存 state 会让 chip 高亮态
  /// 与 URL 成为两个真相源。调用方从 `GoRouterState` 读出 query param 后组装
  /// `NoteQuery` 传进来，本 provider 因此不 import `go_router`，单测零路由依赖。

  NoteListProvider call(NoteQuery query) =>
      NoteListProvider._(argument: query, from: this);

  @override
  String toString() => r'noteListProvider';
}
