// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_note_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅「最近删除」列表（软删除的笔记，按删除时间倒序）。
///
/// 与 `noteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
/// UI 自动重建，调用方无需手动 invalidate。

@ProviderFor(deletedNoteList)
final deletedNoteListProvider = DeletedNoteListProvider._();

/// 订阅「最近删除」列表（软删除的笔记，按删除时间倒序）。
///
/// 与 `noteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
/// UI 自动重建，调用方无需手动 invalidate。

final class DeletedNoteListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          Stream<List<Note>>
        >
    with $FutureModifier<List<Note>>, $StreamProvider<List<Note>> {
  /// 订阅「最近删除」列表（软删除的笔记，按删除时间倒序）。
  ///
  /// 与 `noteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
  /// UI 自动重建，调用方无需手动 invalidate。
  DeletedNoteListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deletedNoteListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deletedNoteListHash();

  @$internal
  @override
  $StreamProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Note>> create(Ref ref) {
    return deletedNoteList(ref);
  }
}

String _$deletedNoteListHash() => r'bc34af563351893a04801276ced43a31e85d0b3b';
