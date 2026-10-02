import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n.dart';

/// 用于加载和切换 AppLocalizations 的委托
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// 这里需要条件导入或从一个
// 应用启动时会初始化的 provider 导入
final defaultLocaleProvider = Provider<Locale>((ref) => const Locale('zh'));

/// 根据当前语言环境获取翻译的 provider
/// 在应用初始化期间应使用 persistentLocaleProvider 覆盖它
final translationsProvider = Provider<Map<String, String>>((ref) {
  // 从应用启动时将被覆盖的 provider 获取语言环境
  final locale = ref.watch(defaultLocaleProvider);
  return localizedValues[locale.languageCode] ?? localizedValues['zh'] ?? {};
});

/// 本地化工具函数
class LocalizationUtils {
  /// 获取设备语言环境
  static Locale getDeviceLocale(BuildContext context) {
    return Localizations.localeOf(context);
  }

  /// 获取最佳匹配的支持的语言环境
  static Locale findSupportedLocale(Locale deviceLocale) {
    // 首先检查是否有完全匹配
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode) {
        return locale;
      }
    }

    // 默认使用中文
    return const Locale('zh');
  }

  /// 获取语言环境以其自身语言表示的名称
  static String getLocaleName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
}
