import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 隐私政策页（`/settings/privacy-policy`）与用户协议页
/// （`/settings/user-agreement`）。
///
/// 本应用是**纯本地应用**（无账号、无后端），两页内容即以此事实为准：
/// 隐私政策声明「数据只在本机」，用户协议声明「内容归用户、数据丢失免责」。
///
/// ⛔ **不建通用「文档页」组件**：全仓只有这两页静态文档，布局就是
/// 顶栏 + 滚动文本，抽组件是负债。文案全部走 l10n（zh / en 各一份）。
class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _LegalDocument(
      title: l10n.settingsPrivacyPolicy,
      intro: l10n.privacyPolicyIntro,
      sections: <(String, String)>[
        (l10n.privacyPolicyDataTitle, l10n.privacyPolicyDataBody),
        (l10n.privacyPolicyPermissionTitle, l10n.privacyPolicyPermissionBody),
        (l10n.privacyPolicySharingTitle, l10n.privacyPolicySharingBody),
        (l10n.privacyPolicyUpdatesTitle, l10n.privacyPolicyUpdatesBody),
        (l10n.privacyPolicyContactTitle, l10n.privacyPolicyContactBody),
      ],
    );
  }
}

class UserAgreementScreen extends ConsumerWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _LegalDocument(
      title: l10n.settingsUserAgreement,
      intro: l10n.userAgreementIntro,
      sections: <(String, String)>[
        (l10n.agreementAcceptTitle, l10n.agreementAcceptBody),
        (l10n.agreementUseTitle, l10n.agreementUseBody),
        (l10n.agreementOwnershipTitle, l10n.agreementOwnershipBody),
        (l10n.agreementLiabilityTitle, l10n.agreementLiabilityBody),
        (l10n.agreementUpdatesTitle, l10n.agreementUpdatesBody),
      ],
    );
  }
}

/// 文档页骨架：居中标题顶栏 + 滚动正文（引言 + 若干「小标题 + 段落」）。
class _LegalDocument extends StatelessWidget {
  const _LegalDocument({
    required this.title,
    required this.intro,
    required this.sections,
  });

  final String title;

  final String intro;

  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                color: colors.textPrimary,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.settings),
              ),
              centerTitle: Text(title, style: context.textStyles.topBarTitle),
              showDivider: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageH,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      intro,
                      style: context.textStyles.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    for (final (heading, body) in sections) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        heading,
                        style: context.textStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        body,
                        style: context.textStyles.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.bottomSafe),
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
