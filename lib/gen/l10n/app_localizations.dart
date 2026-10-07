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

  /// Note list page large title and bottom navigation tab label
  ///
  /// In zh, this message translates to:
  /// **'笔记'**
  String get notes;

  /// To-do list page large title and bottom navigation tab label
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

  /// Tooltip of the note detail top bar back button
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// Tooltip of the note detail top bar share icon
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// Tooltip of the note detail top bar palette icon
  ///
  /// In zh, this message translates to:
  /// **'配色'**
  String get palette;

  /// Title of the note detail background picker sheet and the accessibility label of a background thumbnail
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get noteBackground;

  /// Accessibility label of the blank (no background) thumbnail in the note detail background picker sheet
  ///
  /// In zh, this message translates to:
  /// **'无背景'**
  String get noteBackgroundNone;

  /// Tooltip of the note detail top bar overflow icon
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// Folder manager folder manager screen large title and the note list top bar folder icon tooltip
  ///
  /// In zh, this message translates to:
  /// **'文件夹'**
  String get folders;

  /// Label of the create-folder action row at the end of the folder manager folder list, and the title of the create-folder dialog
  ///
  /// In zh, this message translates to:
  /// **'新建文件夹'**
  String get createFolder;

  /// Hint text of the create-folder dialog text field (folder manager)
  ///
  /// In zh, this message translates to:
  /// **'文件夹名称'**
  String get folderName;

  /// Title of the create-todo dialog opened by the to-do list FAB
  ///
  /// In zh, this message translates to:
  /// **'新建待办'**
  String get createTodo;

  /// Hint text of the create-todo dialog text field (to-do list)
  ///
  /// In zh, this message translates to:
  /// **'待办标题'**
  String get todoTitle;

  /// Confirm button of the create-folder dialog (folder manager)
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// Tooltip of the folder manager top bar trash icon
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// Placeholder shown in the note detail note title field when it is empty
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get noteTitleHint;

  /// Word count shown in the note detail note meta line
  ///
  /// In zh, this message translates to:
  /// **'{count}字'**
  String noteMetaWordCount(int count);

  /// Settings section header: note appearance
  ///
  /// In zh, this message translates to:
  /// **'笔记样式'**
  String get settingsGroupNoteStyle;

  /// Settings section header: quick actions
  ///
  /// In zh, this message translates to:
  /// **'快捷功能'**
  String get settingsGroupQuick;

  /// Settings section header: misc
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get settingsGroupOther;

  /// Settings chevron row leading to the trash screen, and its page title
  ///
  /// In zh, this message translates to:
  /// **'最近删除'**
  String get settingsRecentDeleted;

  /// Settings chevron row
  ///
  /// In zh, this message translates to:
  /// **'速记'**
  String get settingsQuickCapture;

  /// Settings chevron row
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get settingsPrivacyPolicy;

  /// Settings chevron row
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get settingsUserAgreement;

  /// Settings stepper row title: font size
  ///
  /// In zh, this message translates to:
  /// **'文字大小'**
  String get settingsTextScale;

  /// Settings stepper row title: note sort order
  ///
  /// In zh, this message translates to:
  /// **'选择排序方式'**
  String get settingsNoteSort;

  /// Settings stepper row title: note list layout
  ///
  /// In zh, this message translates to:
  /// **'笔记列表布局'**
  String get settingsNoteLayout;

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

  /// Title of the theme page and of its entry row in settings
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get themeTitle;

  /// Section header of the light / dark / system segmented control
  ///
  /// In zh, this message translates to:
  /// **'明暗模式'**
  String get themeSectionBrightness;

  /// Section header of the color scheme list
  ///
  /// In zh, this message translates to:
  /// **'配色方案'**
  String get themeSectionPalette;

  /// Summary line showing the selected palette and brightness
  ///
  /// In zh, this message translates to:
  /// **'当前：{scheme} · {mode}'**
  String themeCurrent(String scheme, String mode);

  /// Color scheme option: amber
  ///
  /// In zh, this message translates to:
  /// **'琥珀'**
  String get themePaletteAmber;

  /// Color scheme option: blue
  ///
  /// In zh, this message translates to:
  /// **'蓝色'**
  String get themePaletteBlue;

  /// Color scheme option: green
  ///
  /// In zh, this message translates to:
  /// **'绿色'**
  String get themePaletteGreen;

  /// Color scheme option: violet
  ///
  /// In zh, this message translates to:
  /// **'紫色'**
  String get themePaletteViolet;

  /// Theme mode option: follow system
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsThemeSystem;

  /// Theme mode option: light
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get settingsThemeLight;

  /// Theme mode option: dark
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get settingsThemeDark;

  /// Placeholder of the note search field
  ///
  /// In zh, this message translates to:
  /// **'搜索笔记'**
  String get notesSearchHint;

  /// Accessibility label of the button that clears the note search field
  ///
  /// In zh, this message translates to:
  /// **'清除搜索'**
  String get notesSearchClear;

  /// Menu action that deletes the current note
  ///
  /// In zh, this message translates to:
  /// **'删除笔记'**
  String get deleteNote;

  /// Body of the note deletion confirmation dialog (soft delete, recoverable)
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这篇笔记吗？删除后可在「最近删除」中恢复。'**
  String get deleteNoteConfirm;

  /// Snackbar shown after a note is soft deleted
  ///
  /// In zh, this message translates to:
  /// **'已移到「最近删除」'**
  String get noteDeleted;

  /// Empty state of the trash screen
  ///
  /// In zh, this message translates to:
  /// **'没有已删除的笔记'**
  String get trashEmpty;

  /// Restore action of a trash row
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get trashRestore;

  /// Snackbar shown after a note is restored
  ///
  /// In zh, this message translates to:
  /// **'已恢复'**
  String get restoreDone;

  /// Permanent delete action of a trash row
  ///
  /// In zh, this message translates to:
  /// **'永久删除'**
  String get trashDeleteForever;

  /// Body of the permanent delete confirmation dialog
  ///
  /// In zh, this message translates to:
  /// **'永久删除后无法恢复，确定要删除吗？'**
  String get trashDeleteForeverConfirm;

  /// Top bar action that empties the trash, and its confirm button
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get trashEmptyAction;

  /// Body of the empty-trash confirmation dialog
  ///
  /// In zh, this message translates to:
  /// **'确定要清空所有已删除的笔记吗？此操作无法撤销。'**
  String get trashEmptyConfirm;

  /// Snackbar shown after the trash is emptied
  ///
  /// In zh, this message translates to:
  /// **'已清空'**
  String get emptyDone;

  /// Deleted date shown on a trash row
  ///
  /// In zh, this message translates to:
  /// **'删除于 {date}'**
  String trashDeletedAt(DateTime date);

  /// Intro paragraph of the privacy policy page
  ///
  /// In zh, this message translates to:
  /// **'「笔记」是一款纯本地应用。我们非常重视您的隐私，请在使用前仔细阅读本政策。'**
  String get privacyPolicyIntro;

  /// Privacy policy section heading
  ///
  /// In zh, this message translates to:
  /// **'数据收集与存储'**
  String get privacyPolicyDataTitle;

  /// Privacy policy section body
  ///
  /// In zh, this message translates to:
  /// **'本应用不收集、不上传您的任何个人数据。全部笔记、待办与设置仅保存在您的设备本地，卸载应用或主动删除后即彻底清除。'**
  String get privacyPolicyDataBody;

  /// Privacy policy section heading
  ///
  /// In zh, this message translates to:
  /// **'权限使用'**
  String get privacyPolicyPermissionTitle;

  /// Privacy policy section body
  ///
  /// In zh, this message translates to:
  /// **'仅当您主动使用通知、分享等相应功能时，应用才会调用对应系统能力，不会在后台读取您的个人信息。'**
  String get privacyPolicyPermissionBody;

  /// Privacy policy section heading
  ///
  /// In zh, this message translates to:
  /// **'数据共享'**
  String get privacyPolicySharingTitle;

  /// Privacy policy section body
  ///
  /// In zh, this message translates to:
  /// **'本应用没有云端服务，不存在向任何第三方共享或传输您内容的行为。'**
  String get privacyPolicySharingBody;

  /// Privacy policy section heading
  ///
  /// In zh, this message translates to:
  /// **'政策更新'**
  String get privacyPolicyUpdatesTitle;

  /// Privacy policy section body
  ///
  /// In zh, this message translates to:
  /// **'本政策如有重大变更，将在应用内或版本更新说明中公布。变更后继续使用即表示您同意更新后的政策。'**
  String get privacyPolicyUpdatesBody;

  /// Privacy policy section heading
  ///
  /// In zh, this message translates to:
  /// **'联系我们'**
  String get privacyPolicyContactTitle;

  /// Privacy policy section body
  ///
  /// In zh, this message translates to:
  /// **'如您对本政策有任何疑问或建议，请通过应用商店页面提供的联系方式与我们联系。'**
  String get privacyPolicyContactBody;

  /// Intro paragraph of the user agreement page
  ///
  /// In zh, this message translates to:
  /// **'欢迎您使用「笔记」。在开始使用前，请您仔细阅读并理解本协议。'**
  String get userAgreementIntro;

  /// User agreement section heading
  ///
  /// In zh, this message translates to:
  /// **'协议的接受'**
  String get agreementAcceptTitle;

  /// User agreement section body
  ///
  /// In zh, this message translates to:
  /// **'您下载、安装或使用本应用，即表示您已阅读并同意本协议的全部内容。如您不同意本协议，请立即停止使用。'**
  String get agreementAcceptBody;

  /// User agreement section heading
  ///
  /// In zh, this message translates to:
  /// **'使用规范'**
  String get agreementUseTitle;

  /// User agreement section body
  ///
  /// In zh, this message translates to:
  /// **'您承诺不利用本应用制作、存储或传播违反法律法规的内容，不得对应用进行反向工程、恶意攻击或其他影响正常使用的行为。'**
  String get agreementUseBody;

  /// User agreement section heading
  ///
  /// In zh, this message translates to:
  /// **'内容归属'**
  String get agreementOwnershipTitle;

  /// User agreement section body
  ///
  /// In zh, this message translates to:
  /// **'您在本应用中创建的笔记、待办等内容归您本人所有。本应用的界面、图标与程序本身的权利归开发者所有。'**
  String get agreementOwnershipBody;

  /// User agreement section heading
  ///
  /// In zh, this message translates to:
  /// **'免责声明'**
  String get agreementLiabilityTitle;

  /// User agreement section body
  ///
  /// In zh, this message translates to:
  /// **'本应用将数据保存在您的设备本地。因设备丢失、系统故障、卸载应用或误操作导致的数据丢失，开发者不承担责任，请自行妥善备份重要内容。'**
  String get agreementLiabilityBody;

  /// User agreement section heading
  ///
  /// In zh, this message translates to:
  /// **'协议变更'**
  String get agreementUpdatesTitle;

  /// User agreement section body
  ///
  /// In zh, this message translates to:
  /// **'本协议如有变更，将在应用内公布。变更后继续使用即表示您接受更新后的协议。'**
  String get agreementUpdatesBody;

  /// Title of the todo edit dialog
  ///
  /// In zh, this message translates to:
  /// **'编辑待办'**
  String get editTodo;

  /// Action that deletes the edited todo
  ///
  /// In zh, this message translates to:
  /// **'删除待办'**
  String get deleteTodo;

  /// Body of the todo deletion confirmation dialog
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这条待办吗？此操作无法撤销。'**
  String get deleteTodoConfirm;

  /// Snackbar shown when persisting a to-do toggle fails
  ///
  /// In zh, this message translates to:
  /// **'勾选没有保存成功，已恢复原状态'**
  String get todoToggleFailed;

  /// Collapsed section header of finished to-dos
  ///
  /// In zh, this message translates to:
  /// **'已完成 {count}'**
  String todoDoneSection(int count);

  /// Tooltip of the to-do list top bar action that clears finished to-dos
  ///
  /// In zh, this message translates to:
  /// **'清除已完成'**
  String get clearCompletedTodos;

  /// Body of the clear-completed confirmation dialog
  ///
  /// In zh, this message translates to:
  /// **'确定要清除全部已完成的待办吗？此操作无法撤销。'**
  String get clearCompletedTodosConfirm;

  /// Empty state of the to-do list
  ///
  /// In zh, this message translates to:
  /// **'还没有待办'**
  String get emptyTodos;

  /// Label of the reminder row in the to-do detail sheet
  ///
  /// In zh, this message translates to:
  /// **'提醒时间'**
  String get todoReminder;

  /// Placeholder shown when a to-do has no reminder
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get todoReminderNone;

  /// Title of the bottom sheet that picks a reminder date and time
  ///
  /// In zh, this message translates to:
  /// **'设置提醒时间'**
  String get todoReminderTitle;

  /// Row that opens the date picker
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get todoReminderDate;

  /// Row that opens the time picker
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get todoReminderTime;

  /// Action that removes the reminder of a to-do
  ///
  /// In zh, this message translates to:
  /// **'清除提醒'**
  String get todoReminderClear;

  /// Tooltip of the clock icon that opens the reminder sheet
  ///
  /// In zh, this message translates to:
  /// **'设置提醒时间'**
  String get todoReminderPickTime;

  /// Button that marks the to-do as done
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get todoComplete;

  /// Button that marks a finished to-do as not done again
  ///
  /// In zh, this message translates to:
  /// **'重新打开'**
  String get todoReopen;

  /// Body of the reminder notification
  ///
  /// In zh, this message translates to:
  /// **'你有一条待办要处理'**
  String get todoReminderNotificationBody;

  /// Snackbar shown after a reminder is set
  ///
  /// In zh, this message translates to:
  /// **'提醒已设置'**
  String get todoReminderSaved;

  /// Snackbar shown after a reminder is removed
  ///
  /// In zh, this message translates to:
  /// **'提醒已清除'**
  String get todoReminderCleared;

  /// Snackbar shown when the picked reminder time is in the past
  ///
  /// In zh, this message translates to:
  /// **'提醒时间要晚于现在'**
  String get todoReminderPast;

  /// Snackbar shown when the notification permission is denied
  ///
  /// In zh, this message translates to:
  /// **'没有通知权限，去系统设置里打开后才能提醒'**
  String get todoReminderPermissionDenied;

  /// Snackbar shown when setting or clearing a reminder fails
  ///
  /// In zh, this message translates to:
  /// **'提醒没有设置成功，请再试一次'**
  String get todoReminderFailed;

  /// Empty state of the note list when a search term matches nothing
  ///
  /// In zh, this message translates to:
  /// **'没有找到相关笔记'**
  String get emptySearchResult;

  /// When something was last updated
  ///
  /// In zh, this message translates to:
  /// **'最后更新：{date}'**
  String last_updated(DateTime date);

  /// Settings row that opens the data and sync page
  ///
  /// In zh, this message translates to:
  /// **'数据与同步'**
  String get settingsDataManagement;

  /// Title of the data management screen
  ///
  /// In zh, this message translates to:
  /// **'数据与同步'**
  String get dataTitle;

  /// Section header of the export group
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get dataGroupExport;

  /// Row that exports a JSON snapshot
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get dataExport;

  /// Subtitle of the export row
  ///
  /// In zh, this message translates to:
  /// **'把全部笔记、文件夹与待办存成一份 JSON 快照文件'**
  String get dataExportDesc;

  /// Section header of the import group
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get dataGroupImport;

  /// Row that imports a JSON snapshot
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get dataImport;

  /// Subtitle of the import row
  ///
  /// In zh, this message translates to:
  /// **'从 JSON 快照合并进来，同一条记录保留更新时间更晚的那份'**
  String get dataImportDesc;

  /// Section header of the WebDAV group
  ///
  /// In zh, this message translates to:
  /// **'WebDAV 同步'**
  String get dataGroupWebDav;

  /// Row that opens the WebDAV config screen
  ///
  /// In zh, this message translates to:
  /// **'服务器'**
  String get dataWebDavServer;

  /// Value shown when no WebDAV server is configured
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get dataWebDavNotConfigured;

  /// Row that syncs with the WebDAV server right away
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get dataSyncNow;

  /// Switch row that enables syncing on app start
  ///
  /// In zh, this message translates to:
  /// **'启动时自动同步'**
  String get dataSyncAutoOnStart;

  /// Subtitle of the auto-sync switch row
  ///
  /// In zh, this message translates to:
  /// **'打开后每次启动应用会自动同步一次'**
  String get dataSyncAutoOnStartDesc;

  /// Footer shown when the app never synced
  ///
  /// In zh, this message translates to:
  /// **'尚未同步'**
  String get dataLastSyncNever;

  /// Footer showing when the last sync happened
  ///
  /// In zh, this message translates to:
  /// **'上次同步：{date}'**
  String dataLastSyncAt(DateTime date);

  /// Snackbar shown after an export
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 条记录'**
  String dataExportDone(int count);

  /// Snackbar shown after an import
  ///
  /// In zh, this message translates to:
  /// **'已导入：新增 {inserted} 条，更新 {updated} 条'**
  String dataImportDone(int inserted, int updated);

  /// Snackbar shown after a sync that changed something
  ///
  /// In zh, this message translates to:
  /// **'同步完成：新增 {inserted} 条，更新 {updated} 条'**
  String dataSyncDone(int inserted, int updated);

  /// Snackbar shown after a sync that changed nothing
  ///
  /// In zh, this message translates to:
  /// **'两端数据一致，无需同步'**
  String get dataSyncNoChange;

  /// Suffix appended to the import result when rows were skipped
  ///
  /// In zh, this message translates to:
  /// **'，跳过 {skipped} 条'**
  String dataSkippedSuffix(int skipped);

  /// Snackbar shown when the server can't be reached
  ///
  /// In zh, this message translates to:
  /// **'连不上服务器，请检查网络'**
  String get dataErrorNetwork;

  /// Snackbar shown when a sync times out
  ///
  /// In zh, this message translates to:
  /// **'连接超时，请稍后重试'**
  String get dataErrorTimeout;

  /// Snackbar shown when WebDAV rejects the credentials
  ///
  /// In zh, this message translates to:
  /// **'用户名或密码不对'**
  String get dataErrorAuth;

  /// Snackbar shown when the server returns an error
  ///
  /// In zh, this message translates to:
  /// **'服务器拒绝了这次请求'**
  String get dataErrorServer;

  /// Snackbar shown when the picked file is not a snapshot
  ///
  /// In zh, this message translates to:
  /// **'这个文件不是本应用导出的数据'**
  String get dataErrorInvalidFile;

  /// Snackbar shown when syncing without a configured server
  ///
  /// In zh, this message translates to:
  /// **'还没有配置 WebDAV 服务器'**
  String get dataErrorNotConfigured;

  /// Snackbar shown for any other backup failure
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试'**
  String get dataErrorUnknown;

  /// Title of the WebDAV config screen
  ///
  /// In zh, this message translates to:
  /// **'WebDAV'**
  String get webDavTitle;

  /// Top bar action that saves the config
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get webDavSave;

  /// Snackbar shown after the config is saved
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get webDavSaved;

  /// Section header of the WebDAV credential form
  ///
  /// In zh, this message translates to:
  /// **'服务器'**
  String get webDavGroupAccount;

  /// Label of the server address field
  ///
  /// In zh, this message translates to:
  /// **'服务器地址'**
  String get webDavUrl;

  /// Label of the username field
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get webDavUsername;

  /// Label of the password field
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get webDavPassword;

  /// Tooltip of the button that reveals the password
  ///
  /// In zh, this message translates to:
  /// **'显示密码'**
  String get webDavPasswordToggle;

  /// Label of the remote file name field
  ///
  /// In zh, this message translates to:
  /// **'远端文件名'**
  String get webDavRemoteFile;

  /// Section header of the WebDAV test connection group
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get webDavGroupAction;

  /// Row that tests the connection
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get webDavTest;

  /// Inline result shown when the connection test succeeds
  ///
  /// In zh, this message translates to:
  /// **'连接成功'**
  String get webDavTestOk;

  /// Inline result shown when the connection test fails
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get webDavTestFailed;

  /// Footer explaining how WebDAV sync works
  ///
  /// In zh, this message translates to:
  /// **'数据以单个 JSON 快照文件存放在服务器上。同步是双向合并，不会删除任何一端的数据。'**
  String get webDavNote;
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
