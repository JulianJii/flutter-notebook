// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_title => 'Flutter Riverpod 整洁架构';

  @override
  String get welcome_message => '欢迎使用 Flutter Riverpod 整洁架构';

  @override
  String get home => '首页';

  @override
  String get settings => '设置';

  @override
  String get profile => '个人中心';

  @override
  String get dark_mode => '深色模式';

  @override
  String get light_mode => '浅色模式';

  @override
  String get system_mode => '跟随系统';

  @override
  String get language => '语言';

  @override
  String get no_data => '暂无数据';

  @override
  String get loading => '加载中...';

  @override
  String get cancel => '取消';

  @override
  String get change_language => '更改应用语言';

  @override
  String get theme => '主题';

  @override
  String get change_theme => '更改应用主题';

  @override
  String get notifications => '通知';

  @override
  String get notification_settings => '配置通知偏好设置';

  @override
  String get localization_demo => '本地化演示';

  @override
  String get localization_demo_description => '查看本地化功能';

  @override
  String get language_settings => '语言设置';

  @override
  String get select_your_language => '选择您偏好的语言';

  @override
  String get language_explanation => '所选语言将应用于整个应用';

  @override
  String get localization_assets_demo => '本地化与资源演示';

  @override
  String get current_language => '当前语言';

  @override
  String get language_code => '语言代码';

  @override
  String get language_name => '语言名称';

  @override
  String get formatting_examples => '格式化示例';

  @override
  String get date_full => '日期（完整）';

  @override
  String get date_short => '日期（简短）';

  @override
  String get time => '时间';

  @override
  String get currency => '货币';

  @override
  String get percent => '百分比';

  @override
  String get localized_assets => '本地化资源';

  @override
  String get localized_assets_explanation =>
      '此部分演示如何根据所选语言加载不同的资源。图片、音频等资源均可随语言变化。';

  @override
  String get image_example => '本地化图片示例';

  @override
  String get welcome_image_caption => '此图片会根据您所选的语言加载';

  @override
  String get common_image_example => '通用图片示例';

  @override
  String get common_image_caption => '此图片在所有语言下都相同';

  @override
  String get error_occurred => '发生错误';

  @override
  String get try_again => '重试';

  @override
  String greeting(String name) {
    return '你好，$name！';
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
      other: '$countString 个项目',
      one: '1 个项目',
      zero: '没有项目',
    );
    return '$_temp0';
  }

  @override
  String get noteSnippetPlaceholder => '无附加文案';

  @override
  String get notes => '笔记';

  @override
  String get todos => '待办';

  @override
  String get all => '全部';

  @override
  String get uncategorized => '未分类';

  @override
  String get back => '返回';

  @override
  String get share => '分享';

  @override
  String get palette => '配色';

  @override
  String get noteBackground => '背景';

  @override
  String get noteBackgroundNone => '无背景';

  @override
  String get more => '更多';

  @override
  String get folders => '文件夹';

  @override
  String get createFolder => '新建文件夹';

  @override
  String get folderName => '文件夹名称';

  @override
  String get createTodo => '新建待办';

  @override
  String get todoTitle => '待办标题';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get noteTitleHint => '标题';

  @override
  String noteMetaWordCount(int count) {
    return '$count字';
  }

  @override
  String get settingsGroupNoteStyle => '笔记样式';

  @override
  String get settingsGroupQuick => '快捷功能';

  @override
  String get settingsGroupReminder => '提醒';

  @override
  String get settingsGroupOther => '其他';

  @override
  String get settingsRecentDeleted => '最近删除';

  @override
  String get settingsQuickCapture => '速记';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsUserAgreement => '用户协议';

  @override
  String get settingsTextScale => '文字大小';

  @override
  String get settingsNoteSort => '选择排序方式';

  @override
  String get settingsNoteLayout => '笔记列表布局';

  @override
  String get settingsStrongReminder => '强提醒';

  @override
  String get settingsStrongReminderDesc => '持续响铃且静音和勿扰状态下仍有效';

  @override
  String get settingsTextScaleSmall => '小';

  @override
  String get settingsTextScaleDefault => '默认';

  @override
  String get settingsTextScaleLarge => '大';

  @override
  String get settingsTextScaleXLarge => '超大';

  @override
  String get settingsSortEditedDesc => '按编辑日期';

  @override
  String get settingsSortEditedAsc => '按编辑日期（最早）';

  @override
  String get settingsSortCreatedDesc => '按创建日期';

  @override
  String get settingsSortTitleAsc => '按标题';

  @override
  String get settingsLayoutGrid => '宫格模式';

  @override
  String get settingsLayoutList => '列表模式';

  @override
  String get themeTitle => '主题';

  @override
  String get themeSectionBrightness => '明暗模式';

  @override
  String get themeSectionPalette => '配色方案';

  @override
  String themeCurrent(String scheme, String mode) {
    return '当前：$scheme · $mode';
  }

  @override
  String get themePaletteAmber => '琥珀';

  @override
  String get themePaletteBlue => '蓝色';

  @override
  String get themePaletteGreen => '绿色';

  @override
  String get themePaletteViolet => '紫色';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsSwitchOn => '开启';

  @override
  String get settingsSwitchOff => '关闭';

  @override
  String get notesSearchHint => '搜索笔记';

  @override
  String get notesSearchClear => '清除搜索';

  @override
  String get deleteNote => '删除笔记';

  @override
  String get deleteNoteConfirm => '确定要删除这篇笔记吗？删除后可在「最近删除」中恢复。';

  @override
  String get noteDeleted => '已移到「最近删除」';

  @override
  String get trashEmpty => '没有已删除的笔记';

  @override
  String get trashRestore => '恢复';

  @override
  String get restoreDone => '已恢复';

  @override
  String get trashDeleteForever => '永久删除';

  @override
  String get trashDeleteForeverConfirm => '永久删除后无法恢复，确定要删除吗？';

  @override
  String get trashEmptyAction => '清空';

  @override
  String get trashEmptyConfirm => '确定要清空所有已删除的笔记吗？此操作无法撤销。';

  @override
  String get emptyDone => '已清空';

  @override
  String trashDeletedAt(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '删除于 $dateString';
  }

  @override
  String get privacyPolicyIntro => '「笔记」是一款纯本地应用。我们非常重视您的隐私，请在使用前仔细阅读本政策。';

  @override
  String get privacyPolicyDataTitle => '数据收集与存储';

  @override
  String get privacyPolicyDataBody =>
      '本应用不收集、不上传您的任何个人数据。全部笔记、待办与设置仅保存在您的设备本地，卸载应用或主动删除后即彻底清除。';

  @override
  String get privacyPolicyPermissionTitle => '权限使用';

  @override
  String get privacyPolicyPermissionBody =>
      '仅当您主动使用通知、分享等相应功能时，应用才会调用对应系统能力，不会在后台读取您的个人信息。';

  @override
  String get privacyPolicySharingTitle => '数据共享';

  @override
  String get privacyPolicySharingBody => '本应用没有云端服务，不存在向任何第三方共享或传输您内容的行为。';

  @override
  String get privacyPolicyUpdatesTitle => '政策更新';

  @override
  String get privacyPolicyUpdatesBody =>
      '本政策如有重大变更，将在应用内或版本更新说明中公布。变更后继续使用即表示您同意更新后的政策。';

  @override
  String get privacyPolicyContactTitle => '联系我们';

  @override
  String get privacyPolicyContactBody =>
      '如您对本政策有任何疑问或建议，请通过应用商店页面提供的联系方式与我们联系。';

  @override
  String get userAgreementIntro => '欢迎您使用「笔记」。在开始使用前，请您仔细阅读并理解本协议。';

  @override
  String get agreementAcceptTitle => '协议的接受';

  @override
  String get agreementAcceptBody =>
      '您下载、安装或使用本应用，即表示您已阅读并同意本协议的全部内容。如您不同意本协议，请立即停止使用。';

  @override
  String get agreementUseTitle => '使用规范';

  @override
  String get agreementUseBody =>
      '您承诺不利用本应用制作、存储或传播违反法律法规的内容，不得对应用进行反向工程、恶意攻击或其他影响正常使用的行为。';

  @override
  String get agreementOwnershipTitle => '内容归属';

  @override
  String get agreementOwnershipBody =>
      '您在本应用中创建的笔记、待办等内容归您本人所有。本应用的界面、图标与程序本身的权利归开发者所有。';

  @override
  String get agreementLiabilityTitle => '免责声明';

  @override
  String get agreementLiabilityBody =>
      '本应用将数据保存在您的设备本地。因设备丢失、系统故障、卸载应用或误操作导致的数据丢失，开发者不承担责任，请自行妥善备份重要内容。';

  @override
  String get agreementUpdatesTitle => '协议变更';

  @override
  String get agreementUpdatesBody => '本协议如有变更，将在应用内公布。变更后继续使用即表示您接受更新后的协议。';

  @override
  String get editTodo => '编辑待办';

  @override
  String get deleteTodo => '删除待办';

  @override
  String get deleteTodoConfirm => '确定要删除这条待办吗？此操作无法撤销。';

  @override
  String get todoToggleFailed => '勾选没有保存成功，已恢复原状态';

  @override
  String todoDoneSection(int count) {
    return '已完成 $count';
  }

  @override
  String get clearCompletedTodos => '清除已完成';

  @override
  String get clearCompletedTodosConfirm => '确定要清除全部已完成的待办吗？此操作无法撤销。';

  @override
  String get emptyTodos => '还没有待办';

  @override
  String get emptySearchResult => '没有找到相关笔记';

  @override
  String last_updated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '最后更新：$dateString';
  }
}
