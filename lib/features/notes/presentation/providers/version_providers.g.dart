// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 一篇笔记的版本历史（新→旧）。历史页的数据源。

@ProviderFor(noteHistory)
final noteHistoryProvider = NoteHistoryFamily._();

/// 一篇笔记的版本历史（新→旧）。历史页的数据源。

final class NoteHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NoteVersion>>,
          List<NoteVersion>,
          Stream<List<NoteVersion>>
        >
    with
        $FutureModifier<List<NoteVersion>>,
        $StreamProvider<List<NoteVersion>> {
  /// 一篇笔记的版本历史（新→旧）。历史页的数据源。
  NoteHistoryProvider._({
    required NoteHistoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noteHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteHistoryHash();

  @override
  String toString() {
    return r'noteHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<NoteVersion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NoteVersion>> create(Ref ref) {
    final argument = this.argument as String;
    return noteHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteHistoryHash() => r'a7a3073cccf479e41605129686a39ae1204f903d';

/// 一篇笔记的版本历史（新→旧）。历史页的数据源。

final class NoteHistoryFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<NoteVersion>>, String> {
  NoteHistoryFamily._()
    : super(
        retry: null,
        name: r'noteHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 一篇笔记的版本历史（新→旧）。历史页的数据源。

  NoteHistoryProvider call(String noteId) =>
      NoteHistoryProvider._(argument: noteId, from: this);

  @override
  String toString() => r'noteHistoryProvider';
}

/// 单个版本的**一次性读**（预览页用，与标签展示行同一取舍：不常驻订阅）。

@ProviderFor(noteVersion)
final noteVersionProvider = NoteVersionFamily._();

/// 单个版本的**一次性读**（预览页用，与标签展示行同一取舍：不常驻订阅）。

final class NoteVersionProvider
    extends
        $FunctionalProvider<
          AsyncValue<NoteVersion>,
          NoteVersion,
          FutureOr<NoteVersion>
        >
    with $FutureModifier<NoteVersion>, $FutureProvider<NoteVersion> {
  /// 单个版本的**一次性读**（预览页用，与标签展示行同一取舍：不常驻订阅）。
  NoteVersionProvider._({
    required NoteVersionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noteVersionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteVersionHash();

  @override
  String toString() {
    return r'noteVersionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<NoteVersion> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NoteVersion> create(Ref ref) {
    final argument = this.argument as String;
    return noteVersion(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteVersionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteVersionHash() => r'73995b7c6b834a5a8ef957ceef1fa1ec6e2fcbbc';

/// 单个版本的**一次性读**（预览页用，与标签展示行同一取舍：不常驻订阅）。

final class NoteVersionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<NoteVersion>, String> {
  NoteVersionFamily._()
    : super(
        retry: null,
        name: r'noteVersionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 单个版本的**一次性读**（预览页用，与标签展示行同一取舍：不常驻订阅）。

  NoteVersionProvider call(String versionId) =>
      NoteVersionProvider._(argument: versionId, from: this);

  @override
  String toString() => r'noteVersionProvider';
}
