import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/localization/language_selector_widget.dart';
import 'package:init/core/providers/localization_providers.dart';
import 'package:init/l10n/app_localizations_delegate.dart';
import 'package:init/l10n/l10n.dart';

/// 演示如何使用语言选择器 widget 的页面
class LanguageSelectorExample extends ConsumerWidget {
  const LanguageSelectorExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(persistentLocaleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('language')),
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
                      context.tr('welcome_message'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.trParams('greeting', {'name': 'User'}),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Current Language: ${LocalizationUtils.getLocaleName(currentLocale)} (${currentLocale.languageCode})',
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
                    _buildTranslationRow(context, 'home'),
                    _buildTranslationRow(context, 'settings'),
                    _buildTranslationRow(context, 'profile'),
                    _buildTranslationRow(context, 'dark_mode'),
                    _buildTranslationRow(context, 'light_mode'),
                    _buildTranslationRow(context, 'logout'),
                    _buildTranslationRow(context, 'login'),
                    _buildTranslationRow(context, 'no_data'),
                    _buildTranslationRow(context, 'loading'),
                    const SizedBox(height: 16),
                    Text(
                      context.trParams('greeting', {'name': 'John Doe'}),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('lastUpdated').replaceAll('{date}', context.formatDate(DateTime.now())),
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
                label: Text(context.tr('language')),
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

  Widget _buildTranslationRow(BuildContext context, String key) {
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
          Expanded(child: Text(context.tr(key))),
        ],
      ),
    );
  }
}
