// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Flutter Riverpod Clean Architecture';

  @override
  String get welcome_message =>
      'Welcome to Flutter Riverpod Clean Architecture';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get dark_mode => 'Dark Mode';

  @override
  String get light_mode => 'Light Mode';

  @override
  String get system_mode => 'System Mode';

  @override
  String get language => 'Language';

  @override
  String get no_data => 'No data available';

  @override
  String get loading => 'Loading...';

  @override
  String get cancel => 'Cancel';

  @override
  String get change_language => 'Change application language';

  @override
  String get theme => 'Theme';

  @override
  String get change_theme => 'Change application theme';

  @override
  String get notifications => 'Notifications';

  @override
  String get notification_settings => 'Configure notification preferences';

  @override
  String get localization_demo => 'Localization Demo';

  @override
  String get localization_demo_description =>
      'View localization features in action';

  @override
  String get language_settings => 'Language Settings';

  @override
  String get select_your_language => 'Select your preferred language';

  @override
  String get language_explanation =>
      'The selected language will be applied across the entire application';

  @override
  String get localization_assets_demo => 'Localization & Assets Demo';

  @override
  String get current_language => 'Current Language';

  @override
  String get language_code => 'Language code';

  @override
  String get language_name => 'Language name';

  @override
  String get formatting_examples => 'Formatting Examples';

  @override
  String get date_full => 'Date (full)';

  @override
  String get date_short => 'Date (short)';

  @override
  String get time => 'Time';

  @override
  String get currency => 'Currency';

  @override
  String get percent => 'Percent';

  @override
  String get localized_assets => 'Localized Assets';

  @override
  String get localized_assets_explanation =>
      'This section demonstrates how to load different assets based on the selected language. Images, audio, and other resources can be language-specific.';

  @override
  String get image_example => 'Localized Image Example';

  @override
  String get welcome_image_caption =>
      'This image is loaded based on your selected language';

  @override
  String get common_image_example => 'Common Image Example';

  @override
  String get common_image_caption =>
      'This image is the same across all languages';

  @override
  String get error_occurred => 'An error occurred';

  @override
  String get try_again => 'Try Again';

  @override
  String greeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String item_count(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get noteSnippetPlaceholder => 'No additional text';

  @override
  String get notes => 'Notes';

  @override
  String get todos => 'Todos';

  @override
  String get all => 'All';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get back => 'Back';

  @override
  String get share => 'Share';

  @override
  String get palette => 'Palette';

  @override
  String get more => 'More';

  @override
  String get folders => 'Folders';

  @override
  String get createFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get noteTitleHint => 'Title';

  @override
  String noteMetaWordCount(int count) {
    return '$count chars';
  }

  @override
  String get settingsGroupCloud => 'Cloud';

  @override
  String get settingsGroupNoteStyle => 'Note style';

  @override
  String get settingsGroupQuick => 'Quick actions';

  @override
  String get settingsGroupReminder => 'Reminders';

  @override
  String get settingsGroupOther => 'Other';

  @override
  String get settingsRecentDeleted => 'Recently deleted';

  @override
  String get settingsQuickCapture => 'Quick capture';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsUserAgreement => 'User agreement';

  @override
  String get settingsTextScale => 'Font size';

  @override
  String get settingsNoteSort => 'Sort by';

  @override
  String get settingsNoteLayout => 'Note list layout';

  @override
  String get settingsStrongReminder => 'Strong reminder';

  @override
  String get settingsStrongReminderDesc =>
      'Keeps ringing even when silent or do not disturb is on';

  @override
  String get settingsTextScaleSmall => 'Small';

  @override
  String get settingsTextScaleDefault => 'Default';

  @override
  String get settingsTextScaleLarge => 'Large';

  @override
  String get settingsTextScaleXLarge => 'Extra large';

  @override
  String get settingsSortEditedDesc => 'Last edited';

  @override
  String get settingsSortEditedAsc => 'First edited';

  @override
  String get settingsSortCreatedDesc => 'Recently created';

  @override
  String get settingsSortTitleAsc => 'Title';

  @override
  String get settingsLayoutGrid => 'Grid';

  @override
  String get settingsLayoutList => 'List';

  @override
  String last_updated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Last updated: $dateString';
  }
}
