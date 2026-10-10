// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// WebDAV 专用 Dio 实例。
///
/// ⛔ **不复用 `dioProvider`**：那一份 `baseUrl` 是占位 API 域名、带着
/// `LogInterceptor`（会把 Basic Auth 头打进日志）。这里每次请求都传完整 URL，
/// 不需要 baseUrl。

@ProviderFor(webDavDio)
final webDavDioProvider = WebDavDioProvider._();

/// WebDAV 专用 Dio 实例。
///
/// ⛔ **不复用 `dioProvider`**：那一份 `baseUrl` 是占位 API 域名、带着
/// `LogInterceptor`（会把 Basic Auth 头打进日志）。这里每次请求都传完整 URL，
/// 不需要 baseUrl。

final class WebDavDioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// WebDAV 专用 Dio 实例。
  ///
  /// ⛔ **不复用 `dioProvider`**：那一份 `baseUrl` 是占位 API 域名、带着
  /// `LogInterceptor`（会把 Basic Auth 头打进日志）。这里每次请求都传完整 URL，
  /// 不需要 baseUrl。
  WebDavDioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webDavDioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webDavDioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return webDavDio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$webDavDioHash() => r'0ae0c3cda7ce38dd7740d6f34fb29b48747b775f';

@ProviderFor(backupLocalDataSource)
final backupLocalDataSourceProvider = BackupLocalDataSourceProvider._();

final class BackupLocalDataSourceProvider
    extends
        $FunctionalProvider<
          BackupLocalDataSource,
          BackupLocalDataSource,
          BackupLocalDataSource
        >
    with $Provider<BackupLocalDataSource> {
  BackupLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupLocalDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<BackupLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackupLocalDataSource create(Ref ref) {
    return backupLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupLocalDataSource>(value),
    );
  }
}

String _$backupLocalDataSourceHash() =>
    r'f9bc85dc3a52bfe63827231b4dd7baf6a7debbb0';

@ProviderFor(webDavDataSource)
final webDavDataSourceProvider = WebDavDataSourceProvider._();

final class WebDavDataSourceProvider
    extends
        $FunctionalProvider<
          WebDavDataSource,
          WebDavDataSource,
          WebDavDataSource
        >
    with $Provider<WebDavDataSource> {
  WebDavDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'webDavDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$webDavDataSourceHash();

  @$internal
  @override
  $ProviderElement<WebDavDataSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WebDavDataSource create(Ref ref) {
    return webDavDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WebDavDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WebDavDataSource>(value),
    );
  }
}

String _$webDavDataSourceHash() => r'c049695809fc3a735830749025da3b89142c27ce';

@ProviderFor(backupRepository)
final backupRepositoryProvider = BackupRepositoryProvider._();

final class BackupRepositoryProvider
    extends
        $FunctionalProvider<
          BackupRepository,
          BackupRepository,
          BackupRepository
        >
    with $Provider<BackupRepository> {
  BackupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupRepositoryHash();

  @$internal
  @override
  $ProviderElement<BackupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupRepository create(Ref ref) {
    return backupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupRepository>(value),
    );
  }
}

String _$backupRepositoryHash() => r'277ebe059346a9d46a006003ed6ec6bdeed848dc';

@ProviderFor(exportBackupUseCase)
final exportBackupUseCaseProvider = ExportBackupUseCaseProvider._();

final class ExportBackupUseCaseProvider
    extends
        $FunctionalProvider<
          ExportBackupUseCase,
          ExportBackupUseCase,
          ExportBackupUseCase
        >
    with $Provider<ExportBackupUseCase> {
  ExportBackupUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportBackupUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportBackupUseCaseHash();

  @$internal
  @override
  $ProviderElement<ExportBackupUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExportBackupUseCase create(Ref ref) {
    return exportBackupUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportBackupUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportBackupUseCase>(value),
    );
  }
}

String _$exportBackupUseCaseHash() =>
    r'cc8958e7d6fa3e9a660245b2431201ae899932f5';

@ProviderFor(importBackupUseCase)
final importBackupUseCaseProvider = ImportBackupUseCaseProvider._();

