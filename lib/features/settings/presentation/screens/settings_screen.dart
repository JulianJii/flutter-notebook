import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/constants/app_constants.dart';
import 'package:init/l10n/l10n.dart';

/// 包含各种应用配置选项的设置页面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(
        children: [
          // 语言设置
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.tr('language')),
            subtitle: Text(context.tr('change_language')),
            onTap: () => context.go(AppConstants.languageSettingsRoute),
          ),

          const Divider(),

          // 主题设置
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(context.tr('theme')),
            subtitle: Text(context.tr('change_theme')),
            onTap: () {
              // 主题设置（待实现）
            },
          ),

          const Divider(),

          // 其他设置...
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(context.tr('notifications')),
            subtitle: Text(context.tr('notification_settings')),
            onTap: () {
              // 通知设置（待实现）
            },
          ),

          const Divider(),

          // 本地化示例
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.tr('localization_demo')),
            subtitle: Text(context.tr('localization_demo_description')),
            onTap: () => context.go(AppConstants.localizationAssetsDemoRoute),
          ),
        ],
      ),
    );
  }
}
