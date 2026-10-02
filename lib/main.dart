import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:init/core/constants/app_constants.dart';
import 'package:init/core/providers/localization_providers.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/core/router/app_router.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/updates/update_providers.dart';
import 'package:init/l10n/app_localizations_delegate.dart';
import 'package:init/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 确保 Flutter binding 已初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // 使用 ProviderScope 运行应用以启用 Riverpod
  runApp(
    ProviderScope(
      overrides: [
        // 用该实例覆盖 shared preferences provider
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),

        // 覆盖默认语言环境 provider，改为使用持久化语言环境
        defaultLocaleProvider.overrideWith(
          (ref) => ref.watch(persistentLocaleProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// 用于管理主题模式的 Provider
// 用于管理主题模式的 Provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 provider 中监听 router
    final router = ref.watch(routerProvider);

    // 监听主题模式
    final themeMode = ref.watch(themeModeProvider);

    // 监听持久化语言环境
    final locale = ref.watch(persistentLocaleProvider);

    return UpdateChecker(
      autoPrompt: true,
      enforceCriticalUpdates: true,
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,

        // 本地化设置
        locale: locale,
        localizationsDelegates: [
          const AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
