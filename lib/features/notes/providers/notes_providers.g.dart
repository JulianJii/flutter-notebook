// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(noteLocalDataSource)
final noteLocalDataSourceProvider = NoteLocalDataSourceProvider._();

final class NoteLocalDataSourceProvider
    extends
        $FunctionalProvider<
          NoteLocalDataSource,
          NoteLocalDataSource,
          NoteLocalDataSource
        >
    with $Provider<NoteLocalDataSource> {
  NoteLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<NoteLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoteLocalDataSource create(Ref ref) {
    return noteLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteLocalDataSource>(value),
    );
  }
}

String _$noteLocalDataSourceHash() =>
    r'f2a7712bb05c6018213df0a65aba3407d824d65b';

@ProviderFor(folderLocalDataSource)
final folderLocalDataSourceProvider = FolderLocalDataSourceProvider._();

final class FolderLocalDataSourceProvider
    extends
        $FunctionalProvider<
          FolderLocalDataSource,
          FolderLocalDataSource,
          FolderLocalDataSource
        >
    with $Provider<FolderLocalDataSource> {
  FolderLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<FolderLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FolderLocalDataSource create(Ref ref) {
    return folderLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FolderLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FolderLocalDataSource>(value),
    );
  }
}

String _$folderLocalDataSourceHash() =>
    r'8ab78170dd8932224def12deacc5fb1a1eb198e9';

@ProviderFor(noteRepository)
final noteRepositoryProvider = NoteRepositoryProvider._();

final class NoteRepositoryProvider
    extends $FunctionalProvider<NoteRepository, NoteRepository, NoteRepository>
    with $Provider<NoteRepository> {
  NoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoteRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoteRepository create(Ref ref) {
    return noteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteRepository>(value),
    );
  }
}

String _$noteRepositoryHash() => r'd1abd7af899984b461854eac8d7cc4195b4f12be';

@ProviderFor(folderRepository)
final folderRepositoryProvider = FolderRepositoryProvider._();

final class FolderRepositoryProvider
    extends
        $FunctionalProvider<
          FolderRepository,
          FolderRepository,
          FolderRepository
        >
    with $Provider<FolderRepository> {
  FolderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderRepositoryHash();

  @$internal
  @override
  $ProviderElement<FolderRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FolderRepository create(Ref ref) {
    return folderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FolderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FolderRepository>(value),
    );
  }
}

String _$folderRepositoryHash() => r'678072a9b93fa912caf2407942b6c6dbc665bb48';

@ProviderFor(tagLocalDataSource)
final tagLocalDataSourceProvider = TagLocalDataSourceProvider._();

final class TagLocalDataSourceProvider
    extends
        $FunctionalProvider<
          TagLocalDataSource,
          TagLocalDataSource,
          TagLocalDataSource
        >
    with $Provider<TagLocalDataSource> {
  TagLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<TagLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TagLocalDataSource create(Ref ref) {
    return tagLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagLocalDataSource>(value),
    );
  }
}

String _$tagLocalDataSourceHash() =>
    r'9ebf56334b1e3a6a3c33b5880767f573af5b01d7';

@ProviderFor(tagRepository)
final tagRepositoryProvider = TagRepositoryProvider._();

final class TagRepositoryProvider
    extends $FunctionalProvider<TagRepository, TagRepository, TagRepository>
    with $Provider<TagRepository> {
  TagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagRepositoryHash();

  @$internal
  @override
  $ProviderElement<TagRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagRepository create(Ref ref) {
    return tagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagRepository>(value),
    );
  }
}

String _$tagRepositoryHash() => r'4abb25b5680bbc35e9316b16ce7ac9f59aedd20d';

@ProviderFor(noteVersionLocalDataSource)
final noteVersionLocalDataSourceProvider =
    NoteVersionLocalDataSourceProvider._();

