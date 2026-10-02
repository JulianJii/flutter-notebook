import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/constants/app_constants.dart';
import 'package:init/core/providers/localization_providers.dart';
import 'package:init/core/router/locale_aware_router.dart';
import 'package:init/examples/localization_assets_demo.dart';
import 'package:init/features/auth/presentation/screens/login_screen.dart';
import 'package:init/features/auth/presentation/screens/register_screen.dart';
import 'package:init/features/home/presentation/screens/home_screen.dart';
import 'package:init/features/auth/presentation/providers/auth_provider.dart';
import 'package:init/features/settings/presentation/screens/settings_screen.dart';
import 'package:init/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:init/features/chat/presentation/screens/chat_screen.dart';
import 'package:init/features/survey/presentation/screens/survey_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  // 监听语言环境变化 - 语言环境改变时重建路由器
  ref.watch(persistentLocaleProvider);

  // 创建带语言环境感知的路由器
  return GoRouter(
    initialLocation: AppConstants.initialRoute,
    debugLogDiagnostics: true,
    // 添加语言环境感知的观察者
    observers: [ref.read(localizationRouterObserverProvider)],
    redirect: (context, state) {
      // 获取认证状态
      final isLoggedIn = authState.isAuthenticated;

      // 检查用户是否正前往登录页面
      final isGoingToLogin = state.matchedLocation == AppConstants.loginRoute;

      // 检查用户是否正前往注册页面
      final isGoingToRegister =
          state.matchedLocation == AppConstants.registerRoute;

      // 若未登录且不是前往登录或注册页面，则重定向到登录
      if (!isLoggedIn && !isGoingToLogin && !isGoingToRegister) {
        return AppConstants.loginRoute;
      }

      // 若已登录且正前往登录或注册页面，则重定向到首页
      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
        return AppConstants.homeRoute;
      }

      // 无需重定向
      return null;
    },
    routes: [
      // 首页路由
      GoRoute(
        path: AppConstants.homeRoute,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // 登录路由
      GoRoute(
        path: AppConstants.loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 注册路由
      GoRoute(
        path: AppConstants.registerRoute,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 设置路由
      GoRoute(
        path: AppConstants.settingsRoute,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // 语言设置路由
      GoRoute(
        path: AppConstants.languageSettingsRoute,
        name: 'language_settings',
        builder: (context, state) => const LanguageSettingsScreen(),
      ),

      // 本地化资源演示路由
      GoRoute(
        path: AppConstants.localizationAssetsDemoRoute,
        name: 'localization_assets_demo',
        builder: (context, state) => const LocalizationAssetsDemo(),
      ),

      // 聊天路由
      GoRoute(
        path: AppConstants.chatRoute,
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),

      // 调查路由
      GoRoute(
        path: AppConstants.surveyRoute,
        name: 'survey',
        builder: (context, state) => const SurveyScreen(),
      ),

      // 初始路由 - 根据认证状态重定向
      GoRoute(
        path: AppConstants.initialRoute,
        name: 'initial',
        redirect: (context, state) => authState.isAuthenticated
            ? AppConstants.homeRoute
            : AppConstants.loginRoute,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Page ${state.uri.path} not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.homeRoute),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
