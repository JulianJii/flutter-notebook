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
  String get app_title;

  /// The welcome message displayed on the home screen
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用 Flutter Riverpod 整洁架构'**
  String get welcome_message;

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
  String get dark_mode;

  /// Label for the light mode option
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get light_mode;

  /// Label for the system theme mode option
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get system_mode;

  /// Label for the language setting
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// Placeholder shown when a list has no items
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get no_data;

  /// Placeholder shown while data is loading
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// Label for the cancel button
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

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

  /// Generic error message
  ///
  /// In zh, this message translates to:
  /// **'发生错误'**
  String get error_occurred;

  /// Label for the try again button
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get try_again;

  /// A greeting message with the person's name
  ///
  /// In zh, this message translates to:
  /// **'你好，{name}！'**
  String greeting(String name);

  /// A plural message based on an item count
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =0{没有项目} =1{1 个项目} other{{count} 个项目}}'**
  String item_count(num count);

  /// Placeholder snippet shown on a note card whose body is empty
  ///
  /// In zh, this message translates to:
  /// **'无附加文案'**
  String get noteSnippetPlaceholder;

  /// P1 page large title and bottom navigation tab label
  ///
  /// In zh, this message translates to:
  /// **'笔记'**
  String get notes;

  /// P2 page large title and bottom navigation tab label
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get todos;

  /// Filter chip meaning no folder filter is applied
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get all;

  /// Filter chip for notes without a folder
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get uncategorized;

  /// Tooltip of the P3 top bar back button
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// Tooltip of the P3 top bar share icon (Q8 unresolved)
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// Tooltip of the P3 top bar palette icon (Q10 unresolved)
  ///
  /// In zh, this message translates to:
  /// **'配色'**
  String get palette;

  /// Tooltip of the P3 top bar overflow icon (Q9 unresolved)
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// P4 folder manager screen large title and the P1 top bar folder icon tooltip
  ///
  /// In zh, this message translates to:
  /// **'文件夹'**
  String get folders;

  /// Label of the create-folder action row at the end of the P4 folder list, and the title of the create-folder dialog
  ///
  /// In zh, this message translates to:
  /// **'新建文件夹'**
  String get createFolder;

  /// Hint text of the create-folder dialog text field (P4)
  ///
  /// In zh, this message translates to:
  /// **'文件夹名称'**
  String get folderName;

  /// Confirm button of the create-folder dialog (P4)
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// Tooltip of the P4 top bar trash icon (Q11 unresolved, the button is disabled)
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// Placeholder shown in the P3 note title field when it is empty
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get noteTitleHint;

  /// Word count shown in the P3 note meta line
  ///
  /// In zh, this message translates to:
  /// **'{count}字'**
  String noteMetaWordCount(int count);

  /// P5 section header: cloud services
  ///
  /// In zh, this message translates to:
  /// **'云服务'**
  String get settingsGroupCloud;

  /// P5 section header: note appearance
  ///
  /// In zh, this message translates to:
  /// **'笔记样式'**
  String get settingsGroupNoteStyle;

  /// P5 section header: quick actions
  ///
  /// In zh, this message translates to:
  /// **'快捷功能'**
  String get settingsGroupQuick;

  /// P5 section header: reminders
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get settingsGroupReminder;

  /// P5 section header: misc
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get settingsGroupOther;

  /// P5 chevron row (Q14: no second level page)
  ///
  /// In zh, this message translates to:
  /// **'最近删除'**
  String get settingsRecentDeleted;

  /// P5 chevron row (Q14: no second level page)
  ///
  /// In zh, this message translates to:
  /// **'速记'**
  String get settingsQuickCapture;

  /// P5 chevron row (Q14: no second level page)
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get settingsPrivacyPolicy;

  /// P5 chevron row (Q14: no second level page)
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get settingsUserAgreement;

  /// P5 stepper row title: font size
  ///
  /// In zh, this message translates to:
  /// **'文字大小'**
  String get settingsTextScale;

  /// P5 stepper row title: note sort order
  ///
  /// In zh, this message translates to:
  /// **'选择排序方式'**
  String get settingsNoteSort;

  /// P5 stepper row title: note list layout
  ///
  /// In zh, this message translates to:
  /// **'笔记列表布局'**
  String get settingsNoteLayout;

  /// P5 switch row title
  ///
  /// In zh, this message translates to:
  /// **'强提醒'**
  String get settingsStrongReminder;

  /// P5 switch row subtitle
  ///
  /// In zh, this message translates to:
  /// **'持续响铃且静音和勿扰状态下仍有效'**
  String get settingsStrongReminderDesc;

  /// Font size option: small
  ///
  /// In zh, this message translates to:
  /// **'小'**
  String get settingsTextScaleSmall;

  /// Font size option: default
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get settingsTextScaleDefault;

  /// Font size option: large
  ///
  /// In zh, this message translates to:
  /// **'大'**
  String get settingsTextScaleLarge;

  /// Font size option: extra large
  ///
  /// In zh, this message translates to:
  /// **'超大'**
  String get settingsTextScaleXLarge;

  /// Sort option: most recently edited
  ///
  /// In zh, this message translates to:
  /// **'按编辑日期'**
  String get settingsSortEditedDesc;

  /// Sort option: least recently edited
  ///
  /// In zh, this message translates to:
  /// **'按编辑日期（最早）'**
  String get settingsSortEditedAsc;

  /// Sort option: most recently created
  ///
  /// In zh, this message translates to:
  /// **'按创建日期'**
  String get settingsSortCreatedDesc;

  /// Sort option: by title
  ///
  /// In zh, this message translates to:
  /// **'按标题'**
  String get settingsSortTitleAsc;

  /// Note list layout option: masonry grid
  ///
  /// In zh, this message translates to:
  /// **'宫格模式'**
  String get settingsLayoutGrid;

  /// Note list layout option: single column list
  ///
  /// In zh, this message translates to:
  /// **'列表模式'**
  String get settingsLayoutList;

  /// When something was last updated
  ///
  /// In zh, this message translates to:
  /// **'最后更新：{date}'**
  String last_updated(DateTime date);
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