final class NoteVersionLocalDataSourceProvider
    extends
        $FunctionalProvider<
          NoteVersionLocalDataSource,
          NoteVersionLocalDataSource,
          NoteVersionLocalDataSource
        >
    with $Provider<NoteVersionLocalDataSource> {
  NoteVersionLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteVersionLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteVersionLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<NoteVersionLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoteVersionLocalDataSource create(Ref ref) {
    return noteVersionLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteVersionLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteVersionLocalDataSource>(value),
    );
  }
}

String _$noteVersionLocalDataSourceHash() =>
    r'252141c79fc2dca217d65048954bb6ae48691588';

@ProviderFor(noteVersionRepository)
final noteVersionRepositoryProvider = NoteVersionRepositoryProvider._();

final class NoteVersionRepositoryProvider
    extends
        $FunctionalProvider<
          NoteVersionRepository,
          NoteVersionRepository,
          NoteVersionRepository
        >
    with $Provider<NoteVersionRepository> {
  NoteVersionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteVersionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteVersionRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoteVersionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoteVersionRepository create(Ref ref) {
    return noteVersionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteVersionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteVersionRepository>(value),
    );
  }
}

String _$noteVersionRepositoryHash() =>
    r'df033218036824b5930a4e0dc3706f5bcb0854ed';

@ProviderFor(watchNotesUseCase)
final watchNotesUseCaseProvider = WatchNotesUseCaseProvider._();

final class WatchNotesUseCaseProvider
    extends
        $FunctionalProvider<
          WatchNotesUseCase,
          WatchNotesUseCase,
          WatchNotesUseCase
        >
    with $Provider<WatchNotesUseCase> {
  WatchNotesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchNotesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchNotesUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchNotesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchNotesUseCase create(Ref ref) {
    return watchNotesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchNotesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchNotesUseCase>(value),
    );
  }
}

String _$watchNotesUseCaseHash() => r'313672720e8bac9bff65bc81f5dd5af3dfa724c0';

@ProviderFor(getNoteUseCase)
final getNoteUseCaseProvider = GetNoteUseCaseProvider._();

final class GetNoteUseCaseProvider
    extends $FunctionalProvider<GetNoteUseCase, GetNoteUseCase, GetNoteUseCase>
    with $Provider<GetNoteUseCase> {
  GetNoteUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getNoteUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getNoteUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetNoteUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetNoteUseCase create(Ref ref) {
    return getNoteUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetNoteUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetNoteUseCase>(value),
    );
  }
}

String _$getNoteUseCaseHash() => r'5f0c1b0d0cc3d550c1a824365d64390429a8a6f6';

@ProviderFor(createNoteUseCase)
final createNoteUseCaseProvider = CreateNoteUseCaseProvider._();

final class CreateNoteUseCaseProvider
    extends
        $FunctionalProvider<
          CreateNoteUseCase,
          CreateNoteUseCase,
          CreateNoteUseCase
        >
    with $Provider<CreateNoteUseCase> {
  CreateNoteUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createNoteUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createNoteUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateNoteUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateNoteUseCase create(Ref ref) {
    return createNoteUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateNoteUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateNoteUseCase>(value),
    );
  }
}

String _$createNoteUseCaseHash() => r'4f483031259d33b4c1824a37ac673f8c18ac93bc';

@ProviderFor(updateNoteUseCase)
final updateNoteUseCaseProvider = UpdateNoteUseCaseProvider._();

final class UpdateNoteUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateNoteUseCase,
          UpdateNoteUseCase,
          UpdateNoteUseCase
        >
    with $Provider<UpdateNoteUseCase> {
  UpdateNoteUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateNoteUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateNoteUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateNoteUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateNoteUseCase create(Ref ref) {
    return updateNoteUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateNoteUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateNoteUseCase>(value),
    );
  }
}

String _$updateNoteUseCaseHash() => r'cc874c3febf1b956b38433024ed69142b743c80a';

@ProviderFor(updateNoteBackgroundUseCase)
final updateNoteBackgroundUseCaseProvider =
    UpdateNoteBackgroundUseCaseProvider._();

final class UpdateNoteBackgroundUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateNoteBackgroundUseCase,
          UpdateNoteBackgroundUseCase,
          UpdateNoteBackgroundUseCase
        >
    with $Provider<UpdateNoteBackgroundUseCase> {
  UpdateNoteBackgroundUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateNoteBackgroundUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateNoteBackgroundUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateNoteBackgroundUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateNoteBackgroundUseCase create(Ref ref) {
    return updateNoteBackgroundUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateNoteBackgroundUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateNoteBackgroundUseCase>(value),
    );
  }
}

String _$updateNoteBackgroundUseCaseHash() =>
    r'2514d35bad4c50fec7ebe56ba4df3a24695df3c8';

@ProviderFor(updateNoteEditorFontUseCase)
final updateNoteEditorFontUseCaseProvider =
    UpdateNoteEditorFontUseCaseProvider._();

final class UpdateNoteEditorFontUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateNoteEditorFontUseCase,
          UpdateNoteEditorFontUseCase,
          UpdateNoteEditorFontUseCase
        >
    with $Provider<UpdateNoteEditorFontUseCase> {
  UpdateNoteEditorFontUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateNoteEditorFontUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateNoteEditorFontUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateNoteEditorFontUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateNoteEditorFontUseCase create(Ref ref) {
    return updateNoteEditorFontUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateNoteEditorFontUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateNoteEditorFontUseCase>(value),
    );
  }
}

String _$updateNoteEditorFontUseCaseHash() =>
    r'e60cd6b1891f957b09e279c10ec835887f435730';

@ProviderFor(updateNoteFlagsUseCase)
final updateNoteFlagsUseCaseProvider = UpdateNoteFlagsUseCaseProvider._();

final class UpdateNoteFlagsUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateNoteFlagsUseCase,
          UpdateNoteFlagsUseCase,
          UpdateNoteFlagsUseCase
        >
    with $Provider<UpdateNoteFlagsUseCase> {
  UpdateNoteFlagsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateNoteFlagsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateNoteFlagsUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateNoteFlagsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateNoteFlagsUseCase create(Ref ref) {
    return updateNoteFlagsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateNoteFlagsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateNoteFlagsUseCase>(value),
    );
  }
}

String _$updateNoteFlagsUseCaseHash() =>
    r'b34728d8ef628ddc85d4a48b46a8823a7039f694';

@ProviderFor(deleteNoteUseCase)
final deleteNoteUseCaseProvider = DeleteNoteUseCaseProvider._();

final class DeleteNoteUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteNoteUseCase,
          DeleteNoteUseCase,
          DeleteNoteUseCase
        >
    with $Provider<DeleteNoteUseCase> {
  DeleteNoteUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteNoteUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteNoteUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteNoteUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteNoteUseCase create(Ref ref) {
    return deleteNoteUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteNoteUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteNoteUseCase>(value),
    );
  }
}

String _$deleteNoteUseCaseHash() => r'5275810a12a8327a620017b4d2f283b10f3dcd2e';

@ProviderFor(batchDeleteNotesUseCase)
final batchDeleteNotesUseCaseProvider = BatchDeleteNotesUseCaseProvider._();

final class BatchDeleteNotesUseCaseProvider
    extends
        $FunctionalProvider<
          BatchDeleteNotesUseCase,
          BatchDeleteNotesUseCase,
          BatchDeleteNotesUseCase
        >
    with $Provider<BatchDeleteNotesUseCase> {
  BatchDeleteNotesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchDeleteNotesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchDeleteNotesUseCaseHash();

  @$internal
  @override
  $ProviderElement<BatchDeleteNotesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BatchDeleteNotesUseCase create(Ref ref) {
    return batchDeleteNotesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchDeleteNotesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchDeleteNotesUseCase>(value),
    );
  }
}

String _$batchDeleteNotesUseCaseHash() =>
    r'66cb8576cc1b49c4d5dcfab8ccf88aac457c997a';

@ProviderFor(batchMoveNotesUseCase)
final batchMoveNotesUseCaseProvider = BatchMoveNotesUseCaseProvider._();

