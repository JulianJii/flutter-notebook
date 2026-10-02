import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/constants/app_constants.dart';
import 'package:init/core/updates/update_service.dart';

/// 更新服务的 Provider
final updateServiceProvider = Provider<UpdateService>((ref) {
  return BasicUpdateService(
    androidPackageName: AppConstants.packageName,
    iOSAppId: AppConstants.iOSAppId,
  );
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

  /// 是否强制更新（阻止关闭关键更新）
  final bool enforceCriticalUpdates;

  /// 创建更新检查器
  const UpdateChecker({
    super.key,
    required this.child,
    this.autoPrompt = true,
    this.enforceCriticalUpdates = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<UpdateCheckResult>>(updateControllerProvider, (
      _,
      state,
    ) {
      state.whenData((result) {
        if (autoPrompt &&
            (result == UpdateCheckResult.updateAvailable ||
                result == UpdateCheckResult.criticalUpdateRequired)) {
          _showUpdateDialog(context, ref, result);
        }
      });
    });

    return child;
  }

  void _showUpdateDialog(
    BuildContext context,
    WidgetRef ref,
    UpdateCheckResult result,
  ) async {
    final updateController = ref.read(updateControllerProvider.notifier);
    final updateInfo = await updateController.getUpdateInfo();

    if (updateInfo == null || !context.mounted) return;

    final isCritical = result == UpdateCheckResult.criticalUpdateRequired;

    showDialog(
      context: context,
      barrierDismissible: !isCritical,
      builder: (context) =>
          UpdateDialog(updateInfo: updateInfo, isCritical: isCritical),
    );
  }
}

/// 显示可用更新信息的对话框
class UpdateDialog extends ConsumerWidget {
  /// 更新相关信息
  final UpdateInfo updateInfo;

  /// 该更新是否关键
  final bool isCritical;

  /// 创建更新对话框
  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.isCritical = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isCritical,
      child: AlertDialog(
        title: Text(isCritical ? 'Required Update' : 'Update Available'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCritical
                    ? 'A critical update (version ${updateInfo.latestVersion}) is required to continue using this app.'
                    : 'A new version (${updateInfo.latestVersion}) is available.',
                style: theme.textTheme.bodyLarge,
              ),
              if (updateInfo.releaseNotes != null) ...[
                const SizedBox(height: 16),
                Text('What\'s new:', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(updateInfo.releaseNotes!),
              ],
            ],
          ),
        ),
        actions: [
          if (!isCritical)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(updateControllerProvider.notifier).openUpdateUrl();
            },
            child: Text(isCritical ? 'Update Now' : 'Update'),
          ),
        ],
      ),
    );
  }
}
