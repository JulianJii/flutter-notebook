import 'package:init/core/logging/logger_provider.dart';
import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/settings/domain/entities/app_settings.dart';
import 'package:init/features/settings/providers/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

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
@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  /// 用户是否已在本次加载落地**之前**动过偏好。
  ///
  /// ⛔ codegen 不会为 Notifier 生成字段，这里显式声明（同 `noteEditorProvider`
  /// 的 `late String _noteId`）。keepAlive provider 的 [build] 只跑一次。
  bool _dirty = false;

  @override
  AppSettings build() {
    _dirty = false;
    Future<void>.microtask(_load);
    return AppSettings.defaults();
  }

  Future<void> _load() async {
    final result = await ref.read(getSettingsUseCaseProvider)(NoParams());
    result.fold(
      // `SettingsRepositoryImpl.load()` 读失败也返回 `Right(defaults)`，
      // `Left` 只可能是意外 —— 记一条即可，state 保持默认值。
      (failure) => _log('load failed: ${failure.message}'),
      // 用户可能在读盘落地前就改了偏好（首帧即可点）—— 那时**不能**用刚读到的
      // 旧快照覆盖他刚做的选择。宁可这一轮丢失一次加载（下次 build 会重读）。
      (settings) {
        if (!_dirty) state = settings;
      },
    );
  }

  void setTextScale(TextScaleLevel value) =>
      _write(state.copyWith(textScale: value));

  void setNoteSort(AppNoteSort value) =>
      _write(state.copyWith(noteSort: value));

  void setNoteLayout(NoteLayout value) =>
      _write(state.copyWith(noteLayout: value));

  void setStrongReminder(bool value) =>
      _write(state.copyWith(strongReminder: value));

  // ⛔ **不建 `setLocale` / `setThemeMode`**：D5 上既没有语言行也没有主题行
  // （`TASK-046` 的 Out of Scope）。为不存在的入口建 setter 是每天都要付的税。
  // P5 真出现这两行时再加。

  /// 先同步改 state（UI 立即响应），再 fire-and-forget 落盘。
  void _write(AppSettings next) {
    if (next == state) return; // 值没变就不写：重复点同一步进器不该产生一次 IO
    _dirty = true;
    state = next;
    ref.read(saveSettingsUseCaseProvider)(next).then((result) {
      // 偏好写失败**不回滚 state**（`USECASE-MAP.md` §3.2）：回滚会让用户点一下
      // 开关又弹回去，且他无从知道为什么。⚠️ 日志不记偏好值本身（隐私）。
      result.fold(
        (failure) => _log('save failed: ${failure.message}'),
        (_) => _log('saved'),
      );
    });
  }

  void _log(String message) =>
      ref.read(taggedLoggerProvider('settings')).i(message);
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
@Riverpod(keepAlive: true)
double textScaleFactor(Ref ref) =>
    switch (ref.watch(settingsProvider).textScale) {
      // TODO(Q14): 4 档文字大小的具体倍率无稿（D5 只标了「文字大小（默认）」），
      // 当前取线性值 0.875 / 1.0 / 1.125 / 1.25 待设计确认。
      TextScaleLevel.small => 0.875,
      TextScaleLevel.normal => 1.0,
      TextScaleLevel.large => 1.125,
      TextScaleLevel.xLarge => 1.25,
    };
