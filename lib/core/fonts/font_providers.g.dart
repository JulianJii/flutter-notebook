// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 字体加载器。`keepAlive`：字体注册进引擎后在整个进程生命周期内有效，
/// 丢掉这个 service 等于丢掉「哪些字体已加载」的记忆，会重复下载。

@ProviderFor(fontLoaderService)
final fontLoaderServiceProvider = FontLoaderServiceProvider._();

/// 字体加载器。`keepAlive`：字体注册进引擎后在整个进程生命周期内有效，
/// 丢掉这个 service 等于丢掉「哪些字体已加载」的记忆，会重复下载。

final class FontLoaderServiceProvider
    extends
        $FunctionalProvider<
          FontLoaderService,
          FontLoaderService,
          FontLoaderService
        >
    with $Provider<FontLoaderService> {
  /// 字体加载器。`keepAlive`：字体注册进引擎后在整个进程生命周期内有效，
  /// 丢掉这个 service 等于丢掉「哪些字体已加载」的记忆，会重复下载。
  FontLoaderServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fontLoaderServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fontLoaderServiceHash();

  @$internal
  @override
  $ProviderElement<FontLoaderService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FontLoaderService create(Ref ref) {
    return fontLoaderService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FontLoaderService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FontLoaderService>(value),
    );
  }
}

String _$fontLoaderServiceHash() => r'1c7d3f8d9629cf8ab8ef02cc889454fb12fbc5c1';

/// 字体 id → **可直接喂给 `TextStyle.fontFamily` 的族名**。
///
/// 这是两条消费链（`main.dart` 的 UI 字体 / 笔记详情页的编辑器字体）的**唯一读入口**：
/// - [fontId] 为 `null` 或不认识的 id → 返回 `null`（= 平台默认），**不触发任何下载**；
/// - 已知 id → 先 `ensureLoaded`（首次联网下载，之后读本地缓存），成功返回族名。
///
/// ⚠️ **失败抛 [FontFailure]**：调用方取 `valueOrNull`，于是加载期间与加载失败
/// 都自然回落系统默认字体，⛔ 不阻塞启动、不阻塞打开笔记。
/// 用户需要知道失败的只有「刚点下选择」那一次 —— 那条路径在弹层里直接
/// `await ensureLoaded`（见 `AppFontPickerSheet`），不走本 provider。

@ProviderFor(fontFamilyOf)
final fontFamilyOfProvider = FontFamilyOfFamily._();

/// 字体 id → **可直接喂给 `TextStyle.fontFamily` 的族名**。
///
/// 这是两条消费链（`main.dart` 的 UI 字体 / 笔记详情页的编辑器字体）的**唯一读入口**：
/// - [fontId] 为 `null` 或不认识的 id → 返回 `null`（= 平台默认），**不触发任何下载**；
/// - 已知 id → 先 `ensureLoaded`（首次联网下载，之后读本地缓存），成功返回族名。
///
/// ⚠️ **失败抛 [FontFailure]**：调用方取 `valueOrNull`，于是加载期间与加载失败
/// 都自然回落系统默认字体，⛔ 不阻塞启动、不阻塞打开笔记。
/// 用户需要知道失败的只有「刚点下选择」那一次 —— 那条路径在弹层里直接
/// `await ensureLoaded`（见 `AppFontPickerSheet`），不走本 provider。

final class FontFamilyOfProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// 字体 id → **可直接喂给 `TextStyle.fontFamily` 的族名**。
  ///
  /// 这是两条消费链（`main.dart` 的 UI 字体 / 笔记详情页的编辑器字体）的**唯一读入口**：
  /// - [fontId] 为 `null` 或不认识的 id → 返回 `null`（= 平台默认），**不触发任何下载**；
  /// - 已知 id → 先 `ensureLoaded`（首次联网下载，之后读本地缓存），成功返回族名。
  ///
  /// ⚠️ **失败抛 [FontFailure]**：调用方取 `valueOrNull`，于是加载期间与加载失败
  /// 都自然回落系统默认字体，⛔ 不阻塞启动、不阻塞打开笔记。
  /// 用户需要知道失败的只有「刚点下选择」那一次 —— 那条路径在弹层里直接
  /// `await ensureLoaded`（见 `AppFontPickerSheet`），不走本 provider。
  FontFamilyOfProvider._({
    required FontFamilyOfFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'fontFamilyOfProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fontFamilyOfHash();

  @override
  String toString() {
    return r'fontFamilyOfProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String?;
    return fontFamilyOf(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FontFamilyOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fontFamilyOfHash() => r'61fb3239272640dfb1a2fd6681b36047e847b0cc';

/// 字体 id → **可直接喂给 `TextStyle.fontFamily` 的族名**。
///
/// 这是两条消费链（`main.dart` 的 UI 字体 / 笔记详情页的编辑器字体）的**唯一读入口**：
/// - [fontId] 为 `null` 或不认识的 id → 返回 `null`（= 平台默认），**不触发任何下载**；
/// - 已知 id → 先 `ensureLoaded`（首次联网下载，之后读本地缓存），成功返回族名。
///
/// ⚠️ **失败抛 [FontFailure]**：调用方取 `valueOrNull`，于是加载期间与加载失败
/// 都自然回落系统默认字体，⛔ 不阻塞启动、不阻塞打开笔记。
/// 用户需要知道失败的只有「刚点下选择」那一次 —— 那条路径在弹层里直接
/// `await ensureLoaded`（见 `AppFontPickerSheet`），不走本 provider。

final class FontFamilyOfFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String?> {
  FontFamilyOfFamily._()
    : super(
        retry: null,
        name: r'fontFamilyOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 字体 id → **可直接喂给 `TextStyle.fontFamily` 的族名**。
  ///
  /// 这是两条消费链（`main.dart` 的 UI 字体 / 笔记详情页的编辑器字体）的**唯一读入口**：
  /// - [fontId] 为 `null` 或不认识的 id → 返回 `null`（= 平台默认），**不触发任何下载**；
  /// - 已知 id → 先 `ensureLoaded`（首次联网下载，之后读本地缓存），成功返回族名。
  ///
  /// ⚠️ **失败抛 [FontFailure]**：调用方取 `valueOrNull`，于是加载期间与加载失败
  /// 都自然回落系统默认字体，⛔ 不阻塞启动、不阻塞打开笔记。
  /// 用户需要知道失败的只有「刚点下选择」那一次 —— 那条路径在弹层里直接
  /// `await ensureLoaded`（见 `AppFontPickerSheet`），不走本 provider。

  FontFamilyOfProvider call(String? fontId) =>
      FontFamilyOfProvider._(argument: fontId, from: this);

  @override
  String toString() => r'fontFamilyOfProvider';
}
