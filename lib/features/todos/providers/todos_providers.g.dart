// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todos_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(todoLocalDataSource)
final todoLocalDataSourceProvider = TodoLocalDataSourceProvider._();

final class TodoLocalDataSourceProvider
    extends
        $FunctionalProvider<
          TodoLocalDataSource,
          TodoLocalDataSource,
          TodoLocalDataSource
        >
    with $Provider<TodoLocalDataSource> {
  TodoLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<TodoLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TodoLocalDataSource create(Ref ref) {
    return todoLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoLocalDataSource>(value),
    );
  }
}

String _$todoLocalDataSourceHash() =>
    r'60d0ba77752ba0d21816d22f44d222820895fbb4';

@ProviderFor(todoRepository)
final todoRepositoryProvider = TodoRepositoryProvider._();

final class TodoRepositoryProvider
    extends $FunctionalProvider<TodoRepository, TodoRepository, TodoRepository>
    with $Provider<TodoRepository> {
  TodoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todoRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todoRepositoryHash();

  @$internal
  @override
  $ProviderElement<TodoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TodoRepository create(Ref ref) {
    return todoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodoRepository>(value),
    );
  }
}

String _$todoRepositoryHash() => r'c2b32b33f48c50277b13163c91976fe9a978eb4c';

@ProviderFor(watchTodosUseCase)
final watchTodosUseCaseProvider = WatchTodosUseCaseProvider._();

final class WatchTodosUseCaseProvider
    extends
        $FunctionalProvider<
          WatchTodosUseCase,
          WatchTodosUseCase,
          WatchTodosUseCase
        >
    with $Provider<WatchTodosUseCase> {
  WatchTodosUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTodosUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTodosUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchTodosUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchTodosUseCase create(Ref ref) {
    return watchTodosUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTodosUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchTodosUseCase>(value),
    );
  }
}

String _$watchTodosUseCaseHash() => r'a268713d9ac70cb4884e48c58355fd3da2245f6c';

@ProviderFor(createTodoUseCase)
final createTodoUseCaseProvider = CreateTodoUseCaseProvider._();

final class CreateTodoUseCaseProvider
    extends
        $FunctionalProvider<
          CreateTodoUseCase,
          CreateTodoUseCase,
          CreateTodoUseCase
        >
    with $Provider<CreateTodoUseCase> {
  CreateTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateTodoUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreateTodoUseCase create(Ref ref) {
    return createTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateTodoUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateTodoUseCase>(value),
    );
  }
}

String _$createTodoUseCaseHash() => r'44cd51c108beb52f5b238fe114b05e0be256426a';

@ProviderFor(toggleTodoUseCase)
final toggleTodoUseCaseProvider = ToggleTodoUseCaseProvider._();

final class ToggleTodoUseCaseProvider
    extends
        $FunctionalProvider<
          ToggleTodoUseCase,
          ToggleTodoUseCase,
          ToggleTodoUseCase
        >
    with $Provider<ToggleTodoUseCase> {
  ToggleTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'toggleTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$toggleTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<ToggleTodoUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ToggleTodoUseCase create(Ref ref) {
    return toggleTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ToggleTodoUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ToggleTodoUseCase>(value),
    );
  }
}

String _$toggleTodoUseCaseHash() => r'274990ed34dfa5bc85ec3277eb0a2962e8ecd9de';

@ProviderFor(updateTodoUseCase)
final updateTodoUseCaseProvider = UpdateTodoUseCaseProvider._();

final class UpdateTodoUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateTodoUseCase,
          UpdateTodoUseCase,
          UpdateTodoUseCase
        >
    with $Provider<UpdateTodoUseCase> {
  UpdateTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateTodoUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateTodoUseCase create(Ref ref) {
    return updateTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateTodoUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateTodoUseCase>(value),
    );
  }
}

String _$updateTodoUseCaseHash() => r'3c97ba6211f801d6551d6959bbe0b903bc569161';

@ProviderFor(deleteTodoUseCase)
final deleteTodoUseCaseProvider = DeleteTodoUseCaseProvider._();

final class DeleteTodoUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteTodoUseCase,
          DeleteTodoUseCase,
          DeleteTodoUseCase
        >
    with $Provider<DeleteTodoUseCase> {
  DeleteTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteTodoUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteTodoUseCase create(Ref ref) {
    return deleteTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteTodoUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteTodoUseCase>(value),
    );
  }
}

