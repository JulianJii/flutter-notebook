import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/localization/language_selector_widget.dart';
import 'package:mynote/core/localization/localized_asset_service.dart';
import 'package:mynote/core/providers/localization_providers.dart';
import 'package:mynote/core/localization/localization_service.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// 展示本地化功能的演示页面
/// 包含语言专属资源演示
class LocalizationAssetsDemo extends ConsumerWidget {
  const LocalizationAssetsDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(persistentLocaleProvider);

    final l10n = AppLocalizations.of(context);

    // 用于格式化示例的当前日期
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.localization_assets_demo),
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
                      l10n.current_language,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('${l10n.language_code}: ${locale.languageCode}'),
                    const SizedBox(height: 4),
                    Text('${l10n.language_name}: ${localeDisplayName(locale)}'),
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
                      l10n.formatting_examples,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.date_full}: ${DateFormat.yMMMMEEEEd(locale.toString()).format(now)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.date_short}: ${DateFormat.yMd(locale.toString()).format(now)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.time}: ${DateFormat.Hm(locale.toString()).format(now)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.currency}: ${NumberFormat.currency(locale: locale.toString()).format(1234.56)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.percent}: ${NumberFormat.percentPattern(locale.toString()).format(0.1234)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 本地化资源示例
            Text(
              l10n.localized_assets,
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
                      l10n.localized_assets_explanation,
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
                      l10n.image_example,
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
                            l10n.welcome_image_caption,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 通用（非本地化）图片示例
                    Text(
                      l10n.common_image_example,
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
                            l10n.common_image_caption,
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
}