final class ImportBackupUseCaseProvider
    extends
        $FunctionalProvider<
          ImportBackupUseCase,
          ImportBackupUseCase,
          ImportBackupUseCase
        >
    with $Provider<ImportBackupUseCase> {
  ImportBackupUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importBackupUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importBackupUseCaseHash();

  @$internal
  @override
  $ProviderElement<ImportBackupUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImportBackupUseCase create(Ref ref) {
    return importBackupUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportBackupUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportBackupUseCase>(value),
    );
  }
}

String _$importBackupUseCaseHash() =>
    r'cedecc0df56e1e1630d9aa3b37a698a84f890577';

@ProviderFor(syncWithWebDavUseCase)
final syncWithWebDavUseCaseProvider = SyncWithWebDavUseCaseProvider._();

final class SyncWithWebDavUseCaseProvider
    extends
        $FunctionalProvider<
          SyncWithWebDavUseCase,
          SyncWithWebDavUseCase,
          SyncWithWebDavUseCase
        >
    with $Provider<SyncWithWebDavUseCase> {
  SyncWithWebDavUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncWithWebDavUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncWithWebDavUseCaseHash();

  @$internal
  @override
  $ProviderElement<SyncWithWebDavUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncWithWebDavUseCase create(Ref ref) {
    return syncWithWebDavUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncWithWebDavUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncWithWebDavUseCase>(value),
    );
  }
}

String _$syncWithWebDavUseCaseHash() =>
    r'3d398e4ea0c2d1f9cd4aaec2cee42ca5519fef2e';

@ProviderFor(lanSyncRepository)
final lanSyncRepositoryProvider = LanSyncRepositoryProvider._();

final class LanSyncRepositoryProvider
    extends
        $FunctionalProvider<
          LanSyncRepository,
          LanSyncRepository,
          LanSyncRepository
        >
    with $Provider<LanSyncRepository> {
  LanSyncRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lanSyncRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lanSyncRepositoryHash();

  @$internal
  @override
  $ProviderElement<LanSyncRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LanSyncRepository create(Ref ref) {
    return lanSyncRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LanSyncRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LanSyncRepository>(value),
    );
  }
}

String _$lanSyncRepositoryHash() => r'64137d9a1b4e4a6dfbfdd478c899ec11e82f9759';

/// ⛔ **必须 keepAlive**：它间接持有 `HttpServer` 与 UDP socket。被回收就等于
/// 「服务莫名其妙停了」，而且 provider 重建会起一个**新**端口，广播出去的端口与
/// 实际监听的对不上 —— 症状是「开了服务但别人连不上」。

@ProviderFor(lanSyncUseCases)
final lanSyncUseCasesProvider = LanSyncUseCasesProvider._();

/// ⛔ **必须 keepAlive**：它间接持有 `HttpServer` 与 UDP socket。被回收就等于
/// 「服务莫名其妙停了」，而且 provider 重建会起一个**新**端口，广播出去的端口与
/// 实际监听的对不上 —— 症状是「开了服务但别人连不上」。

final class LanSyncUseCasesProvider
    extends
        $FunctionalProvider<LanSyncUseCases, LanSyncUseCases, LanSyncUseCases>
    with $Provider<LanSyncUseCases> {
  /// ⛔ **必须 keepAlive**：它间接持有 `HttpServer` 与 UDP socket。被回收就等于
  /// 「服务莫名其妙停了」，而且 provider 重建会起一个**新**端口，广播出去的端口与
  /// 实际监听的对不上 —— 症状是「开了服务但别人连不上」。
  LanSyncUseCasesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lanSyncUseCasesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lanSyncUseCasesHash();

  @$internal
  @override
  $ProviderElement<LanSyncUseCases> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LanSyncUseCases create(Ref ref) {
    return lanSyncUseCases(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LanSyncUseCases value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LanSyncUseCases>(value),
    );
  }
}

String _$lanSyncUseCasesHash() => r'b79ef000c3cd256140215cc5f5941af18f280ba2';

@ProviderFor(listBackupHistoryUseCase)
final listBackupHistoryUseCaseProvider = ListBackupHistoryUseCaseProvider._();