String _$deleteTodoUseCaseHash() => r'6bf9c6e2880f1e42ec7ae50fcc3dc100c9a23904';

@ProviderFor(deleteCompletedTodosUseCase)
final deleteCompletedTodosUseCaseProvider =
    DeleteCompletedTodosUseCaseProvider._();

final class DeleteCompletedTodosUseCaseProvider
    extends
        $FunctionalProvider<
          DeleteCompletedTodosUseCase,
          DeleteCompletedTodosUseCase,
          DeleteCompletedTodosUseCase
        >
    with $Provider<DeleteCompletedTodosUseCase> {
  DeleteCompletedTodosUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteCompletedTodosUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteCompletedTodosUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteCompletedTodosUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeleteCompletedTodosUseCase create(Ref ref) {
    return deleteCompletedTodosUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteCompletedTodosUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteCompletedTodosUseCase>(value),
    );
  }
}

String _$deleteCompletedTodosUseCaseHash() =>
    r'beed3956125b3839da1f7bb4f170603f1c140661';

@ProviderFor(watchTrashedTodosUseCase)
final watchTrashedTodosUseCaseProvider = WatchTrashedTodosUseCaseProvider._();

final class WatchTrashedTodosUseCaseProvider
    extends
        $FunctionalProvider<
          WatchTrashedTodosUseCase,
          WatchTrashedTodosUseCase,
          WatchTrashedTodosUseCase
        >
    with $Provider<WatchTrashedTodosUseCase> {
  WatchTrashedTodosUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchTrashedTodosUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchTrashedTodosUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchTrashedTodosUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchTrashedTodosUseCase create(Ref ref) {
    return watchTrashedTodosUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchTrashedTodosUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchTrashedTodosUseCase>(value),
    );
  }
}

String _$watchTrashedTodosUseCaseHash() =>
    r'2a7ee48de191f30a0ee42f8f1d6ef8226f62fcd1';

@ProviderFor(restoreTodoUseCase)
final restoreTodoUseCaseProvider = RestoreTodoUseCaseProvider._();

final class RestoreTodoUseCaseProvider
    extends
        $FunctionalProvider<
          RestoreTodoUseCase,
          RestoreTodoUseCase,
          RestoreTodoUseCase
        >
    with $Provider<RestoreTodoUseCase> {
  RestoreTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<RestoreTodoUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestoreTodoUseCase create(Ref ref) {
    return restoreTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreTodoUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreTodoUseCase>(value),
    );
  }
}

String _$restoreTodoUseCaseHash() =>
    r'ddc9f0838694098880a7e85612ece9f4aef47ff3';

@ProviderFor(purgeTodoUseCase)
final purgeTodoUseCaseProvider = PurgeTodoUseCaseProvider._();

final class PurgeTodoUseCaseProvider
    extends
        $FunctionalProvider<
          PurgeTodoUseCase,
          PurgeTodoUseCase,
          PurgeTodoUseCase
        >
    with $Provider<PurgeTodoUseCase> {
  PurgeTodoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purgeTodoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purgeTodoUseCaseHash();

  @$internal
  @override
  $ProviderElement<PurgeTodoUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurgeTodoUseCase create(Ref ref) {
    return purgeTodoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurgeTodoUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurgeTodoUseCase>(value),
    );
  }
}

String _$purgeTodoUseCaseHash() => r'8a0a2161f1e4a0015b38f3073b2798b0b0fcfd54';

@ProviderFor(emptyTodoTrashUseCase)
final emptyTodoTrashUseCaseProvider = EmptyTodoTrashUseCaseProvider._();

final class EmptyTodoTrashUseCaseProvider
    extends
        $FunctionalProvider<
          EmptyTodoTrashUseCase,
          EmptyTodoTrashUseCase,
          EmptyTodoTrashUseCase
        >
    with $Provider<EmptyTodoTrashUseCase> {
  EmptyTodoTrashUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emptyTodoTrashUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emptyTodoTrashUseCaseHash();

  @$internal
  @override
  $ProviderElement<EmptyTodoTrashUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EmptyTodoTrashUseCase create(Ref ref) {
    return emptyTodoTrashUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmptyTodoTrashUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmptyTodoTrashUseCase>(value),
    );
  }
}

String _$emptyTodoTrashUseCaseHash() =>
    r'e9257769af6fca9688ff643530f3ca903184474d';
