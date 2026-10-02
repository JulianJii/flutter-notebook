import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// 后台隔离区记录任务最后运行时间的键，
/// 以便前台 UI（无法直接观察后台隔离区）可以轮询任务执行的证据。
const String lastBackgroundTaskRunKey = 'background_task_last_run';

/// WorkManager 在单独的后台隔离区中启动的入口点，用于运行任务。
/// 它无法访问应用的 widget 树、provider 或调度它的隔离区的任何状态——
/// 只有你显式持久化的内容（此处通过 SharedPreferences）才能在往返中保留。
///
/// 必须是顶层或静态函数，并且必须携带此 pragma，
/// 以便 Dart 编译器不会将其从发布构建中删除
///（`lib/` 中似乎没有任何代码直接调用它——WorkManager 从原生代码调用它）。
@pragma('vm:entry-point')
void backgroundTaskCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint('BackgroundTask running: $taskName, input: $inputData');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      lastBackgroundTaskRunKey,
      '$taskName @ ${DateTime.now().toIso8601String()}',
    );
    // 返回 true 表示成功；如果你返回 false 或抛出异常，WorkManager 会重试任务。
    return Future.value(true);
  });
}

/// 对 `workmanager` 插件的轻量封装，用于调度可延迟的、
/// 有保证的后台工作（同步、清理、定期刷新……），即使应用关闭也应继续运行——
/// 该插件在底层将其交给 Android 的 WorkManager / iOS 的 BGTaskScheduler 处理。
class BackgroundTaskService {
  bool _initialized = false;

  /// 在调度任何任务之前必须调用一次（例如在 `main()` 中）。
  Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(backgroundTaskCallbackDispatcher);
    _initialized = true;
  }

  /// 调度一个单次任务，在至少 [initialDelay] 后运行一次。
  Future<void> registerOneOffTask({
    required String uniqueName,
    required String taskName,
    Duration initialDelay = Duration.zero,
  }) {
    return Workmanager().registerOneOffTask(
      uniqueName,
      taskName,
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  /// 调度一个周期性任务。Android 强制最低频率为 15 分钟；
  /// 较短的值会被操作系统静默地调整到该最小值。
  Future<void> registerPeriodicTask({
    required String uniqueName,
    required String taskName,
    Duration frequency = const Duration(minutes: 15),
  }) {
    return Workmanager().registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> cancelByUniqueName(String uniqueName) =>
      Workmanager().cancelByUniqueName(uniqueName);

  Future<void> cancelAll() => Workmanager().cancelAll();

  /// 读取后台隔离区最后写入的标记，以便 UI 可以显示
  /// 已调度任务实际运行的证据。
  Future<String?> readLastRunMarker() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastBackgroundTaskRunKey);
  }
}

final backgroundTaskServiceProvider = Provider<BackgroundTaskService>(
  (ref) => BackgroundTaskService(),
);
