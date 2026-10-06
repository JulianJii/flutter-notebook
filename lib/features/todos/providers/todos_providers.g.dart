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
