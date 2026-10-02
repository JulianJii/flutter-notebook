import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In zh, this message translates to:
  /// **'Flutter Riverpod 整洁架构'**
  String get appTitle;

  /// The welcome message displayed on the home screen
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用 Flutter Riverpod 整洁架构'**
  String get welcomeMessage;

  /// Label for the home tab or button
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get home;

  /// Label for the settings tab or button
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// Label for the profile tab or button
  ///
  /// In zh, this message translates to:
  /// **'个人中心'**
  String get profile;

  /// Label for the dark mode option
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// Label for the light mode option
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get lightMode;

  /// Label for the system theme mode option
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get systemMode;

  /// Label for the language setting
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// Label for changing the application language
  ///
  /// In zh, this message translates to:
  /// **'更改应用语言'**
  String get change_language;

  /// Label for theme selection
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// Label for changing the application theme
  ///
  /// In zh, this message translates to:
  /// **'更改应用主题'**
  String get change_theme;

  /// Label for notifications settings
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get notifications;

  /// Label for notification settings description
  ///
  /// In zh, this message translates to:
  /// **'配置通知偏好设置'**
  String get notification_settings;

  /// Label for the localization demo option
  ///
  /// In zh, this message translates to:
  /// **'本地化演示'**
  String get localization_demo;

  /// Description for the localization demo option
  ///
  /// In zh, this message translates to:
  /// **'查看本地化功能'**
  String get localization_demo_description;

  /// Title for the language settings screen
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get language_settings;

  /// Instruction to select a language
  ///
  /// In zh, this message translates to:
  /// **'选择您偏好的语言'**
  String get select_your_language;

  /// Explanation of the language selection effects
  ///
  /// In zh, this message translates to:
  /// **'所选语言将应用于整个应用'**
  String get language_explanation;

  /// Title for the localization assets demo screen
  ///
  /// In zh, this message translates to:
  /// **'本地化与资源演示'**
  String get localization_assets_demo;

  /// Label for displaying current language info
  ///
  /// In zh, this message translates to:
  /// **'当前语言'**
  String get current_language;

  /// Label for language code
  ///
  /// In zh, this message translates to:
  /// **'语言代码'**
  String get language_code;

  /// Label for language name
  ///
  /// In zh, this message translates to:
  /// **'语言名称'**
  String get language_name;

  /// Title for formatting examples section
  ///
  /// In zh, this message translates to:
  /// **'格式化示例'**
  String get formatting_examples;

  /// Label for full date format example
  ///
  /// In zh, this message translates to:
  /// **'日期（完整）'**
  String get date_full;

  /// Label for short date format example
  ///
  /// In zh, this message translates to:
  /// **'日期（简短）'**
  String get date_short;

  /// Label for time format example
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get time;

  /// Label for currency format example
  ///
  /// In zh, this message translates to:
  /// **'货币'**
  String get currency;

  /// Label for percent format example
  ///
  /// In zh, this message translates to:
  /// **'百分比'**
  String get percent;

  /// Title for localized assets section
  ///
  /// In zh, this message translates to:
  /// **'本地化资源'**
  String get localized_assets;

  /// Explanation of localized assets feature
  ///
  /// In zh, this message translates to:
  /// **'此部分演示如何根据所选语言加载不同的资源。图片、音频等资源均可随语言变化。'**
  String get localized_assets_explanation;

  /// Title for localized image example
  ///
  /// In zh, this message translates to:
  /// **'本地化图片示例'**
  String get image_example;

  /// Caption for the welcome image example
  ///
  /// In zh, this message translates to:
  /// **'此图片会根据您所选的语言加载'**
  String get welcome_image_caption;

  /// Title for common image example
  ///
  /// In zh, this message translates to:
  /// **'通用图片示例'**
  String get common_image_example;

  /// Caption for the common image example
  ///
  /// In zh, this message translates to:
  /// **'此图片在所有语言下都相同'**
  String get common_image_caption;

  /// Label for the logout button
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// Label for the login button
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// Label for the email field
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get email;

  /// Label for the password field
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// Label for the sign in button
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get signIn;

  /// Label for the register button
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get register;

  /// Label for the forgot password button
  ///
  /// In zh, this message translates to:
  /// **'忘记密码？'**
  String get forgotPassword;

  /// Generic error message
  ///
  /// In zh, this message translates to:
  /// **'发生错误'**
  String get errorOccurred;

  /// Label for the try again button
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get tryAgain;

  /// A greeting message with the person's name
  ///
  /// In zh, this message translates to:
  /// **'你好，{name}！'**
  String greeting(String name);

  /// A plural message based on an item count
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =0{没有项目} =1{1 个项目} other{{count} 个项目}}'**
  String itemCount(num count);

  /// When something was last updated
  ///
  /// In zh, this message translates to:
  /// **'最后更新：{date}'**
  String lastUpdated(DateTime date);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
