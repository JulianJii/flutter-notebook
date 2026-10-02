// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flutter Riverpod 整洁架构';

  @override
  String get welcomeMessage => '欢迎使用 Flutter Riverpod 整洁架构';

  @override
  String get home => '首页';

  @override
  String get settings => '设置';

  @override
  String get profile => '个人中心';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get systemMode => '跟随系统';

  @override
  String get language => '语言';

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
  String get logout => '退出登录';

  @override
  String get login => '登录';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get signIn => '登录';

  @override
  String get register => '注册';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get errorOccurred => '发生错误';

  @override
  String get tryAgain => '重试';

  @override
  String greeting(String name) {
    return '你好，$name！';
  }

  @override
  String itemCount(num count) {
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
  String lastUpdated(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '最后更新：$dateString';
  }
}
