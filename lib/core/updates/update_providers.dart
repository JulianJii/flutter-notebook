import 'package:material_ui/material_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mynote/core/router/app_router.dart';
import 'package:mynote/core/updates/update_service.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';

/// 更新服务的 Provider
final updateServiceProvider = Provider<UpdateService>((ref) {
  return BasicUpdateService(dio: Dio());
});

/// 当前安装的版本号（`PackageInfo.version`）。
final appVersionProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(updateServiceProvider);
  await service.init();
  return service.currentVersion;
});

/// 用于检查是否有可用更新的 Provider
final updateCheckProvider = FutureProvider.autoDispose<UpdateCheckResult>((
  ref,
) async {
  final updateService = ref.watch(updateServiceProvider);
  await updateService.init();
  return await updateService.checkForUpdates();
});

/// 更新信息的 Provider
final updateInfoProvider = FutureProvider.autoDispose<UpdateInfo?>((ref) async {
  final updateService = ref.watch(updateServiceProvider);
  return await updateService.getUpdateInfo();
});

/// 更新流程的控制器
/// 更新流程的控制器
class UpdateController extends AsyncNotifier<UpdateCheckResult> {
  @override
  Future<UpdateCheckResult> build() async {
    final updateService = ref.watch(updateServiceProvider);
    await updateService.init();
    return await updateService.checkForUpdates();
  }

  /// 检查更新
  Future<void> checkForUpdates() async {
    state = const AsyncValue.loading();

    try {
      final updateService = ref.read(updateServiceProvider);
      final result = await updateService.checkForUpdates();
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// 提示用户更新应用
  Future<bool> promptForUpdate({bool force = false}) async {
    final updateService = ref.read(updateServiceProvider);
    return await updateService.promptUpdate(force: force);
  }

  /// 打开更新 URL
  Future<bool> openUpdateUrl() async {
    final updateService = ref.read(updateServiceProvider);
    return await updateService.openUpdateUrl();
  }

  /// 获取可用更新的信息
  Future<UpdateInfo?> getUpdateInfo() async {
    final updateService = ref.read(updateServiceProvider);
    return await updateService.getUpdateInfo();
  }
}

/// 更新控制器的 Provider
final updateControllerProvider =
    AsyncNotifierProvider<UpdateController, UpdateCheckResult>(
      UpdateController.new,
    );

/// 当有可用更新时显示更新对话框的 Widget
class UpdateChecker extends ConsumerWidget {
  /// 要显示的子 Widget
  final Widget child;

  /// 是否自动提示更新
  final bool autoPrompt;

  /// 创建更新检查器
  const UpdateChecker({super.key, required this.child, this.autoPrompt = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<UpdateCheckResult>>(updateControllerProvider, (
      _,
      state,
    ) {
      state.whenData((result) {
        if (autoPrompt && result == UpdateCheckResult.updateAvailable) {
          _showUpdateDialog(ref);
        }
      });
    });

    return child;
  }

  Future<void> _showUpdateDialog(WidgetRef ref) async {
    final updateController = ref.read(updateControllerProvider.notifier);
    final updateInfo = await updateController.getUpdateInfo();

    // ⚠️ 弹窗必须用 root navigator 的 context：本 widget 位于 `MaterialApp`
    // **之上**，它自己的 context 既没有 Navigator 也没有 Localizations。
    final navContext = rootNavigatorKey.currentContext;
    if (updateInfo == null || navContext == null || !navContext.mounted) return;

    showDialog(
      context: navContext,
      builder: (context) => UpdateDialog(updateInfo: updateInfo),
    );
  }
}

/// 显示可用更新信息的对话框
class UpdateDialog extends ConsumerWidget {
  /// 更新相关信息
  final UpdateInfo updateInfo;

  /// 创建更新对话框
  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.updateDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateDialogBody(displayVersion(updateInfo.latestVersion)),
              style: theme.textTheme.bodyLarge,
            ),
            if (updateInfo.releaseNotes != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.updateDialogReleaseNotes,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(updateInfo.releaseNotes!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.updateDialogLater),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(updateControllerProvider.notifier).openUpdateUrl();
          },
          child: Text(l10n.updateDialogUpdate),
        ),
      ],
    );
  }
}
