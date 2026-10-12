import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mynote/core/constants/app_constants.dart';
import 'package:mynote/core/fonts/font_providers.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/core/router/app_router.dart';
import 'package:mynote/core/theme/app_theme.dart';
import 'package:mynote/core/updates/update_providers.dart';
import 'package:mynote/core/window/desktop_window.dart';
import 'package:mynote/features/backup/presentation/providers/startup_sync_provider.dart';
import 'package:mynote/features/todos/presentation/providers/reminder_reconciler.dart';
import 'package:mynote/features/settings/domain/entities/app_settings.dart';
import 'package:mynote/features/settings/presentation/providers/settings_provider.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows / macOS：摘掉系统标题栏（标题栏由 DesktopWindowFrame 自绘）
  await setUpDesktopWindow();

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
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
    final router = ref.watch(routerProvider);

    // 监听主题模式：`select` 只在 themeMode 变时重建，排序 / 布局等无关偏好的改动
    // 不会把整个 MaterialApp 重建一遍。
    final themeMode = switch (ref.watch(
      settingsProvider.select((s) => s.themeMode),
    )) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    // 配色方案：`select` 只在它变时重建整个 MaterialApp（明暗由 themeMode 管，
    // 改排序 / 布局等无关偏好不触发这里）。
    final colorScheme = ref.watch(
      settingsProvider.select((s) => s.colorScheme),
    );

    // UI 字体。偏好里存的是字体 **id**（`null` = 系统默认），族名与「首次下载并
    // 注册进引擎」都在 `core/fonts` 现算 —— `AsyncValue.value` 在加载期间与失败时
    // 给 `null`，于是这一帧回落系统字体、加载完自动换过来（⛔ 不阻塞 `main()`。
    // 代价只是冷启动时一次短暂的字形切换）。
    // ⛔ 只作用于 UI 文字：每篇笔记的标题 / 正文走该篇笔记自己的 `editorFontId`。
    final uiFontId = ref.watch(settingsProvider.select((s) => s.uiFontId));
    final fontFamily = ref.watch(fontFamilyOfProvider(uiFontId)).value;

    // 监听生效的语言环境：用户选择 → 系统语言 → 中文
    final locale = ref.watch(appLocaleProvider);

    // 挂载启动自动同步：`AsyncNotifier` 的 build 只在首次监听时跑一次，
    // 开关没开时它立刻返回。失败静默（用户此刻可能在任何页面）。
    ref.watch(startupSyncProvider);

    return UpdateChecker(
      autoPrompt: true,
      child: ReminderReconciler(
        // ⚠️ 必须挂在 MaterialApp.router **之外**（与 UpdateChecker 同层）：对账要
        // 覆盖冷启动，而那时 MaterialApp 的子树还没建。
        child: MaterialApp.router(
          title: AppConstants.appName,
          theme: AppTheme.light(colorScheme, fontFamily),
          darkTheme: AppTheme.dark(colorScheme, fontFamily),
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,

          // Windows / macOS 的自绘标题栏（其余平台原样透传 child）
          builder: (BuildContext context, Widget? child) =>
              DesktopWindowFrame(child: child ?? const SizedBox.shrink()),

          locale: locale,
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            // material_ui 是 flutter/material 的 fork，自身不带 Localizations，
            // gen-l10n 生成的这套只含 flutter_localizations 的那几份，缺会崩
            ...GlobalMaterialLocalizations.delegates,
            // Quill 工具栏/编辑框文本本地化，缺会崩编辑页
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
