// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 数据管理页的三个动作。
///
/// state 只表达「哪个操作在跑」，结果通过返回值交给页面 —— 成功/失败文案需要
/// l10n，Notifier 里不该产生面向用户的字符串。

@ProviderFor(BackupController)
final backupControllerProvider = BackupControllerProvider._();

/// 数据管理页的三个动作。
///
/// state 只表达「哪个操作在跑」，结果通过返回值交给页面 —— 成功/失败文案需要
/// l10n，Notifier 里不该产生面向用户的字符串。
final class BackupControllerProvider
    extends $NotifierProvider<BackupController, BackupOperation?> {
  /// 数据管理页的三个动作。
  ///
  /// state 只表达「哪个操作在跑」，结果通过返回值交给页面 —— 成功/失败文案需要
  /// l10n，Notifier 里不该产生面向用户的字符串。
  BackupControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupControllerHash();

  @$internal
  @override
  BackupController create() => BackupController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupOperation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupOperation?>(value),
    );
  }
}

String _$backupControllerHash() => r'b027ca854dc8d98dde37d16c927e8ad1540bdf03';

/// 数据管理页的三个动作。
///
/// state 只表达「哪个操作在跑」，结果通过返回值交给页面 —— 成功/失败文案需要
/// l10n，Notifier 里不该产生面向用户的字符串。

abstract class _$BackupController extends $Notifier<BackupOperation?> {
  BackupOperation? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BackupOperation?, BackupOperation?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BackupOperation?, BackupOperation?>,
              BackupOperation?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
