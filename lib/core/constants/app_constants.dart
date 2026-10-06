class AppConstants {
  // API 常量
  static const String apiBaseUrl = 'https://api.yourdomain.com';

  // 应用常量
  static const String appName = 'Flutter Riverpod Clean Architecture';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.wode.init';
  static const String iOSAppId = '123456789';
  static const String appcastUrl = 'https://your-appcast-url.com/appcast.xml';

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
  // Examples hub & integration pattern demo routes
  static const String advancedFeaturesRoute = '/examples/advanced';
  static const String localizationDemoScreenRoute = '/examples/localization';
  static const String languageSelectorDemoRoute =
      '/examples/localization/selector';
  static const String webSocketDemoRoute = '/examples/websocket';
  static const String webhookDemoRoute = '/examples/webhook';
  static const String graphqlDemoRoute = '/examples/graphql';
  static const String grpcDemoRoute = '/examples/grpc';
  static const String backgroundTasksDemoRoute = '/examples/background-tasks';
  static const String fileTransferDemoRoute = '/examples/file-transfer';

  // Hive box names
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Accessibility
  static const Duration accessibilityTooltipDuration = Duration(seconds: 5);
  static const double accessibilityTouchTargetMinSize = 48.0;
}
