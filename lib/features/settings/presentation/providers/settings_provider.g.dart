// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全局用户偏好。**唯一的读入口**。
///
/// ⛔ **`settings` feature 的公开面只有 2 个符号**：本 provider 与 `AppSettings`
/// 实体。Repository / UseCase / DataSource **不导出**（`FEATURE-DEPENDENCIES.md`
/// §5.1）—— 一旦有人 import `features/settings/data/...`，R2 禁令被打破时的
/// 破坏面就被限制在这一个文件里。
///
/// **为什么是 `Notifier` 而不是 `AsyncNotifier`**：首次读 `SharedPreferences` 是
/// 异步的，`AsyncNotifier` 会让设置必然先渲染一帧 loading，且笔记列表/笔记详情读偏好也得
/// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
/// microtask 里读一次持久化值，读到后 state 自动重建
///（`ARCHITECTURE-DESIGN.md` §6.2 设置段）。
///
/// ⚠️ **偏好保存失败只记日志**：写偏好是 fire-and-forget（state 已经先更新），
/// 没有 UI 事件源可弹提示，而它的可恢复路径只有「重启 App」，不值得为此加状态。
///
/// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
/// （比如用户离开笔记列表）松手时把 state 丢掉 —— 下次进设置读到的又是默认值，
/// 且 [build] 里那次 microtask 加载会撞上「Ref 已被 dispose」。

@ProviderFor(Settings)
final settingsProvider = SettingsProvider._();

/// 全局用户偏好。**唯一的读入口**。
///
/// ⛔ **`settings` feature 的公开面只有 2 个符号**：本 provider 与 `AppSettings`
/// 实体。Repository / UseCase / DataSource **不导出**（`FEATURE-DEPENDENCIES.md`
/// §5.1）—— 一旦有人 import `features/settings/data/...`，R2 禁令被打破时的
/// 破坏面就被限制在这一个文件里。
///
/// **为什么是 `Notifier` 而不是 `AsyncNotifier`**：首次读 `SharedPreferences` 是
/// 异步的，`AsyncNotifier` 会让设置必然先渲染一帧 loading，且笔记列表/笔记详情读偏好也得
/// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
/// microtask 里读一次持久化值，读到后 state 自动重建
///（`ARCHITECTURE-DESIGN.md` §6.2 设置段）。
///
/// ⚠️ **偏好保存失败只记日志**：写偏好是 fire-and-forget（state 已经先更新），
/// 没有 UI 事件源可弹提示，而它的可恢复路径只有「重启 App」，不值得为此加状态。
///
/// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
/// （比如用户离开笔记列表）松手时把 state 丢掉 —— 下次进设置读到的又是默认值，
/// 且 [build] 里那次 microtask 加载会撞上「Ref 已被 dispose」。
final class SettingsProvider extends $NotifierProvider<Settings, AppSettings> {
  /// 全局用户偏好。**唯一的读入口**。
  ///
  /// ⛔ **`settings` feature 的公开面只有 2 个符号**：本 provider 与 `AppSettings`
  /// 实体。Repository / UseCase / DataSource **不导出**（`FEATURE-DEPENDENCIES.md`
  /// §5.1）—— 一旦有人 import `features/settings/data/...`，R2 禁令被打破时的
  /// 破坏面就被限制在这一个文件里。
  ///
  /// **为什么是 `Notifier` 而不是 `AsyncNotifier`**：首次读 `SharedPreferences` 是
  /// 异步的，`AsyncNotifier` 会让设置必然先渲染一帧 loading，且笔记列表/笔记详情读偏好也得
  /// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
  /// microtask 里读一次持久化值，读到后 state 自动重建
  ///（`ARCHITECTURE-DESIGN.md` §6.2 设置段）。
  ///
  /// ⚠️ **偏好保存失败只记日志**：写偏好是 fire-and-forget（state 已经先更新），
  /// 没有 UI 事件源可弹提示，而它的可恢复路径只有「重启 App」，不值得为此加状态。
  ///
  /// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
  ///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
  /// （比如用户离开笔记列表）松手时把 state 丢掉 —— 下次进设置读到的又是默认值，
  /// 且 [build] 里那次 microtask 加载会撞上「Ref 已被 dispose」。
  SettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsHash();