final class BatchMoveNotesUseCaseProvider
    extends
        $FunctionalProvider<
          BatchMoveNotesUseCase,
          BatchMoveNotesUseCase,
          BatchMoveNotesUseCase
        >
    with $Provider<BatchMoveNotesUseCase> {
  BatchMoveNotesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchMoveNotesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchMoveNotesUseCaseHash();

  @$internal
  @override
  $ProviderElement<BatchMoveNotesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BatchMoveNotesUseCase create(Ref ref) {
    return batchMoveNotesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchMoveNotesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchMoveNotesUseCase>(value),
    );
  }
}

String _$batchMoveNotesUseCaseHash() =>
    r'd55ceb16899528e3ce15d59de81d0eb1659c25c5';

@ProviderFor(batchUpdateNoteFlagsUseCase)
final batchUpdateNoteFlagsUseCaseProvider =
    BatchUpdateNoteFlagsUseCaseProvider._();

final class BatchUpdateNoteFlagsUseCaseProvider
    extends
        $FunctionalProvider<
          BatchUpdateNoteFlagsUseCase,
          BatchUpdateNoteFlagsUseCase,
          BatchUpdateNoteFlagsUseCase
        >
    with $Provider<BatchUpdateNoteFlagsUseCase> {
  BatchUpdateNoteFlagsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batchUpdateNoteFlagsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batchUpdateNoteFlagsUseCaseHash();

  @$internal
  @override
  $ProviderElement<BatchUpdateNoteFlagsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BatchUpdateNoteFlagsUseCase create(Ref ref) {
    return batchUpdateNoteFlagsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BatchUpdateNoteFlagsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BatchUpdateNoteFlagsUseCase>(value),
    );
  }
}

String _$batchUpdateNoteFlagsUseCaseHash() =>
    r'6e7e8110e6688e303a40521e5ba15409ea9acb42';

@ProviderFor(watchFolderCountsUseCase)
final watchFolderCountsUseCaseProvider = WatchFolderCountsUseCaseProvider._();

final class WatchFolderCountsUseCaseProvider
    extends
        $FunctionalProvider<
          WatchFolderCountsUseCase,
          WatchFolderCountsUseCase,
          WatchFolderCountsUseCase
        >
    with $Provider<WatchFolderCountsUseCase> {
  WatchFolderCountsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchFolderCountsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchFolderCountsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchFolderCountsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchFolderCountsUseCase create(Ref ref) {
    return watchFolderCountsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchFolderCountsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchFolderCountsUseCase>(value),
    );
  }
}

String _$watchFolderCountsUseCaseHash() =>
    r'd0653a2d6ccbd5ff2921a660826a25ad432934f0';

@ProviderFor(watchTagsUseCase)
final watchTagsUseCaseProvider = WatchTagsUseCaseProvider._();

final class WatchTagsUseCaseProvider
    extends
        $FunctionalProvider<
          WatchTagsUseCase,
          WatchTagsUseCase,
          WatchTagsUseCase
        >
    with $Provider<WatchTagsUseCase> {
  WatchTagsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTagsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTagsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchTagsUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchTagsUseCase create(Ref ref) {
    return watchTagsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTagsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchTagsUseCase>(value),
    );
  }
}

String _$watchTagsUseCaseHash() => r'b13c392a3c03e311d58a8577cb39562e52a21da2';

@ProviderFor(getNoteTagsUseCase)
final getNoteTagsUseCaseProvider = GetNoteTagsUseCaseProvider._();

final class GetNoteTagsUseCaseProvider
    extends
        $FunctionalProvider<
          GetNoteTagsUseCase,
          GetNoteTagsUseCase,
          GetNoteTagsUseCase
        >
    with $Provider<GetNoteTagsUseCase> {
  GetNoteTagsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getNoteTagsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getNoteTagsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetNoteTagsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetNoteTagsUseCase create(Ref ref) {
    return getNoteTagsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetNoteTagsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetNoteTagsUseCase>(value),
    );
  }
}

String _$getNoteTagsUseCaseHash() =>
    r'2a3b5929826b73e3d0695d7e1a8e11035e33dfc2';

