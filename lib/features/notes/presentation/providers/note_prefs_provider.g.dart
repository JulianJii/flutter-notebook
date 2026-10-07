// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// notes 侧**唯一**读 settings 的地方：把设置里的两个偏好翻译成 notes 自己的
/// 类型，notes 的页面因此不必认识 `settings` 的 provider。
///
/// 为什么翻译放在这里：`AppNoteSort` 与 `NoteSort` 是两个 feature 各持一份的
/// 同名枚举（features 之间不互相 import 的代价，见 `app_settings.dart` 顶部注释），
/// 4 → 4 的映射总要落在某一边；放在 notes 侧只写一次，三个页面都不必知道
/// `AppNoteSort` 的存在。
///
/// `select` 不能省：watch 整个 `AppSettings` 会让改 `themeMode` / `locale` 等
/// 无关偏好时整页（含所有可见 NoteCard）跟着重建。

@ProviderFor(noteListPrefs)
final noteListPrefsProvider = NoteListPrefsProvider._();

/// notes 侧**唯一**读 settings 的地方：把设置里的两个偏好翻译成 notes 自己的
/// 类型，notes 的页面因此不必认识 `settings` 的 provider。
///
/// 为什么翻译放在这里：`AppNoteSort` 与 `NoteSort` 是两个 feature 各持一份的
/// 同名枚举（features 之间不互相 import 的代价，见 `app_settings.dart` 顶部注释），
/// 4 → 4 的映射总要落在某一边；放在 notes 侧只写一次，三个页面都不必知道
/// `AppNoteSort` 的存在。
///
/// `select` 不能省：watch 整个 `AppSettings` 会让改 `themeMode` / `locale` 等
/// 无关偏好时整页（含所有可见 NoteCard）跟着重建。

final class NoteListPrefsProvider
    extends
        $FunctionalProvider<
          ({NoteLayout layout, NoteSort sort}),
          ({NoteLayout layout, NoteSort sort}),
          ({NoteLayout layout, NoteSort sort})
        >
    with $Provider<({NoteLayout layout, NoteSort sort})> {
  /// notes 侧**唯一**读 settings 的地方：把设置里的两个偏好翻译成 notes 自己的
  /// 类型，notes 的页面因此不必认识 `settings` 的 provider。
  ///
  /// 为什么翻译放在这里：`AppNoteSort` 与 `NoteSort` 是两个 feature 各持一份的
  /// 同名枚举（features 之间不互相 import 的代价，见 `app_settings.dart` 顶部注释），
  /// 4 → 4 的映射总要落在某一边；放在 notes 侧只写一次，三个页面都不必知道
  /// `AppNoteSort` 的存在。
  ///
  /// `select` 不能省：watch 整个 `AppSettings` 会让改 `themeMode` / `locale` 等
  /// 无关偏好时整页（含所有可见 NoteCard）跟着重建。
  NoteListPrefsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteListPrefsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteListPrefsHash();

  @$internal
  @override
  $ProviderElement<({NoteLayout layout, NoteSort sort})> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ({NoteLayout layout, NoteSort sort}) create(Ref ref) {
    return noteListPrefs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({NoteLayout layout, NoteSort sort}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<({NoteLayout layout, NoteSort sort})>(value),
    );
  }
}

String _$noteListPrefsHash() => r'38ebd0c6d0be614a1b68fbb915e4a40918d89b65';

/// 文本缩放。settings 侧导出的是 `double`（原始值，不带 settings 的任何类型），
/// 这一层只是把订阅点收进本文件 —— notes 的页面因此不必 import settings 的
/// presentation，跨 feature 依赖只剩这一个文件。

@ProviderFor(noteTextScale)
final noteTextScaleProvider = NoteTextScaleProvider._();

/// 文本缩放。settings 侧导出的是 `double`（原始值，不带 settings 的任何类型），
/// 这一层只是把订阅点收进本文件 —— notes 的页面因此不必 import settings 的
/// presentation，跨 feature 依赖只剩这一个文件。

final class NoteTextScaleProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// 文本缩放。settings 侧导出的是 `double`（原始值，不带 settings 的任何类型），
  /// 这一层只是把订阅点收进本文件 —— notes 的页面因此不必 import settings 的
  /// presentation，跨 feature 依赖只剩这一个文件。
  NoteTextScaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteTextScaleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteTextScaleHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return noteTextScale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$noteTextScaleHash() => r'c2bcca03d9facebefe0c51b0af2c1eda0d1c5aec';

/// 插入图片前是否压缩（设置项「压缩插入的图片」）。
///
/// 与 [noteTextScale] 同理：把订阅点收进本文件，笔记详情页因此不必 import
/// `settings` 的 presentation。`select` 同样不能省。

@ProviderFor(noteCompressImages)
final noteCompressImagesProvider = NoteCompressImagesProvider._();

/// 插入图片前是否压缩（设置项「压缩插入的图片」）。
///
/// 与 [noteTextScale] 同理：把订阅点收进本文件，笔记详情页因此不必 import
/// `settings` 的 presentation。`select` 同样不能省。

final class NoteCompressImagesProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 插入图片前是否压缩（设置项「压缩插入的图片」）。
  ///
  /// 与 [noteTextScale] 同理：把订阅点收进本文件，笔记详情页因此不必 import
  /// `settings` 的 presentation。`select` 同样不能省。
  NoteCompressImagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteCompressImagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteCompressImagesHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return noteCompressImages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$noteCompressImagesHash() =>
    r'100f54af122ad400a150b28467cba81232bad894';
