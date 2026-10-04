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
/// 异步的，`AsyncNotifier` 会让 P5 必然先渲染一帧 loading，且 P1/P3 读偏好也得
/// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
/// microtask 里读一次持久化值，读到后 state 自动重建
///（`ARCHITECTURE-DESIGN.md` §6.2 P5 段）。
///
/// TODO(Q33): 加载 / 保存失败只记日志，不回滚、不弹 Snackbar —— 用户无法修复，
/// 弹窗只会吓人，且错误态视觉无稿。
///
/// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
/// （比如用户离开 P1）松手时把 state 丢掉 —— 下次进 P5 读到的又是默认值，
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
/// 异步的，`AsyncNotifier` 会让 P5 必然先渲染一帧 loading，且 P1/P3 读偏好也得
/// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
/// microtask 里读一次持久化值，读到后 state 自动重建
///（`ARCHITECTURE-DESIGN.md` §6.2 P5 段）。
///
/// TODO(Q33): 加载 / 保存失败只记日志，不回滚、不弹 Snackbar —— 用户无法修复，
/// 弹窗只会吓人，且错误态视觉无稿。
///
/// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
/// （比如用户离开 P1）松手时把 state 丢掉 —— 下次进 P5 读到的又是默认值，
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
  /// 异步的，`AsyncNotifier` 会让 P5 必然先渲染一帧 loading，且 P1/P3 读偏好也得
  /// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
  /// microtask 里读一次持久化值，读到后 state 自动重建
  ///（`ARCHITECTURE-DESIGN.md` §6.2 P5 段）。
  ///
  /// TODO(Q33): 加载 / 保存失败只记日志，不回滚、不弹 Snackbar —— 用户无法修复，
  /// 弹窗只会吓人，且错误态视觉无稿。
  ///
  /// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
  ///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
  /// （比如用户离开 P1）松手时把 state 丢掉 —— 下次进 P5 读到的又是默认值，
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

String _$settingsHash() => r'a9e4607ddbb51f93d769d5c25bd48a42de78c856';

/// 全局用户偏好。**唯一的读入口**。
///
/// ⛔ **`settings` feature 的公开面只有 2 个符号**：本 provider 与 `AppSettings`
/// 实体。Repository / UseCase / DataSource **不导出**（`FEATURE-DEPENDENCIES.md`
/// §5.1）—— 一旦有人 import `features/settings/data/...`，R2 禁令被打破时的
/// 破坏面就被限制在这一个文件里。
///
/// **为什么是 `Notifier` 而不是 `AsyncNotifier`**：首次读 `SharedPreferences` 是
/// 异步的，`AsyncNotifier` 会让 P5 必然先渲染一帧 loading，且 P1/P3 读偏好也得
/// 处理 `AsyncValue`。这里 `build()` 同步给默认值（UI 立刻能用），再在
/// microtask 里读一次持久化值，读到后 state 自动重建
///（`ARCHITECTURE-DESIGN.md` §6.2 P5 段）。
///
/// TODO(Q33): 加载 / 保存失败只记日志，不回滚、不弹 Snackbar —— 用户无法修复，
/// 弹窗只会吓人，且错误态视觉无稿。
///
/// **`keepAlive: true` 不是可选项**：偏好是 App 级全局状态
///（`ARCHITECTURE-DESIGN.md` §8.3）。默认的 autoDispose 会在最后一个监听者
/// （比如用户离开 P1）松手时把 state 丢掉 —— 下次进 P5 读到的又是默认值，
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

/// 文字大小 → 排版缩放系数。
///
/// 这是 R1（`core/` 不 import `features/`）在排版场景下的**唯一桥**：
/// `core/theme/tokens/app_text_styles.dart` 的字阶方法只收 `double`，
/// 不认识 `TextScaleLevel`。消费方（TASK-047 的 P1 卡片 / P3 正文）只
/// `ref.watch(textScaleFactorProvider)` 一个 double，⛔ 不 import `features/settings`。
///
/// ⛔ **不接 `MediaQuery.textScaler`**：与用户系统的字号缩放相乘会让正文到 42sp
/// （`PROJECT-STATUS.md` §6.5 A7）。

@ProviderFor(textScaleFactor)
final textScaleFactorProvider = TextScaleFactorProvider._();

/// 文字大小 → 排版缩放系数。
///
/// 这是 R1（`core/` 不 import `features/`）在排版场景下的**唯一桥**：
/// `core/theme/tokens/app_text_styles.dart` 的字阶方法只收 `double`，
/// 不认识 `TextScaleLevel`。消费方（TASK-047 的 P1 卡片 / P3 正文）只
/// `ref.watch(textScaleFactorProvider)` 一个 double，⛔ 不 import `features/settings`。
///
/// ⛔ **不接 `MediaQuery.textScaler`**：与用户系统的字号缩放相乘会让正文到 42sp
/// （`PROJECT-STATUS.md` §6.5 A7）。

final class TextScaleFactorProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// 文字大小 → 排版缩放系数。
  ///
  /// 这是 R1（`core/` 不 import `features/`）在排版场景下的**唯一桥**：
  /// `core/theme/tokens/app_text_styles.dart` 的字阶方法只收 `double`，
  /// 不认识 `TextScaleLevel`。消费方（TASK-047 的 P1 卡片 / P3 正文）只
  /// `ref.watch(textScaleFactorProvider)` 一个 double，⛔ 不 import `features/settings`。
  ///
  /// ⛔ **不接 `MediaQuery.textScaler`**：与用户系统的字号缩放相乘会让正文到 42sp
  /// （`PROJECT-STATUS.md` §6.5 A7）。
  TextScaleFactorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textScaleFactorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textScaleFactorHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return textScaleFactor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$textScaleFactorHash() => r'91ee78ce97c9a540a35343746bf8e66aba7fd5ec';