@ProviderFor(setNoteTagsUseCase)
final setNoteTagsUseCaseProvider = SetNoteTagsUseCaseProvider._();

final class SetNoteTagsUseCaseProvider
    extends
        $FunctionalProvider<
          SetNoteTagsUseCase,
          SetNoteTagsUseCase,
          SetNoteTagsUseCase
        >
    with $Provider<SetNoteTagsUseCase> {
  SetNoteTagsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setNoteTagsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setNoteTagsUseCaseHash();

  @$internal
  @override
  $ProviderElement<SetNoteTagsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SetNoteTagsUseCase create(Ref ref) {
    return setNoteTagsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetNoteTagsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetNoteTagsUseCase>(value),
    );
  }
}

String _$setNoteTagsUseCaseHash() =>
    r'8d01f55822cc5f5b3c4f0578ca67ad2689d4aabd';

@ProviderFor(renameTagUseCase)
final renameTagUseCaseProvider = RenameTagUseCaseProvider._();

final class RenameTagUseCaseProvider
    extends
        $FunctionalProvider<
          RenameTagUseCase,
          RenameTagUseCase,
          RenameTagUseCase
        >
    with $Provider<RenameTagUseCase> {
  RenameTagUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renameTagUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renameTagUseCaseHash();

  @$internal
  @override
  $ProviderElement<RenameTagUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RenameTagUseCase create(Ref ref) {
    return renameTagUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RenameTagUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RenameTagUseCase>(value),
    );
  }
}

String _$renameTagUseCaseHash() => r'fd291364afb32ed3835d9e9568379bc48c8387c4';

@ProviderFor(deleteTagUseCase)
final deleteTagUseCaseProvider = DeleteTagUseCaseProvider._();

final class DeleteTagUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteTagUseCase,
          DeleteTagUseCase,
          DeleteTagUseCase
        >
    with $Provider<DeleteTagUseCase> {
  DeleteTagUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteTagUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteTagUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteTagUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteTagUseCase create(Ref ref) {
    return deleteTagUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteTagUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteTagUseCase>(value),
    );
  }
}

String _$deleteTagUseCaseHash() => r'160ae1d4579c2d90461188fb353a2adb14b93c5e';

@ProviderFor(saveNoteVersionUseCase)
final saveNoteVersionUseCaseProvider = SaveNoteVersionUseCaseProvider._();

final class SaveNoteVersionUseCaseProvider
    extends
        $FunctionalProvider<
          SaveNoteVersionUseCase,
          SaveNoteVersionUseCase,
          SaveNoteVersionUseCase
        >
    with $Provider<SaveNoteVersionUseCase> {
  SaveNoteVersionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveNoteVersionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveNoteVersionUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveNoteVersionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveNoteVersionUseCase create(Ref ref) {
    return saveNoteVersionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveNoteVersionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveNoteVersionUseCase>(value),
    );
  }
}

String _$saveNoteVersionUseCaseHash() =>
    r'12f8d2d04dd130d349257cf5de2610d2fc9fb43f';

@ProviderFor(watchNoteVersionsUseCase)
final watchNoteVersionsUseCaseProvider = WatchNoteVersionsUseCaseProvider._();

final class WatchNoteVersionsUseCaseProvider
    extends
        $FunctionalProvider<
          WatchNoteVersionsUseCase,
          WatchNoteVersionsUseCase,
          WatchNoteVersionsUseCase
        >
    with $Provider<WatchNoteVersionsUseCase> {
  WatchNoteVersionsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchNoteVersionsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchNoteVersionsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchNoteVersionsUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchNoteVersionsUseCase create(Ref ref) {
    return watchNoteVersionsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchNoteVersionsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchNoteVersionsUseCase>(value),
    );
  }
}

String _$watchNoteVersionsUseCaseHash() =>
    r'd742d7d50ec4e9e3b819ed637a25d117316e9c6c';

@ProviderFor(restoreNoteVersionUseCase)
final restoreNoteVersionUseCaseProvider = RestoreNoteVersionUseCaseProvider._();

