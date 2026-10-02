
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/providers/localization_providers.dart';
import 'package:init/l10n/app_localizations_delegate.dart';
import 'package:init/l10n/l10n.dart';
import 'package:intl/intl.dart';

/// 用于处理本地化相关功能的服务类
class LocalizationService {
  const LocalizationService(this.ref);

  final Ref ref;

  /// 获取当前语言环境
  Locale get currentLocale => ref.read(persistentLocaleProvider);

  /// 设置新的语言环境
  Future<void> setLocale(Locale locale) async {
    await ref.read(persistentLocaleProvider.notifier).setLocale(locale);
  }

  /// 重置为系统语言环境
  Future<void> resetToSystemLocale() async {
    await ref.read(persistentLocaleProvider.notifier).resetToSystemLocale();
  }

  /// 获取语言环境在其母语中的名称
  String getLocaleName(Locale locale) {
    return LocalizationUtils.getLocaleName(locale);
  }

  /// 获取所有受支持的语言环境
  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  /// 检查某个语言环境是否受支持
  bool isSupported(Locale locale) => AppLocalizations.isSupported(locale);

  /// 根据当前语言环境格式化日期
  String formatDate(DateTime date, {String? pattern}) {
    final locale = currentLocale.toString();
    if (pattern != null) {
      return DateFormat(pattern, locale).format(date);
    }
    return DateFormat.yMMMd(locale).format(date);
  }

  /// 根据当前语言环境格式化时间
  String formatTime(DateTime time, {String? pattern}) {
    final locale = currentLocale.toString();
    if (pattern != null) {
      return DateFormat(pattern, locale).format(time);
    }
    return DateFormat.Hm(locale).format(time);
  }

  /// 根据当前语言环境格式化日期和时间
  String formatDateTime(DateTime dateTime, {String? pattern}) {
    final locale = currentLocale.toString();
    if (pattern != null) {
      return DateFormat(pattern, locale).format(dateTime);
    }
    return DateFormat.yMMMd(locale).add_Hm().format(dateTime);
  }

  /// 根据当前语言环境格式化货币
  String formatCurrency(double amount, {String? symbol}) {
    final locale = currentLocale.toString();
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol ?? getCurrencySymbol(),
    ).format(amount);
  }

  /// 获取当前语言环境对应的货币符号
  String getCurrencySymbol() {
    switch (currentLocale.languageCode) {
      case 'zh':
        return '¥';
      default:
        return '\$';
    }
  }
}

/// 本地化服务的 Provider
final localizationServiceProvider = Provider<LocalizationService>((ref) {
  return LocalizationService(ref);
});

/// BuildContext 的扩展方法，用于便捷地访问本地化功能
extension LocalizationServiceExtension on BuildContext {
  /// 获取本地化服务
  LocalizationService get localization =>
      ProviderScope.containerOf(this).read(localizationServiceProvider);

  /// 设置新的语言环境
  Future<void> setLocale(Locale locale) => localization.setLocale(locale);

  /// 重置为系统语言环境
  Future<void> resetToSystemLocale() => localization.resetToSystemLocale();

  /// 获取当前语言环境
  Locale get currentLocale => localization.currentLocale;

  /// 格式化日期
  String formatDate(DateTime date, {String? pattern}) =>
      localization.formatDate(date, pattern: pattern);

  /// 格式化时间
  String formatTime(DateTime time, {String? pattern}) =>
      localization.formatTime(time, pattern: pattern);

  /// 格式化日期和时间
  String formatDateTime(DateTime dateTime, {String? pattern}) =>
      localization.formatDateTime(dateTime, pattern: pattern);

  /// 格式化货币
  String formatCurrency(double amount, {String? symbol}) =>
      localization.formatCurrency(amount, symbol: symbol);
}
