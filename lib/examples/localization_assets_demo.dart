import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/localization/language_selector_widget.dart';
import 'package:init/core/localization/localized_asset_service.dart';
import 'package:init/core/providers/localization_providers.dart';
import 'package:init/l10n/l10n.dart';
import 'package:intl/intl.dart';

/// 展示本地化功能的演示页面
/// 包含语言专属资源演示
class LocalizationAssetsDemo extends ConsumerWidget {
  const LocalizationAssetsDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(persistentLocaleProvider);

    // 创建 AppLocalizations 实例用于格式化
    final l10n = AppLocalizations(locale);

    // 用于格式化示例的当前日期
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('localization_assets_demo')),
        actions: const [
          // 应用栏中的语言弹出菜单
          LanguagePopupMenuButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前语言环境信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('current_language'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${context.tr('language_code')}: ${locale.languageCode}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('language_name')}: ${getLanguageName(locale.languageCode)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 日期和数字格式化示例
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('formatting_examples'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${context.tr('date_full')}: ${DateFormat.yMMMMEEEEd(locale.toString()).format(now)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('date_short')}: ${DateFormat.yMd(locale.toString()).format(now)}',
                    ),
                    const SizedBox(height: 4),
                    Text('${context.tr('time')}: ${l10n.formatTime(now)}'),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('currency')}: ${l10n.formatCurrency(1234.56)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.tr('percent')}: ${NumberFormat.percentPattern(locale.toString()).format(0.1234)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 本地化资源示例
            Text(
              context.tr('localized_assets'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // 展示关于语言专属资源的说明
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('localized_assets_explanation'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 本地化资源示例
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('image_example'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Column(
                        children: [
                          // 这里会展示一张本地化的欢迎图片
                          const LocalizedImage(
                            imageName: 'welcome.png',
                            width: 240,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('welcome_image_caption'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 通用（非本地化）图片示例
                    Text(
                      context.tr('common_image_example'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Column(
                        children: [
                          // 这里会展示一张通用图片（不区分语言）
                          const LocalizedImage(
                            imageName: 'logo.png',
                            useCommonPath: true,
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('common_image_caption'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据语言代码获取语言名称的辅助方法
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }
}