final class RestoreNoteVersionUseCaseProvider
    extends
        $FunctionalProvider<
          RestoreNoteVersionUseCase,
          RestoreNoteVersionUseCase,
          RestoreNoteVersionUseCase
        >
    with $Provider<RestoreNoteVersionUseCase> {
  RestoreNoteVersionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreNoteVersionUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreNoteVersionUseCaseHash();

  @$internal
  @override
  $ProviderElement<RestoreNoteVersionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestoreNoteVersionUseCase create(Ref ref) {
    return restoreNoteVersionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreNoteVersionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreNoteVersionUseCase>(value),
    );
  }
}

String _$restoreNoteVersionUseCaseHash() =>
    r'd90428c83579999ca16132a8a44e633f11092913';

@ProviderFor(createFolderUseCase)
final createFolderUseCaseProvider = CreateFolderUseCaseProvider._();

final class CreateFolderUseCaseProvider
    extends
        $FunctionalProvider<
          CreateFolderUseCase,
          CreateFolderUseCase,
          CreateFolderUseCase
        >
    with $Provider<CreateFolderUseCase> {
  CreateFolderUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createFolderUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createFolderUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateFolderUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateFolderUseCase create(Ref ref) {
    return createFolderUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateFolderUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateFolderUseCase>(value),
    );
  }
}

String _$createFolderUseCaseHash() =>
    r'82598c2a5094b7c9275db76a4b470285b8059bac';

@ProviderFor(renameFolderUseCase)
final renameFolderUseCaseProvider = RenameFolderUseCaseProvider._();

final class RenameFolderUseCaseProvider
    extends
        $FunctionalProvider<
          RenameFolderUseCase,
          RenameFolderUseCase,
          RenameFolderUseCase
        >
    with $Provider<RenameFolderUseCase> {
  RenameFolderUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renameFolderUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renameFolderUseCaseHash();

  @$internal
  @override
  $ProviderElement<RenameFolderUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RenameFolderUseCase create(Ref ref) {
    return renameFolderUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RenameFolderUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RenameFolderUseCase>(value),
    );
  }
}

String _$renameFolderUseCaseHash() =>
    r'd2e667e09959432c2f209b3b8fdee8e6ad062fc2';

@ProviderFor(deleteFolderUseCase)
final deleteFolderUseCaseProvider = DeleteFolderUseCaseProvider._();

final class DeleteFolderUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteFolderUseCase,
          DeleteFolderUseCase,
          DeleteFolderUseCase
        >
    with $Provider<DeleteFolderUseCase> {
  DeleteFolderUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteFolderUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteFolderUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteFolderUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteFolderUseCase create(Ref ref) {
    return deleteFolderUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteFolderUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteFolderUseCase>(value),
    );
  }
}

String _$deleteFolderUseCaseHash() =>
    r'1eaf361cfecb8a14cbb9f695c67f48978e70fbaa';

@ProviderFor(reorderFoldersUseCase)
final reorderFoldersUseCaseProvider = ReorderFoldersUseCaseProvider._();

final class ReorderFoldersUseCaseProvider
    extends
        $FunctionalProvider<
          ReorderFoldersUseCase,
          ReorderFoldersUseCase,
          ReorderFoldersUseCase
        >
    with $Provider<ReorderFoldersUseCase> {
  ReorderFoldersUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reorderFoldersUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reorderFoldersUseCaseHash();

  @$internal
  @override
  $ProviderElement<ReorderFoldersUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReorderFoldersUseCase create(Ref ref) {
    return reorderFoldersUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReorderFoldersUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReorderFoldersUseCase>(value),
    );
  }
}

String _$reorderFoldersUseCaseHash() =>
    r'f860b0f1b1e721861f5001fa269bf36e7a6a48f8';

@ProviderFor(watchDeletedNotesUseCase)
final watchDeletedNotesUseCaseProvider = WatchDeletedNotesUseCaseProvider._();

