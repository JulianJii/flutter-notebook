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
  String get more => '更多';

  @override
  String get folders => '文件夹';

  @override
  String get createFolder => '新建文件夹';

  @override
  String get folderName => '文件夹名称';

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
  String get settingsGroupCloud => '云服务';

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
  String last_updated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '最后更新：$dateString';
  }
}
