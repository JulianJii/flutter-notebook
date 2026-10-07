import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mynote/core/constants/app_constants.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/core/router/app_router.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/updates/update_providers.dart';
import 'package:mynote/features/backup/presentation/providers/startup_sync_provider.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 从 provider 中监听 router
    final router = ref.watch(routerProvider);

    // 监听主题模式：`select` 只在 themeMode 变时重建，文字大小等无关偏好的改动
    // 不会把整个 MaterialApp 重建一遍。
    final themeMode = switch (ref.watch(
      settingsProvider.select((s) => s.themeMode),
    )) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    // 配色方案：`select` 只在它变时重建整个 MaterialApp（明暗由 themeMode 管，
    // 改文字大小等无关偏好不触发这里）。
    final colorScheme = ref.watch(
      settingsProvider.select((s) => s.colorScheme),
    );

    // 监听生效的语言环境：用户选择 → 系统语言 → 中文
    final locale = ref.watch(appLocaleProvider);

    // 挂载启动自动同步：`AsyncNotifier` 的 build 只在首次监听时跑一次，
    // 开关没开时它立刻返回。失败静默（用户此刻可能在任何页面）。
    ref.watch(startupSyncProvider);

    return UpdateChecker(
      autoPrompt: true,
      enforceCriticalUpdates: true,
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.light(colorScheme),
        darkTheme: AppTheme.dark(colorScheme),
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,

        // 本地化设置
        locale: locale,
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          // material_ui 是 flutter/material 的 fork，自带一套 Localizations，
          // gen-l10n 生成的列表里只有 flutter_localizations 那套，缺它会崩
          ...GlobalMaterialLocalizations.delegates,
          // Quill 工具栏/编辑器的本地化，缺它编辑页会崩
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
