import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/constants/app_constants.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/updates/update_providers.dart';
import 'package:mynote/core/updates/update_service.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// 关于（`/settings/about`）。
///
/// | 分组 | 内容 |
/// |---|---|
/// | 版本 | 当前版本号 + 「检测更新」按钮 + 检查结果 |
/// | 相关 | GitHub 仓库主页、开源许可 |
/// | — | 应用简介 |
///
/// 更新检查走 `core/updates`：`UpdateController` → `UpdateService` 比对
/// GitHub 最新 Release 的 `tag_name` 与 `PackageInfo.version`。
/// 有新版时多出一个「前往下载」按钮，跳 Release 页（`url_launcher` 交给浏览器）。
///
/// ⛔ **不自带下载逻辑**：应用没上架商店，也没有自建分发，安装包由 Release
/// 提供；各平台的安装（Android APK / Windows 包）由用户自己在浏览器完成。
/// ⛔ **不渲染 `AppBottomNav`**：root 层路由，整屏盖住 Shell。
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider);
    final check = ref.watch(updateControllerProvider);
    final updateInfo = ref.watch(updateInfoProvider).value;
    final controller = ref.read(updateControllerProvider.notifier);

    final result = check.value;
    final latestVersion = updateInfo == null
        ? null
        : displayVersion(updateInfo.latestVersion);

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                color: context.colors.textPrimary,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.settings),
              ),
              centerTitle: Text(
                l10n.settingsAbout,
                style: context.textStyles.topBarTitle,
              ),
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  AppSettingsGroup(
                    key: const Key('section_about_version'),
                    title: l10n.aboutSectionVersion,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('about_current_version'),
                        title: l10n.aboutCurrentVersion,
                        trailingValue: version.value ?? '—',
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.rowPadH),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FilledButton.icon(
                              key: const Key('about_check_update'),
                              // 检查中禁用，避免并发打 GitHub API（未认证限 60 次/小时）。
                              onPressed: check.isLoading
                                  ? null
                                  : controller.checkForUpdates,
                              icon: const Icon(Icons.system_update_alt),
                              label: Text(l10n.aboutCheckUpdate),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _resultText(l10n, check, latestVersion),
                              key: const Key('about_check_result'),
                              style: context.textStyles.meta.copyWith(
                                color: result == UpdateCheckResult.checkFailed
                                    ? Theme.of(context).colorScheme.error
                                    : context.colors.textTertiary,
                              ),
                            ),
                            if (result == UpdateCheckResult.updateAvailable)
                              TextButton(
                                key: const Key('about_open_release'),
                                onPressed: controller.openUpdateUrl,
                                child: Text(l10n.aboutOpenRelease),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    key: const Key('section_about_links'),
                    title: l10n.aboutSectionLinks,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('about_repository'),
                        title: l10n.aboutRepository,
                        trailingValue: AppConstants.githubRepo,
                        trailing: AppIcon(
                          icon: AppIcons.chevronRight,
                          size: AppSpacing.rowIconSize,
                          color: context.colors.textSecondary,
                        ),
                        onTap: () => launchUrl(
                          Uri.parse(AppConstants.githubRepoUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                      AppListTile(
                        key: const Key('about_license'),
                        title: l10n.aboutLicense,
                        trailingValue: AppConstants.licenseName,
                        dividerBefore: true,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageH,
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      l10n.aboutIntro,
                      style: context.textStyles.body.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 检查结果的文案。四种 `AsyncValue` 状态 × 三种 `UpdateCheckResult` 全覆盖。
String _resultText(
  AppLocalizations l10n,
  AsyncValue<UpdateCheckResult> check,
  String? latestVersion,
) {
  if (check.isLoading) return l10n.aboutChecking;
  if (check.hasError) return l10n.aboutCheckFailed;

  return switch (check.value) {
    UpdateCheckResult.upToDate => l10n.aboutUpToDate,
    // `latestVersion` 为空说明结果有了但 release 信息没取到，按失败处理。
    UpdateCheckResult.updateAvailable =>
      latestVersion == null
          ? l10n.aboutCheckFailed
          : l10n.aboutUpdateFound(latestVersion),
    _ => l10n.aboutCheckFailed,
  };
}
