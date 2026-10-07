import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/localization/language_selector_widget.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/localization/localization_service.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';

/// 演示如何使用语言选择器 widget 的页面
class LanguageSelectorExample extends ConsumerWidget {
  const LanguageSelectorExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        actions: const [LanguagePopupMenuButton(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 介绍卡片
            Card(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcome_message,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.greeting('User'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Language: ${localeDisplayName(currentLocale)} (${currentLocale.languageCode})',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            // 翻译示例
            Card(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Translation Examples',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _buildTranslationRow(context, 'home', l10n.home),
                    _buildTranslationRow(context, 'settings', l10n.settings),
                    _buildTranslationRow(context, 'profile', l10n.profile),
                    _buildTranslationRow(context, 'dark_mode', l10n.dark_mode),
                    _buildTranslationRow(
                      context,
                      'light_mode',
                      l10n.light_mode,
                    ),
                    _buildTranslationRow(context, 'no_data', l10n.no_data),
                    _buildTranslationRow(context, 'loading', l10n.loading),
                    const SizedBox(height: 16),
                    Text(
                      l10n.greeting('John Doe'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.last_updated(DateTime.now()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // 语言选择器
            const Card(child: LanguageSelectorWidget()),

            const SizedBox(height: 24),

            // 对话框按钮
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.language),
                label: Text(l10n.language),
                onPressed: () {
                  LanguageSelectorDialog.show(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationRow(BuildContext context, String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
