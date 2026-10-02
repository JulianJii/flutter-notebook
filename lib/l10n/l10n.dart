
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'app_localizations_delegate.dart';

/// 处理应用中本地化的主类
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('zh'), // 中文
    Locale('en'), // 英语
  ];

  static bool isSupported(Locale locale) {
    return supportedLocales.contains(Locale(locale.languageCode));
  }

  /// 根据 key 获取本地化字符串
  String translate(String key) {
    final languageMap = localizedValues[locale.languageCode];
    if (languageMap == null) {
      return localizedValues['zh']?[key] ?? key;
    }
    return languageMap[key] ?? localizedValues['zh']?[key] ?? key;
  }

  /// 获取带参数替换的本地化字符串
  String translateWithParams(String key, Map<String, String> params) {
    String value = translate(key);
    params.forEach((paramKey, paramValue) {
      value = value.replaceAll('{$paramKey}', paramValue);
    });
    return value;
  }

  // 各种数据类型的格式化方法

  /// 使用当前语言环境格式化货币
  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: locale.toString(),
      symbol: getCurrencySymbol(),
    ).format(amount);
  }

  /// 使用当前语言环境格式化日期
  String formatDate(DateTime date) {
    return DateFormat.yMMMd(locale.toString()).format(date);
  }

  /// 使用当前语言环境格式化时间
  String formatTime(DateTime time) {
    return DateFormat.Hm(locale.toString()).format(time);
  }

  /// 根据语言环境获取合适的货币符号
  String getCurrencySymbol() {
    switch (locale.languageCode) {
      case 'zh':
        return '¥';
      default:
        return '\$';
    }
  }
}

// 简单的翻译映射表 - 在类之间共享
final Map<String, Map<String, String>> localizedValues = {
  'zh': {
    'app_title': 'Flutter Riverpod 整洁架构',
    'welcome_message': '欢迎使用 Flutter Riverpod 整洁架构',
    'home': '首页',
    'settings': '设置',
    'profile': '个人中心',
    'dark_mode': '深色模式',
    'light_mode': '浅色模式',
    'system_mode': '跟随系统',
    'language': '语言',
    'logout': '退出登录',
    'login': '登录',
    'email': '邮箱',
    'password': '密码',
    'sign_in': '登录',
    'register': '注册',
    'forgot_password': '忘记密码？',
    'error_occurred': '发生错误',
    'try_again': '重试',
    'cancel': '取消',
    'save': '保存',
    'delete': '删除',
    'edit': '编辑',
    'no_data': '暂无数据',
    'loading': '加载中...',
    'cache_expired': '缓存已过期',
    'cache_updated': '缓存更新成功',
  },
  'en': {
    'app_title': 'Flutter Riverpod Clean Architecture',
    'welcome_message': 'Welcome to Flutter Riverpod Clean Architecture',
    'home': 'Home',
    'settings': 'Settings',
    'profile': 'Profile',
    'dark_mode': 'Dark Mode',
    'light_mode': 'Light Mode',
    'system_mode': 'System Mode',
    'language': 'Language',
    'logout': 'Logout',
    'login': 'Login',
    'email': 'Email',
    'password': 'Password',
    'sign_in': 'Sign In',
    'register': 'Register',
    'forgot_password': 'Forgot Password?',
    'error_occurred': 'An error occurred',
    'try_again': 'Try Again',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'no_data': 'No data available',
    'loading': 'Loading...',
    'cache_expired': 'Cache has expired',
    'cache_updated': 'Cache updated successfully',
  },
};

/// 用于更便捷地访问本地化方法的 BuildContext 扩展
extension LocalizationExtension on BuildContext {
  /// 获取 AppLocalizations 实例
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// 将 key 翻译为当前语言
  String tr(String key) => l10n.translate(key);

  /// 带参数替换地翻译 key
  String trParams(String key, Map<String, String> params) =>
      l10n.translateWithParams(key, params);

  /// 根据当前语言环境格式化货币
  String currency(double amount) => l10n.formatCurrency(amount);

  /// 根据当前语言环境格式化日期
  String formatDate(DateTime date) => l10n.formatDate(date);

  /// 根据当前语言环境格式化时间
  String formatTime(DateTime time) => l10n.formatTime(time);
}
