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
  String get noteBackground => 'Background';

  @override
  String get noteBackgroundNone => 'No background';

  @override
  String get more => 'More';

  @override
  String get folders => 'Folders';

  @override
  String get createFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get createTodo => 'New todo';

  @override
  String get todoTitle => 'Todo title';

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
  String get themeTitle => 'Theme';

  @override
  String get themeSectionBrightness => 'Appearance';

  @override
  String get themeSectionPalette => 'Color scheme';

  @override
  String themeCurrent(String scheme, String mode) {
    return 'Current: $scheme · $mode';
  }

  @override
  String get themePaletteAmber => 'Amber';

  @override
  String get themePaletteBlue => 'Blue';

  @override
  String get themePaletteGreen => 'Green';

  @override
  String get themePaletteViolet => 'Violet';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsSwitchOn => 'On';

  @override
  String get settingsSwitchOff => 'Off';

  @override
  String get notesSearchHint => 'Search notes';

  @override
  String get notesSearchClear => 'Clear search';

  @override
  String get deleteNote => 'Delete note';

  @override
  String get deleteNoteConfirm =>
      'Delete this note? You can restore it from Recently deleted.';

  @override
  String get noteDeleted => 'Moved to Recently deleted';

  @override
  String get trashEmpty => 'No deleted notes';

  @override
  String get trashRestore => 'Restore';

  @override
  String get restoreDone => 'Restored';

  @override
  String get trashDeleteForever => 'Delete permanently';

  @override
  String get trashDeleteForeverConfirm =>
      'Permanently delete? This can\'t be undone.';

  @override
  String get trashEmptyAction => 'Empty';

  @override
  String get trashEmptyConfirm =>
      'Delete all notes in Recently deleted? This can\'t be undone.';

  @override
  String get emptyDone => 'Emptied';

  @override
  String trashDeletedAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Deleted $dateString';
  }

  @override
  String get privacyPolicyIntro =>
      'Notes is a fully local-first app. We take your privacy seriously — please read this policy before use.';

  @override
  String get privacyPolicyDataTitle => 'Data collection and storage';

  @override
  String get privacyPolicyDataBody =>
      'This app does not collect or upload any personal data. All notes, todos and settings stay on your device only, and are permanently removed when you uninstall the app or delete them yourself.';

  @override
  String get privacyPolicyPermissionTitle => 'Permissions';

  @override
  String get privacyPolicyPermissionBody =>
      'System capabilities such as notifications and sharing are only invoked when you actively use the corresponding features; the app never reads your personal information in the background.';

  @override
  String get privacyPolicySharingTitle => 'Data sharing';

  @override
  String get privacyPolicySharingBody =>
      'This app has no cloud service, so your content is never shared with or transferred to any third party.';

  @override
  String get privacyPolicyUpdatesTitle => 'Policy updates';

  @override
  String get privacyPolicyUpdatesBody =>
      'Material changes to this policy will be announced in the app or in release notes. Continuing to use the app after a change means you accept the updated policy.';

  @override
  String get privacyPolicyContactTitle => 'Contact us';

  @override
  String get privacyPolicyContactBody =>
      'If you have any questions or suggestions about this policy, please contact us via the channel provided on the app store page.';

  @override
  String get userAgreementIntro =>
      'Thank you for using Notes. Please read and understand this agreement carefully before you start.';

  @override
  String get agreementAcceptTitle => 'Acceptance of the agreement';

  @override
  String get agreementAcceptBody =>
      'By downloading, installing or using this app, you confirm that you have read and accepted this agreement in full. If you do not agree, please stop using the app immediately.';

  @override
  String get agreementUseTitle => 'Acceptable use';

  @override
  String get agreementUseBody =>
      'You agree not to create, store or distribute content that violates applicable laws, and not to reverse engineer, attack or otherwise interfere with the normal operation of the app.';

  @override
  String get agreementOwnershipTitle => 'Content ownership';

  @override
  String get agreementOwnershipBody =>
      'Notes, todos and other content you create in this app belong to you. Rights in the app itself, including its interface and icons, belong to the developer.';

  @override
  String get agreementLiabilityTitle => 'Disclaimer';

  @override
  String get agreementLiabilityBody =>
      'Data is stored locally on your device. The developer is not liable for data loss caused by device loss, system failure, uninstalling the app or accidental deletion. Please back up important content yourself.';

  @override
  String get agreementUpdatesTitle => 'Changes to the agreement';

  @override
  String get agreementUpdatesBody =>
      'Changes to this agreement will be announced in the app. Continuing to use the app after a change means you accept the updated agreement.';

  @override
  String get editTodo => 'Edit to-do';

  @override
  String get deleteTodo => 'Delete to-do';

  @override
  String get deleteTodoConfirm => 'Delete this to-do? This can\'t be undone.';

  @override
  String get todoToggleFailed => 'Couldn\'t save the change, reverted';

  @override
  String todoDoneSection(int count) {
    return 'Finished ($count)';
  }

  @override
  String get clearCompletedTodos => 'Clear finished';

  @override
  String get clearCompletedTodosConfirm =>
      'Clear all finished to-dos? This can\'t be undone.';

  @override
  String get emptyTodos => 'No to-dos yet';

  @override
  String get emptySearchResult => 'No matching notes';

  @override
  String last_updated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Last updated: $dateString';
  }

  @override
  String get settingsDataManagement => 'Data & Sync';

  @override
  String get dataTitle => 'Data & Sync';

  @override
  String get dataGroupExport => 'Export';

  @override
  String get dataExport => 'Export data';

  @override
  String get dataExportDesc =>
      'Save all notes, folders and to-dos into one JSON snapshot file';

  @override
  String get dataGroupImport => 'Import';

  @override
  String get dataImport => 'Import data';

  @override
  String get dataImportDesc =>
      'Merge a JSON snapshot in; the newer copy wins for each record';

  @override
  String get dataGroupWebDav => 'WebDAV Sync';

  @override
  String get dataWebDavServer => 'Server';

  @override
  String get dataWebDavNotConfigured => 'Not set';

  @override
  String get dataSyncNow => 'Sync now';

  @override
  String get dataSyncAutoOnStart => 'Sync when app starts';

  @override
  String get dataSyncAutoOnStartDesc => 'Syncs once every time the app starts';

  @override
  String get dataLastSyncNever => 'Never synced';

  @override
  String dataLastSyncAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Last synced: $dateString';
  }

  @override
  String dataExportDone(int count) {
    return 'Exported $count records';
  }

  @override
  String dataImportDone(int inserted, int updated) {
    return 'Imported: $inserted added, $updated updated';
  }

  @override
  String dataSyncDone(int inserted, int updated) {
    return 'Synced: $inserted added, $updated updated';
  }

  @override
  String get dataSyncNoChange => 'Both sides are already in sync';

  @override
  String dataSkippedSuffix(int skipped) {
    return ', $skipped skipped';
  }

  @override
  String get dataErrorNetwork =>
      'Can\'t reach the server — check your connection';

  @override
  String get dataErrorTimeout => 'Connection timed out. Try again later';

  @override
  String get dataErrorAuth => 'Wrong username or password';

  @override
  String get dataErrorServer => 'The server rejected the request';

  @override
  String get dataErrorInvalidFile =>
      'This file isn\'t a snapshot exported by this app';

  @override
  String get dataErrorNotConfigured => 'No WebDAV server configured yet';

  @override
  String get dataErrorUnknown => 'Something went wrong. Try again';

  @override
  String get webDavTitle => 'WebDAV';

  @override
  String get webDavSave => 'Save';

  @override
  String get webDavSaved => 'Saved';

  @override
  String get webDavGroupAccount => 'Server';

  @override
  String get webDavUrl => 'Server address';

  @override
  String get webDavUsername => 'Username';

  @override
  String get webDavPassword => 'Password';

  @override
  String get webDavPasswordToggle => 'Show password';

  @override
  String get webDavRemoteFile => 'Remote file name';

  @override
  String get webDavGroupAction => 'Connection';

  @override
  String get webDavTest => 'Test connection';

  @override
  String get webDavTestOk => 'Connected';

  @override
  String get webDavTestFailed => 'Couldn\'t connect';

  @override
  String get webDavNote =>
      'Data is stored on the server as a single JSON snapshot. Syncing merges both ways and never deletes data from either side.';
}
