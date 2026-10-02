import 'package:material_ui/material_ui.dart';

/// 功能开关服务的接口
abstract class FeatureFlagService {
  /// 初始化功能开关服务
  Future<void> init();

  /// 检查某个功能是否启用
  bool isFeatureEnabled(String featureKey);

  /// 获取功能开关的字符串值
  String getString(String key, {required String defaultValue});

  /// 获取功能开关的整数值
  int getInt(String key, {required int defaultValue});

  /// 获取功能开关的浮点值
  double getDouble(String key, {required double defaultValue});

  /// 获取功能开关的布尔值
  bool getBool(String key, {required bool defaultValue});

  /// 获取功能开关的颜色值
  Color getColor(String key, {required Color defaultValue});

  /// 从远程源获取最新配置
  Future<void> fetchAndActivate();

  /// 为功能开关设置默认值
  void setDefaults(Map<String, dynamic> defaults);

  /// 注册在配置更新时调用的回调
  void addListener(VoidCallback listener);

  /// 注销先前注册的回调
  void removeListener(VoidCallback listener);

  /// 清理资源
  void dispose();
}
