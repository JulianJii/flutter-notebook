import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/localization/language_selector_widget.dart';
import 'package:init/l10n/l10n.dart';

/// 语言选择设置页面
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('language_settings'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 语言选择说明
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                context.tr('select_your_language'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // 语言选择器组件
            const Expanded(child: Card(child: LanguageSelectorWidget())),

            // 语言选择说明文字
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                context.tr('language_explanation'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