final class WatchDeletedNotesUseCaseProvider
    extends
        $FunctionalProvider<
          WatchDeletedNotesUseCase,
          WatchDeletedNotesUseCase,
          WatchDeletedNotesUseCase
        >
    with $Provider<WatchDeletedNotesUseCase> {
  WatchDeletedNotesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchDeletedNotesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchDeletedNotesUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchDeletedNotesUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchDeletedNotesUseCase create(Ref ref) {
    return watchDeletedNotesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchDeletedNotesUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchDeletedNotesUseCase>(value),
    );
  }
}

String _$watchDeletedNotesUseCaseHash() =>
    r'6fa1f0c5f52aee89accded822324d029dbd3ef3f';

@ProviderFor(restoreNoteUseCase)
final restoreNoteUseCaseProvider = RestoreNoteUseCaseProvider._();

final class RestoreNoteUseCaseProvider
    extends
        $FunctionalProvider<
          RestoreNoteUseCase,
          RestoreNoteUseCase,
          RestoreNoteUseCase
        >
    with $Provider<RestoreNoteUseCase> {
  RestoreNoteUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreNoteUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreNoteUseCaseHash();

  @$internal
  @override
  $ProviderElement<RestoreNoteUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestoreNoteUseCase create(Ref ref) {
    return restoreNoteUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreNoteUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreNoteUseCase>(value),
    );
  }
}

String _$restoreNoteUseCaseHash() =>
    r'76d0992febb50993bea77641297fc7b8e46ab2a0';

@ProviderFor(purgeNoteUseCase)
final purgeNoteUseCaseProvider = PurgeNoteUseCaseProvider._();

final class PurgeNoteUseCaseProvider
    extends
        $FunctionalProvider<
          PurgeNoteUseCase,
          PurgeNoteUseCase,
          PurgeNoteUseCase
        >
    with $Provider<PurgeNoteUseCase> {
  PurgeNoteUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purgeNoteUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purgeNoteUseCaseHash();

  @$internal
  @override
  $ProviderElement<PurgeNoteUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurgeNoteUseCase create(Ref ref) {
    return purgeNoteUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurgeNoteUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurgeNoteUseCase>(value),
    );
  }
}

String _$purgeNoteUseCaseHash() => r'fa8cbdd60080d3bc10152d8d0aa1f7033b958de8';

@ProviderFor(emptyTrashUseCase)
final emptyTrashUseCaseProvider = EmptyTrashUseCaseProvider._();

final class EmptyTrashUseCaseProvider
    extends
        $FunctionalProvider<
          EmptyTrashUseCase,
          EmptyTrashUseCase,
          EmptyTrashUseCase
        >
    with $Provider<EmptyTrashUseCase> {
  EmptyTrashUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emptyTrashUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emptyTrashUseCaseHash();

  @$internal
  @override
  $ProviderElement<EmptyTrashUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmptyTrashUseCase create(Ref ref) {
    return emptyTrashUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmptyTrashUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmptyTrashUseCase>(value),
    );
  }
}

String _$emptyTrashUseCaseHash() => r'9daefe6c23d956a4c025f5967edfb6ea8cb0d1a0';

@ProviderFor(watchTrashedFoldersUseCase)
final watchTrashedFoldersUseCaseProvider =
    WatchTrashedFoldersUseCaseProvider._();

final class WatchTrashedFoldersUseCaseProvider
    extends
        $FunctionalProvider<
          WatchTrashedFoldersUseCase,
          WatchTrashedFoldersUseCase,
          WatchTrashedFoldersUseCase
        >
    with $Provider<WatchTrashedFoldersUseCase> {
  WatchTrashedFoldersUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTrashedFoldersUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTrashedFoldersUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchTrashedFoldersUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchTrashedFoldersUseCase create(Ref ref) {
    return watchTrashedFoldersUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTrashedFoldersUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchTrashedFoldersUseCase>(value),
    );
  }
}

String _$watchTrashedFoldersUseCaseHash() =>
    r'4aab34ed693ade7422720fa9a3f75d98cdd4a1d0';

