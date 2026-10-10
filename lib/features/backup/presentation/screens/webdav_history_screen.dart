import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/backup/domain/entities/backup_version_entry.dart';
import 'package:mynote/features/backup/presentation/providers/backup_controller.dart';
import 'package:mynote/features/backup/presentation/widgets/backup_feedback.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// WebDAV 历史版本（`/settings/webdav/history`）。
///
/// 与设置 / 主题页同形态：root 层二级页，整屏盖住 Shell，不渲染 `AppBottomNav`。
///
/// **列表是手动拉的**（进页面 `initState` 一次），不 watch 流 —— 远端数据没有推送
/// 机制，「变化」只发生在本 App 自己同步之后，而同步完用户会自己回来点。
/// 恢复后重新拉一次即可。
///
/// ⚠️ **动作叫「找回内容」而不是「回滚」**：合并是并集语义，墓碑比任何历史版本都
/// 新，所以当时删掉的东西不会回来。确认框里必须说清这件事，否则用户会以为这是
/// undo，误判自己的数据状态。
class WebDavHistoryScreen extends ConsumerStatefulWidget {
  const WebDavHistoryScreen({super.key});

  @override
  ConsumerState<WebDavHistoryScreen> createState() => _WebDavHistoryScreenState();
}

class _WebDavHistoryScreenState extends ConsumerState<WebDavHistoryScreen> {
  late Future<Either<Failure, List<BackupVersionEntry>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Either<Failure, List<BackupVersionEntry>>> _load() {
    return ref.read(backupControllerProvider.notifier).loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                    : context.go(AppRoutes.webDav),
              ),
              centerTitle: Text(
                l10n.webDavHistory,
                style: context.textStyles.topBarTitle,
              ),
              showDivider: false,
            ),
            Expanded(
              child: FutureBuilder<Either<Failure, List<BackupVersionEntry>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data;
                  // 读列表失败：留白。与回收站屏同一约定（错误不渲染成错误页）。
                  // ⚠️ 本页**没有** refresh 入口 —— 重新进入本页会重新拉，用户有路可走。
                  if (data == null) return const SizedBox.shrink();
                  return data.fold(
                    (_) => const SizedBox.shrink(),
                    (entries) => entries.isEmpty ? _empty(l10n) : _list(entries),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
        child: Text(
          l10n.webDavHistoryEmpty,
          textAlign: TextAlign.center,
          style: context.textStyles.subtitle.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _list(List<BackupVersionEntry> entries) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH,
        vertical: AppSpacing.sm,
      ),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) =>
          _HistoryRow(entry: entries[index], onRestore: () => _confirmRestore(entries[index])),
    );
  }

  /// 二次确认 → 合并回本地。
  ///
  /// ⚠️ 确认文案里**必须**说明「删掉的不会回来」（`webDavHistoryRestoreConfirm`）——
  /// 这不是免责声明，是这个功能的语义边界。不说，用户会以为在 undo，事后才发现
  /// 回收站里的东西仍然不在。
  Future<void> _confirmRestore(BackupVersionEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.webDavHistoryRestoreConfirm(entry.at)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.webDavHistoryRestore),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(backupControllerProvider.notifier)
        .restoreVersion(entry);
    if (!mounted) return;

    result.fold(
      (failure) => showFailureSnack(context, failure, isImport: true),
      (merged) {
        showFeedbackSnack(
          context,
          merged.changed == 0
              ? l10n.dataSyncNoChange
              : l10n.webDavHistoryRestored(merged.inserted, merged.updated),
          ok: true,
        );
        // 恢复只改本地库，历史列表不变；但用户接着会想再看看状态，重新拉一次。
        setState(() => _future = _load());
      },
    );
  }
}

/// 一行：一个时间 + 条数 + 「找回内容」。
///
/// 页面内私有组件（语义只属于历史版本，不上提 `core/ui`）。
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.onRestore});

  final BackupVersionEntry entry;

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.rowPadH,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              l10n.webDavHistoryEntryAt(entry.at, entry.count),
              style: context.textStyles.rowTitle.copyWith(
                color: context.colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.chipGap),
          TextButton(
            onPressed: onRestore,
            child: Text(
              l10n.webDavHistoryRestore,
              style: context.textStyles.value.copyWith(
                color: context.colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}