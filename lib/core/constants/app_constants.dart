class AppConstants {
  // 应用常量
  static const String appName = 'MyNote';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.wode.mynote';
  static const String iOSAppId = '123456789';
  static const String appcastUrl = 'https://your-appcast-url.com/appcast.xml';

  // GitHub：应用发版在 Release 上，版本检查读它的 latest。
  // ⚠️ 改仓库要改这里，不要散落到调用点。
  static const String githubOwner = 'JulianJii';
  static const String githubRepo = 'flutter-notebook';
  static const String githubRepoUrl =
      'https://github.com/$githubOwner/$githubRepo';
  static const String githubLatestReleaseApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';
  // 开源许可（关于页展示，与仓库 LICENSE 保持一致）
  static const String licenseName = 'MIT';

  // 超时时长
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Hive box names
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Accessibility
  static const Duration accessibilityTooltipDuration = Duration(seconds: 5);
  static const double accessibilityTouchTargetMinSize = 48.0;
}
