import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/background/background_task_service.dart';

/// 演示使用 `workmanager` 插件调度可延迟的后台工作：一个一次性任务和一个周期性任务，
/// 两者即使在应用完全关闭后也会继续运行。
///
/// 注意：这仅在 Android/iOS 上运行（WorkManager / BGTaskScheduler 是移动操作系统调度器）；
/// 在桌面/Web 上无法演示，其中 [BackgroundTaskService.initialize] 仍然可以安全调用，
/// 但调度的任务永远不会被平台触发。
class BackgroundTasksExampleScreen extends ConsumerStatefulWidget {
  const BackgroundTasksExampleScreen({super.key});

  static const _oneOffTaskName = 'template-one-off-task';
  static const _periodicTaskName = 'template-periodic-task';

  @override
  ConsumerState<BackgroundTasksExampleScreen> createState() =>
      _BackgroundTasksExampleScreenState();
}

class _BackgroundTasksExampleScreenState
    extends ConsumerState<BackgroundTasksExampleScreen> {
  String? _lastRun;
  bool _initialized = false;
  String? _status;

  Future<void> _refreshLastRun() async {
    final marker = await ref
        .read(backgroundTaskServiceProvider)
        .readLastRunMarker();
    if (mounted) setState(() => _lastRun = marker);
  }

  Future<void> _initialize() async {
    await ref.read(backgroundTaskServiceProvider).initialize();
    setState(() {
      _initialized = true;
      _status = 'Initialized';
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(backgroundTaskServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Background tasks (WorkManager)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'The OS decides exactly when a task runs (subject to battery, '
            'network and OS-defined minimum intervals), so results may take '
            'a while to appear - check back or tap "Check last run".',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _initialize,
            icon: const Icon(Icons.power_settings_new),
            label: Text(_initialized ? 'Re-initialize' : 'Initialize'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () async {
                  await service.registerOneOffTask(
                    uniqueName: BackgroundTasksExampleScreen._oneOffTaskName,
                    taskName: BackgroundTasksExampleScreen._oneOffTaskName,
                    initialDelay: const Duration(seconds: 5),
                  );
                  setState(() => _status = 'One-off task scheduled (~5s)');
                },
                child: const Text('Schedule one-off task'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await service.registerPeriodicTask(
                    uniqueName: BackgroundTasksExampleScreen._periodicTaskName,
                    taskName: BackgroundTasksExampleScreen._periodicTaskName,
                  );
                  setState(
                    () => _status =
                        'Periodic task scheduled (every 15 min, OS-clamped)',
                  );
                },
                child: const Text('Schedule periodic task'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await service.cancelAll();
                  setState(() => _status = 'All tasks cancelled');
                },
                child: const Text('Cancel all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_status != null) Text(_status!),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  _lastRun == null
                      ? 'No recorded run yet'
                      : 'Last run: $_lastRun',
                ),
              ),
              TextButton(
                onPressed: _refreshLastRun,
                child: const Text('Check last run'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