  @$internal
  @override
  Settings create() => Settings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppSettings>(value),
    );
  }
}

String _$settingsHash() => r'a31ad2a3ddba1bd177735f1b2f7142f863c3e845';

/// 全局用户偏好。**唯一的读入口**。
///
/// ⛔ **`settings` feature 的公开面只有 2 个符号**：本 provider 与 `AppSettings`
/// 实体。Repository / UseCase / DataSource **不导出**（`FEATURE-DEPENDENCIES.md`
/// §5.1）—— 一旦有人 import `features/settings/data/...`，R2 禁令被打破时的
/// 破坏面就被限制在这一个文件里。
///
/// **为什么是 `Notifier` 而不是 `AsyncNotifier`**：首次读 `SharedPreferences` 是
/// 异步的，`AsyncNotifier` 会让设置必然先渲染一帧 loading，且笔记列表/笔记详情读偏好也得
/// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
/// microtask 里读一次持久化值，读到后 state 自动重建
///（`ARCHITECTURE-DESIGN.md` §6.2 设置段）。
///
/// ⚠️ **偏好保存失败只记日志**：写偏好是 fire-and-forget（state 已经先更新），
/// 没有 UI 事件源可弹提示，而它的可恢复路径只有「重启 App」，不值得为此加状态。
///
/// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
/// （比如用户离开笔记列表）松手时把 state 丢掉 —— 下次进设置读到的又是默认值，
/// 且 [build] 里那次 microtask 加载会撞上「Ref 已被 dispose」。

abstract class _$Settings extends $Notifier<AppSettings> {
  AppSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppSettings, AppSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppSettings, AppSettings>,
              AppSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 设置「字体」→ **系统字体族名**（`null` = 平台默认）。
///
/// 这是 R1（`core/` 不 import `features/`）在字体场景下的**唯一桥**：
/// `AppTheme.light/dark` 只收一个 `String?`，不认识 `AppFontFamily`；把族名套进
/// 13 级字阶的那一步在 `AppTextStyles.withFontFamily`。消费方（`main.dart`）
/// 只 watch 一个 `String?`。
///
/// ⚠️ `system` 映射成 `null` 而**不是**某个具体族名：`null` 才是「平台默认」，
/// 写死 `sans-serif` 会在非 Android 平台上拿到一个解析不到的族名。

@ProviderFor(uiFontFamily)
final uiFontFamilyProvider = UiFontFamilyProvider._();

/// 设置「字体」→ **系统字体族名**（`null` = 平台默认）。
///
/// 这是 R1（`core/` 不 import `features/`）在字体场景下的**唯一桥**：
/// `AppTheme.light/dark` 只收一个 `String?`，不认识 `AppFontFamily`；把族名套进
/// 13 级字阶的那一步在 `AppTextStyles.withFontFamily`。消费方（`main.dart`）
/// 只 watch 一个 `String?`。
///
/// ⚠️ `system` 映射成 `null` 而**不是**某个具体族名：`null` 才是「平台默认」，
/// 写死 `sans-serif` 会在非 Android 平台上拿到一个解析不到的族名。

final class UiFontFamilyProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// 设置「字体」→ **系统字体族名**（`null` = 平台默认）。
  ///
  /// 这是 R1（`core/` 不 import `features/`）在字体场景下的**唯一桥**：
  /// `AppTheme.light/dark` 只收一个 `String?`，不认识 `AppFontFamily`；把族名套进
  /// 13 级字阶的那一步在 `AppTextStyles.withFontFamily`。消费方（`main.dart`）
  /// 只 watch 一个 `String?`。
  ///
  /// ⚠️ `system` 映射成 `null` 而**不是**某个具体族名：`null` 才是「平台默认」，
  /// 写死 `sans-serif` 会在非 Android 平台上拿到一个解析不到的族名。
  UiFontFamilyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uiFontFamilyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uiFontFamilyHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return uiFontFamily(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$uiFontFamilyHash() => r'aa9c8eb2d06d7280df83fb0172b6deead33cbe34';