@ProviderFor(restoreFolderUseCase)
final restoreFolderUseCaseProvider = RestoreFolderUseCaseProvider._();

final class RestoreFolderUseCaseProvider
    extends
        $FunctionalProvider<
          RestoreFolderUseCase,
          RestoreFolderUseCase,
          RestoreFolderUseCase
        >
    with $Provider<RestoreFolderUseCase> {
  RestoreFolderUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreFolderUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreFolderUseCaseHash();

  @$internal
  @override
  $ProviderElement<RestoreFolderUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestoreFolderUseCase create(Ref ref) {
    return restoreFolderUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreFolderUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreFolderUseCase>(value),
    );
  }
}

String _$restoreFolderUseCaseHash() =>
    r'971bee76e34c56b98f9f171f13004e54b8d34d25';

@ProviderFor(purgeFolderUseCase)
final purgeFolderUseCaseProvider = PurgeFolderUseCaseProvider._();

final class PurgeFolderUseCaseProvider
    extends
        $FunctionalProvider<
          PurgeFolderUseCase,
          PurgeFolderUseCase,
          PurgeFolderUseCase
        >
    with $Provider<PurgeFolderUseCase> {
  PurgeFolderUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purgeFolderUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purgeFolderUseCaseHash();

  @$internal
  @override
  $ProviderElement<PurgeFolderUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PurgeFolderUseCase create(Ref ref) {
    return purgeFolderUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurgeFolderUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurgeFolderUseCase>(value),
    );
  }
}

String _$purgeFolderUseCaseHash() =>
    r'aa585fb47f83b79694768316b17d73296e157362';

@ProviderFor(emptyFolderTrashUseCase)
final emptyFolderTrashUseCaseProvider = EmptyFolderTrashUseCaseProvider._();

final class EmptyFolderTrashUseCaseProvider
    extends
        $FunctionalProvider<
          EmptyFolderTrashUseCase,
          EmptyFolderTrashUseCase,
          EmptyFolderTrashUseCase
        >
    with $Provider<EmptyFolderTrashUseCase> {
  EmptyFolderTrashUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emptyFolderTrashUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emptyFolderTrashUseCaseHash();

  @$internal
  @override
  $ProviderElement<EmptyFolderTrashUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmptyFolderTrashUseCase create(Ref ref) {
    return emptyFolderTrashUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmptyFolderTrashUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmptyFolderTrashUseCase>(value),
    );
  }
}

String _$emptyFolderTrashUseCaseHash() =>
    r'8b35de47fa24f34cd4a3e9decaaef37e9ff5ad31';

@ProviderFor(noteImageRepository)
final noteImageRepositoryProvider = NoteImageRepositoryProvider._();

final class NoteImageRepositoryProvider
    extends
        $FunctionalProvider<
          NoteImageRepository,
          NoteImageRepository,
          NoteImageRepository
        >
    with $Provider<NoteImageRepository> {
  NoteImageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteImageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteImageRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoteImageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoteImageRepository create(Ref ref) {
    return noteImageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteImageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteImageRepository>(value),
    );
  }
}

String _$noteImageRepositoryHash() =>
    r'2e7fae8b430fc917b5cfcf6aeac6abc971020001';

@ProviderFor(pickNoteImageUseCase)
final pickNoteImageUseCaseProvider = PickNoteImageUseCaseProvider._();

final class PickNoteImageUseCaseProvider
    extends
        $FunctionalProvider<
          PickNoteImageUseCase,
          PickNoteImageUseCase,
          PickNoteImageUseCase
        >
    with $Provider<PickNoteImageUseCase> {
  PickNoteImageUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pickNoteImageUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pickNoteImageUseCaseHash();

  @$internal
  @override
  $ProviderElement<PickNoteImageUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PickNoteImageUseCase create(Ref ref) {
    return pickNoteImageUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickNoteImageUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickNoteImageUseCase>(value),
    );
  }
}

String _$pickNoteImageUseCaseHash() =>
    r'6bf05c5e45f52777bd7d63c88db89732ea67c2c3';
