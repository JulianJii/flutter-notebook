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
