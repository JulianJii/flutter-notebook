import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/backup/domain/entities/backup_import_result.dart';
import 'package:mynote/features/backup/presentation/providers/backup_controller.dart';
import 'package:mynote/features/backup/presentation/providers/webdav_config_provider.dart';
import 'package:mynote/features/backup/presentation/widgets/backup_feedback.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 数据与同步页（`/settings/data`）：导出 / 导入 / WebDAV 三个入口。
///
/// 与设置、主题页同形态：root 层二级页，整屏盖住 Shell，不渲染 `AppBottomNav`。
/// 全部由 `AppTopBar` / `AppSectionHeader` / `AppCard` / `AppListTile` /
/// `AppSwitchRow` 拼装，不造新视觉。
class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final config = ref.watch(webDavConfigProvider);
    final running = ref.watch(backupControllerProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
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
              centerTitle: Text(
                l10n.dataTitle,
                style: context.textStyles.topBarTitle,
              ),
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  AppSettingsGroup(
                    title: l10n.dataGroupExport,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('data_export'),
                        title: l10n.dataExport,
                        subtitle: l10n.dataExportDesc,
                        titleWeight: AppSwitchRow.titleWeight,
                        onTap: running == null
                            ? () => _export(context, ref)
                            : null,
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    title: l10n.dataGroupImport,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('data_import'),
                        title: l10n.dataImport,
                        subtitle: l10n.dataImportDesc,
                        titleWeight: AppSwitchRow.titleWeight,
                        onTap: running == null
                            ? () => _import(context, ref)
                            : null,
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    title: l10n.lanTitle,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('data_lan_sync'),
                        title: l10n.lanTitle,
                        subtitle: l10n.lanAllowAccessDesc,
                        trailing: _chevron(context),
                        onTap: () => context.push(AppRoutes.lanSync),
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    title: l10n.dataGroupWebDav,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('data_webdav_server'),
                        title: l10n.dataWebDavServer,
                        trailingValue: config.isConfigured
                            ? config.url
                            : l10n.dataWebDavNotConfigured,
                        trailing: _chevron(context),
                        onTap: () => context.push(AppRoutes.webDav),
                      ),
                      AppListTile(
                        key: const Key('data_sync_now'),
                        title: l10n.dataSyncNow,
                        trailing: _trailing(context, running, BackupOperation.sync),
                        dividerBefore: true,
                        onTap: running == null ? () => _sync(context, ref) : null,
                      ),
                      AppSwitchRow(
                        key: const Key('data_auto_sync'),
                        title: l10n.dataSyncAutoOnStart,
                        subtitle: l10n.dataSyncAutoOnStartDesc,
                        value: config.autoSyncOnStart,
                        dividerBefore: true,
                        onChanged: (value) => ref
                            .read(webDavConfigProvider.notifier)
                            .setAutoSyncOnStart(value),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.rowPadH,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          config.lastSyncAt == null
                              ? l10n.dataLastSyncNever
                              : l10n.dataLastSyncAt(config.lastSyncAt!),
                          style: context.textStyles.meta.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(backupControllerProvider.notifier).export();
    if (!context.mounted) return;
    result.fold(
      (failure) => showFailureSnack(context, failure, isImport: false),
      (count) =>
          showFeedbackSnack(context, l10n.dataExportDone(count), ok: true),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(backupControllerProvider.notifier).import();
    if (!context.mounted) return;
    result.fold(
      (failure) => showFailureSnack(context, failure, isImport: true),
      // null = 用户在文件选择器里取消 —— 什么都不该弹。
      (imported) {
        if (imported != null) {
          showFeedbackSnack(context, _resultText(l10n, imported), ok: true);
        }
      },
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final result = await ref.read(backupControllerProvider.notifier).sync();
    if (!context.mounted) return;
    result.fold(
      (failure) => showFailureSnack(context, failure, isImport: false),
      (synced) => showFeedbackSnack(
        context,
        synced.changed == 0
            ? l10n.dataSyncNoChange
            : l10n.dataSyncDone(synced.inserted, synced.updated),
        ok: true,
      ),
    );
  }

  /// 忙态：该行正在跑就转圈，其余情况给 chevron。
  Widget _trailing(
    BuildContext context,
    BackupOperation? running,
    BackupOperation operation,
  ) {
    if (running == operation) {
      return SizedBox(
        width: _kRowTrailingIconSize,
        height: _kRowTrailingIconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.textSecondary,
        ),
      );
    }
    return _chevron(context);
  }

  String _resultText(AppLocalizations l10n, BackupImportResult result) {
    final base = l10n.dataImportDone(result.inserted, result.updated);
    return result.skipped == 0
        ? base
        : '$base${l10n.dataSkippedSuffix(result.skipped)}';
  }
}

/// 行尾 chevron。`UI-IMPLEMENTATION-SPEC.md` §2.5：20dp。
AppIcon _chevron(BuildContext context) => AppIcon(
  icon: AppIcons.chevronRight,
  size: _kRowTrailingIconSize,
  color: context.colors.textSecondary,
);

const double _kRowTrailingIconSize = 20;
