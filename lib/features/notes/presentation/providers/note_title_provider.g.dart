// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_title_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 一篇笔记的标题（一次性读）。给待办卡上的「挂接笔记」chip 用：
/// 挂接是低频状态，为每个 chip 常驻一条笔记流是浪费；读不到（笔记已被
/// 物理清扫）返回空串，由 UI 兜底提示（见 `TodoCard` 的挂接 chip）。

@ProviderFor(noteTitle)
final noteTitleProvider = NoteTitleFamily._();

/// 一篇笔记的标题（一次性读）。给待办卡上的「挂接笔记」chip 用：
/// 挂接是低频状态，为每个 chip 常驻一条笔记流是浪费；读不到（笔记已被
/// 物理清扫）返回空串，由 UI 兜底提示（见 `TodoCard` 的挂接 chip）。

final class NoteTitleProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// 一篇笔记的标题（一次性读）。给待办卡上的「挂接笔记」chip 用：
  /// 挂接是低频状态，为每个 chip 常驻一条笔记流是浪费；读不到（笔记已被
  /// 物理清扫）返回空串，由 UI 兜底提示（见 `TodoCard` 的挂接 chip）。
  NoteTitleProvider._({
    required NoteTitleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noteTitleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteTitleHash();

  @override
  String toString() {
    return r'noteTitleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return noteTitle(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteTitleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteTitleHash() => r'997c9cc1f10098bc8d23a05255b5a133fdb0a14e';

/// 一篇笔记的标题（一次性读）。给待办卡上的「挂接笔记」chip 用：
/// 挂接是低频状态，为每个 chip 常驻一条笔记流是浪费；读不到（笔记已被
/// 物理清扫）返回空串，由 UI 兜底提示（见 `TodoCard` 的挂接 chip）。

final class NoteTitleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  NoteTitleFamily._()
    : super(
        retry: null,
        name: r'noteTitleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一篇笔记的标题（一次性读）。给待办卡上的「挂接笔记」chip 用：
  /// 挂接是低频状态，为每个 chip 常驻一条笔记流是浪费；读不到（笔记已被
  /// 物理清扫）返回空串，由 UI 兜底提示（见 `TodoCard` 的挂接 chip）。

  NoteTitleProvider call(String noteId) =>
      NoteTitleProvider._(argument: noteId, from: this);

  @override
  String toString() => r'noteTitleProvider';
}
