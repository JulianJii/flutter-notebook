class AppConstants {
  // API 常量
  static const String apiBaseUrl = 'https://api.yourdomain.com';

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

  // 路由常量
  //
  // ⚠️ 笔记 App 在用的路由唯一 Source of Truth 是 `core/router/app_routes.dart`，
  // ⛔ 不再往这里加路由字符串。
  //
  // 以下只是 `lib/examples/` 内部跳转用的路径字面量，均未挂进 GoRouter。
  //
  // 已删（零外部引用）：
  //   `initialRoute` `homeRoute` `localizationDemoRoute` `examplesHubRoute`
  //   `settingsRoute` `languageSettingsRoute` `localizationAssetsDemoRoute`
  //   `loginRoute` `registerRoute` `chatRoute` `surveyRoute`
  //   `postsRoute` `postDetailRoute` `biometricDemoRoute`
  //     —— 分别随 `lib/features/auth/`、`lib/features/home/`、
  //        `lib/features/posts/` 与 `lib/core/auth/` 一并删除。
  // 已删：`localizationDemoScreenRoute` `languageSelectorDemoRoute`
  // `webSocketDemoRoute` `webhookDemoRoute` `graphqlDemoRoute` `grpcDemoRoute`
  // `backgroundTasksDemoRoute` `fileTransferDemoRoute` —— 随 `lib/examples/`
  // 一并删除（零外部引用）。

  // Hive box names
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Accessibility
  static const Duration accessibilityTooltipDuration = Duration(seconds: 5);
  static const double accessibilityTouchTargetMinSize = 48.0;
}
