import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/localization/language_selector_widget.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/localization/localization_service.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class LocalizationDemo extends ConsumerWidget {
  const LocalizationDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);
    final now = DateTime.now();
    final orderDate = DateTime.now().subtract(const Duration(days: 3));

    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat.yMMMd(currentLocale.toString());
    final timeFormat = DateFormat.Hm(currentLocale.toString());
    final currencyFormat = NumberFormat.currency(
      locale: currentLocale.toString(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
        actions: const [LanguagePopupMenuButton()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前语言信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcome_message,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Current Language: ${localeDisplayName(currentLocale)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Locale: ${currentLocale.languageCode}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(persistentLocaleProvider.notifier)
                              .resetToSystemLocale();
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('Reset to System Locale'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 基础翻译
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Translations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildTranslationItem(
                        context,
                        'app_title',
                        l10n.app_title,
                      ),
                      _buildTranslationItem(context, 'home', l10n.home),
                      _buildTranslationItem(context, 'settings', l10n.settings),
                      _buildTranslationItem(context, 'profile', l10n.profile),
                      _buildTranslationItem(
                        context,
                        'dark_mode',
                        l10n.dark_mode,
                      ),
                      _buildTranslationItem(
                        context,
                        'light_mode',
                        l10n.light_mode,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 参数替换
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parameters & Pluralization',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.greeting('John Doe'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.item_count(0),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        l10n.item_count(1),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        l10n.item_count(5),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.last_updated(now),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 格式化
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date & Currency Formatting',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildFormattingExample(
                        context,
                        'Date:',
                        dateFormat.format(now),
                      ),
                      _buildFormattingExample(
                        context,
                        'Short Date:',
                        DateFormat.yMd(currentLocale.toString()).format(now),
                      ),
                      _buildFormattingExample(
                        context,
                        'Time:',
                        timeFormat.format(now),
                      ),
                      _buildFormattingExample(
                        context,
                        'DateTime:',
                        '${dateFormat.format(now)} ${timeFormat.format(now)}',
                      ),
                      _buildFormattingExample(
                        context,
                        'Full DateTime:',
                        DateFormat(
                          'EEEE, MMMM d, yyyy HH:mm',
                          currentLocale.toString(),
                        ).format(now),
                      ),
                      _buildFormattingExample(
                        context,
                        'Currency:',
                        currencyFormat.format(1234.56),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 模拟订单详情示例
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details Example',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Order #12345',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Date:'),
                          Text(dateFormat.format(orderDate)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Product 1'),
                          Text(currencyFormat.format(59.99)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Product 2'),
                          Text(currencyFormat.format(149.99)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:'),
                          Text(currencyFormat.format(209.98)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tax:'),
                          Text(currencyFormat.format(16.80)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            currencyFormat.format(226.78),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 语言选择器
              const Card(child: LanguageSelectorWidget()),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationItem(BuildContext context, String key, String value) {
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

  Widget _buildFormattingExample(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
