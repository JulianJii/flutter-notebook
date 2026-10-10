// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trashed_folder_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 订阅回收站里的文件夹（软删除的，按删除时间倒序）。
///
/// 与 `deletedNoteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
/// UI 自动重建，调用方无需手动 invalidate。

@ProviderFor(trashedFolderList)
final trashedFolderListProvider = TrashedFolderListProvider._();

/// 订阅回收站里的文件夹（软删除的，按删除时间倒序）。
///
/// 与 `deletedNoteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
/// UI 自动重建，调用方无需手动 invalidate。

final class TrashedFolderListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NoteFolder>>,
          List<NoteFolder>,
          Stream<List<NoteFolder>>
        >
    with $FutureModifier<List<NoteFolder>>, $StreamProvider<List<NoteFolder>> {
  /// 订阅回收站里的文件夹（软删除的，按删除时间倒序）。
  ///
  /// 与 `deletedNoteListProvider` 同约定：drift watch 推流，恢复 / 永久删除后
  /// UI 自动重建，调用方无需手动 invalidate。
  TrashedFolderListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trashedFolderListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trashedFolderListHash();

  @$internal
  @override
  $StreamProviderElement<List<NoteFolder>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NoteFolder>> create(Ref ref) {
    return trashedFolderList(ref);
  }
}

String _$trashedFolderListHash() => r'bb5a858bdac6718b8f7838d7ca4f81a44dc44e7a';
