// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_editor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 笔记编辑器（`/notes/:id` 与 `/notes/new` 共用）。
///
/// **自动保存不是过度设计**（`ARCHITECTURE-DESIGN.md` §4 P3）：D3 没有保存按钮、
/// 没有未保存提示，「不保存就是数据丢失」。故停止输入 500ms 后自动落库。

@ProviderFor(NoteEditor)
final noteEditorProvider = NoteEditorFamily._();

/// 笔记编辑器（`/notes/:id` 与 `/notes/new` 共用）。
///
/// **自动保存不是过度设计**（`ARCHITECTURE-DESIGN.md` §4 P3）：D3 没有保存按钮、
/// 没有未保存提示，「不保存就是数据丢失」。故停止输入 500ms 后自动落库。
final class NoteEditorProvider
    extends $AsyncNotifierProvider<NoteEditor, NoteEditorState> {
  /// 笔记编辑器（`/notes/:id` 与 `/notes/new` 共用）。
  ///
  /// **自动保存不是过度设计**（`ARCHITECTURE-DESIGN.md` §4 P3）：D3 没有保存按钮、
  /// 没有未保存提示，「不保存就是数据丢失」。故停止输入 500ms 后自动落库。
  NoteEditorProvider._({
    required NoteEditorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'noteEditorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteEditorHash();

  @override
  String toString() {
    return r'noteEditorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NoteEditor create() => NoteEditor();

  @override
  bool operator ==(Object other) {
    return other is NoteEditorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteEditorHash() => r'5319afa1465f1fe61feaca39b934917d9509c313';

/// 笔记编辑器（`/notes/:id` 与 `/notes/new` 共用）。
///
/// **自动保存不是过度设计**（`ARCHITECTURE-DESIGN.md` §4 P3）：D3 没有保存按钮、
/// 没有未保存提示，「不保存就是数据丢失」。故停止输入 500ms 后自动落库。

final class NoteEditorFamily extends $Family
    with
        $ClassFamilyOverride<
          NoteEditor,
          AsyncValue<NoteEditorState>,
          NoteEditorState,
          FutureOr<NoteEditorState>,
          String
        > {
  NoteEditorFamily._()
    : super(
        retry: null,
        name: r'noteEditorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 笔记编辑器（`/notes/:id` 与 `/notes/new` 共用）。
  ///
  /// **自动保存不是过度设计**（`ARCHITECTURE-DESIGN.md` §4 P3）：D3 没有保存按钮、
  /// 没有未保存提示，「不保存就是数据丢失」。故停止输入 500ms 后自动落库。

  NoteEditorProvider call(String noteId) =>
      NoteEditorProvider._(argument: noteId, from: this);

  @override
  String toString() => r'noteEditorProvider';
}

/// 笔记编辑器（`/notes/:id` 与 `/notes/new` 共用）。
///
/// **自动保存不是过度设计**（`ARCHITECTURE-DESIGN.md` §4 P3）：D3 没有保存按钮、
/// 没有未保存提示，「不保存就是数据丢失」。故停止输入 500ms 后自动落库。

abstract class _$NoteEditor extends $AsyncNotifier<NoteEditorState> {
  late final _$args = ref.$arg as String;
  String get noteId => _$args;

  FutureOr<NoteEditorState> build(String noteId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NoteEditorState>, NoteEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NoteEditorState>, NoteEditorState>,
              AsyncValue<NoteEditorState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
