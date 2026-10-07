import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';

/// 在 SharedPreferences 中存储所选语言码的键。
///
/// 键不存在 = 用户没选过 = 跟随系统。⚠️ 键名是**已发布**的持久化格式，
/// 改它等于让老用户的语言选择静默失效。
const String languageCodeKey = 'selected_language_code';

/// gen-l10n 不生成 isSupported，本地补一个。
bool isSupportedLocale(Locale locale) => AppLocalizations.supportedLocales.any(
  (l) => l.languageCode == locale.languageCode,
);

/// 用户选择的语言，**null = 跟随系统**（没选过或主动回退）。
///
/// ⛔ **上屏不要 watch 它**：null 是合法值，交给 [appLocaleProvider] 解析。
/// 写入口只有 [PersistentLocaleNotifier.setLocale]（设置页的语言行、core 的
/// 语言选择组件都走它），⚠️ 不要再开第二份语言偏好（`AppSettings.locale`
/// 已因这个理由删除）。
final persistentLocaleProvider = NotifierProvider<PersistentLocaleNotifier,
    Locale?>(PersistentLocaleNotifier.new);

/// 实际生效的语言：用户选择 → 系统语言 → 中文（系统语言不受支持时）。
///
/// 这是「首次启动默认跟随系统语言」的**唯一落点**：没选过就不该有偏好，
/// 直接问系统。系统语言不在 `AppLocalizations.supportedLocales` 里（如法语）
/// 时回落 `zh`（`preferred-supported-locales` 的第一位）。
final appLocaleProvider = Provider<Locale>((ref) {
  final picked = ref.watch(persistentLocaleProvider);
  if (picked != null) return picked;

  final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
  return isSupportedLocale(systemLocale) ? systemLocale : const Locale('zh');
});

/// 管理带持久化的语言选择。
class PersistentLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final savedLanguageCode = ref
        .watch(sharedPreferencesProvider)
        .getString(languageCodeKey);

    // 空串不是合法语言码（手改 / 旧版本残留），按「没选过」处理。
    if (savedLanguageCode == null || savedLanguageCode.isEmpty) return null;
    return Locale(savedLanguageCode);
  }

  /// 设置语言并持久化。[locale] 为 `null` = 回到「跟随系统」（删键）。
  ///
  /// 写盘失败**不回滚** `state`：语言切换是用户当场可见的操作，弹回去他无从
  /// 知道为什么，可恢复路径只有重新选一次。
  Future<void> setLocale(Locale? locale) async {
    final prefs = ref.read(sharedPreferencesProvider);

    if (locale == null) {
      await prefs.remove(languageCodeKey);
      state = null;
      return;
    }

    if (!isSupportedLocale(locale)) return;
    await prefs.setString(languageCodeKey, locale.languageCode);
    state = locale;
  }

  /// 回到「跟随系统」。等价于 [setLocale]`(null)`。
  Future<void> resetToSystemLocale() => setLocale(null);
}