final class ListBackupHistoryUseCaseProvider
    extends
        $FunctionalProvider<
          ListBackupHistoryUseCase,
          ListBackupHistoryUseCase,
          ListBackupHistoryUseCase
        >
    with $Provider<ListBackupHistoryUseCase> {
  ListBackupHistoryUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listBackupHistoryUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listBackupHistoryUseCaseHash();

  @$internal
  @override
  $ProviderElement<ListBackupHistoryUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ListBackupHistoryUseCase create(Ref ref) {
    return listBackupHistoryUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ListBackupHistoryUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ListBackupHistoryUseCase>(value),
    );
  }
}

String _$listBackupHistoryUseCaseHash() =>
    r'ba616218679eff3b3946da6225d4e577fb202453';

@ProviderFor(restoreBackupVersionUseCase)
final restoreBackupVersionUseCaseProvider =
    RestoreBackupVersionUseCaseProvider._();

final class RestoreBackupVersionUseCaseProvider
    extends
        $FunctionalProvider<
          RestoreBackupVersionUseCase,
          RestoreBackupVersionUseCase,
          RestoreBackupVersionUseCase
        >
    with $Provider<RestoreBackupVersionUseCase> {
  RestoreBackupVersionUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreBackupVersionUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreBackupVersionUseCaseHash();

  @$internal
  @override
  $ProviderElement<RestoreBackupVersionUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RestoreBackupVersionUseCase create(Ref ref) {
    return restoreBackupVersionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RestoreBackupVersionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RestoreBackupVersionUseCase>(value),
    );
  }
}

String _$restoreBackupVersionUseCaseHash() =>
    r'0c8e5b569cfe7c2a8709adde1b98853a1f945009';

@ProviderFor(testWebDavUseCase)
final testWebDavUseCaseProvider = TestWebDavUseCaseProvider._();

final class TestWebDavUseCaseProvider
    extends
        $FunctionalProvider<
          TestWebDavUseCase,
          TestWebDavUseCase,
          TestWebDavUseCase
        >
    with $Provider<TestWebDavUseCase> {
  TestWebDavUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'testWebDavUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$testWebDavUseCaseHash();

  @$internal
  @override
  $ProviderElement<TestWebDavUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TestWebDavUseCase create(Ref ref) {
    return testWebDavUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TestWebDavUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TestWebDavUseCase>(value),
    );
  }
}

String _$testWebDavUseCaseHash() => r'146fce22a04e9f895168ef8576a9450e6239141f';

@ProviderFor(getWebDavConfigUseCase)
final getWebDavConfigUseCaseProvider = GetWebDavConfigUseCaseProvider._();

final class GetWebDavConfigUseCaseProvider
    extends
        $FunctionalProvider<
          GetWebDavConfigUseCase,
          GetWebDavConfigUseCase,
          GetWebDavConfigUseCase
        >
    with $Provider<GetWebDavConfigUseCase> {
  GetWebDavConfigUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getWebDavConfigUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getWebDavConfigUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetWebDavConfigUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetWebDavConfigUseCase create(Ref ref) {
    return getWebDavConfigUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetWebDavConfigUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetWebDavConfigUseCase>(value),
    );
  }
}

String _$getWebDavConfigUseCaseHash() =>
    r'2be596bf7eb411a6dc01e1d6db8f17bd771a39c4';

@ProviderFor(saveWebDavConfigUseCase)
final saveWebDavConfigUseCaseProvider = SaveWebDavConfigUseCaseProvider._();

final class SaveWebDavConfigUseCaseProvider
    extends
        $FunctionalProvider<
          SaveWebDavConfigUseCase,
          SaveWebDavConfigUseCase,
          SaveWebDavConfigUseCase
        >
    with $Provider<SaveWebDavConfigUseCase> {
  SaveWebDavConfigUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveWebDavConfigUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveWebDavConfigUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveWebDavConfigUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveWebDavConfigUseCase create(Ref ref) {
    return saveWebDavConfigUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveWebDavConfigUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveWebDavConfigUseCase>(value),
    );
  }
}

String _$saveWebDavConfigUseCaseHash() =>
    r'5d000b6db78159d4c8453a77d7a312b9199106b4';
