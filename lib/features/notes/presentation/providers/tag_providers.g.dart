// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全部标签（含存活笔记数，name ASC）。标签筛选弹层与标签管理页共用，
/// 数据链路固定 Screen → 本 provider → UseCase → Repository。

@ProviderFor(tagList)
final tagListProvider = TagListProvider._();

/// 全部标签（含存活笔记数，name ASC）。标签筛选弹层与标签管理页共用，
/// 数据链路固定 Screen → 本 provider → UseCase → Repository。

final class TagListProvider
    extends
        $FunctionalProvider<AsyncValue<List<Tag>>, List<Tag>, Stream<List<Tag>>>
    with $FutureModifier<List<Tag>>, $StreamProvider<List<Tag>> {
  /// 全部标签（含存活笔记数，name ASC）。标签筛选弹层与标签管理页共用，
  /// 数据链路固定 Screen → 本 provider → UseCase → Repository。
  TagListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagListHash();

  @$internal
  @override
  $StreamProviderElement<List<Tag>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Tag>> create(Ref ref) {
    return tagList(ref);
  }
}

String _$tagListHash() => r'f02637316a59268baa4ca45ebcd57d8d2298ba15';

/// 一篇笔记标签名的**一次性读**。详情页的展示行用它而非流 —— 常驻 drift 流
/// 在测试 teardown 会留一个「关流 Timer」，炸 flutter_test 的 pending-timer
/// 不变量；一行展示也不值得常驻订阅。[version] 无业务语义，只用于
/// 「打标弹层保存完 +1 强制重查」。

@ProviderFor(noteTagsSnapshot)
final noteTagsSnapshotProvider = NoteTagsSnapshotFamily._();

/// 一篇笔记标签名的**一次性读**。详情页的展示行用它而非流 —— 常驻 drift 流
/// 在测试 teardown 会留一个「关流 Timer」，炸 flutter_test 的 pending-timer
/// 不变量；一行展示也不值得常驻订阅。[version] 无业务语义，只用于
/// 「打标弹层保存完 +1 强制重查」。

final class NoteTagsSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// 一篇笔记标签名的**一次性读**。详情页的展示行用它而非流 —— 常驻 drift 流
  /// 在测试 teardown 会留一个「关流 Timer」，炸 flutter_test 的 pending-timer
  /// 不变量；一行展示也不值得常驻订阅。[version] 无业务语义，只用于
  /// 「打标弹层保存完 +1 强制重查」。
  NoteTagsSnapshotProvider._({
    required NoteTagsSnapshotFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'noteTagsSnapshotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteTagsSnapshotHash();

  @override
  String toString() {
    return r'noteTagsSnapshotProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return noteTagsSnapshot(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteTagsSnapshotProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteTagsSnapshotHash() => r'b5ac1b1a75eed0d2bbb926a171aceb5e4e910a65';

/// 一篇笔记标签名的**一次性读**。详情页的展示行用它而非流 —— 常驻 drift 流
/// 在测试 teardown 会留一个「关流 Timer」，炸 flutter_test 的 pending-timer
/// 不变量；一行展示也不值得常驻订阅。[version] 无业务语义，只用于
/// 「打标弹层保存完 +1 强制重查」。

final class NoteTagsSnapshotFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, (String, int)> {
  NoteTagsSnapshotFamily._()
    : super(
        retry: null,
        name: r'noteTagsSnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一篇笔记标签名的**一次性读**。详情页的展示行用它而非流 —— 常驻 drift 流
  /// 在测试 teardown 会留一个「关流 Timer」，炸 flutter_test 的 pending-timer
  /// 不变量；一行展示也不值得常驻订阅。[version] 无业务语义，只用于
  /// 「打标弹层保存完 +1 强制重查」。

  NoteTagsSnapshotProvider call(String noteId, int version) =>
      NoteTagsSnapshotProvider._(argument: (noteId, version), from: this);

  @override
  String toString() => r'noteTagsSnapshotProvider';
}
