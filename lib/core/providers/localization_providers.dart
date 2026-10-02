import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/l10n/l10n.dart';

/// 用于在 SharedPreferences 中存储所选语言代码的键
const _languageCodeKey = 'selected_language_code';

/// 用于持久化和获取用户语言偏好设置的 Provider
final savedLocaleProvider = Provider<Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final savedLanguageCode = prefs.getString(_languageCodeKey);

  if (savedLanguageCode != null &&
      AppLocalizations.supportedLocales.any(
        (l) => l.languageCode == savedLanguageCode,
      )) {
    return Locale(savedLanguageCode);
  }

  // 默认使用系统语言，若系统语言不受支持则使用中文
  final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
  if (AppLocalizations.isSupported(systemLocale)) {
    return systemLocale;
  }

  return const Locale('zh');
});

/// 用于初始化和持久化语言环境 notifier 的 Provider
/// 用于初始化和持久化语言环境 notifier 的 Provider
final persistentLocaleProvider =
    NotifierProvider<PersistentLocaleNotifier, Locale>(
      PersistentLocaleNotifier.new,
    );

/// 用于管理带持久化的语言环境状态的 Notifier
class PersistentLocaleNotifier extends Notifier<Locale> {
  static const _languageCodeKey = 'selected_language_code';

  @override
  Locale build() {
    return ref.watch(savedLocaleProvider);
  }

  /// 设置新的语言环境并持久化该选择
  Future<void> setLocale(Locale locale) async {
    if (AppLocalizations.isSupported(locale)) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_languageCodeKey, locale.languageCode);
      state = locale;
    }
  }

  /// 重置为系统语言环境
  Future<void> resetToSystemLocale() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_languageCodeKey);
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

    if (AppLocalizations.isSupported(systemLocale)) {
      state = systemLocale;
    } else {
      state = const Locale('zh');
    }
  }
}
