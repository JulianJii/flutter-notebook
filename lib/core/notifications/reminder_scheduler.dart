import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 待办提醒的唯一平台出入口：把「某个时刻」注册 / 注销成一条系统通知。
///
/// ⛔ 不复用 `core/notifications/notification_service.dart`：那是推送（FCM）的
/// 抽象，没有定时能力，且实现是 Debug 空壳。本类是**本地定时通知**，只服务待办。
///
/// ⛔ 不做「重复提醒」/「重启后恢复」：前者待办稿没有入口，后者要原生 boot
/// receiver + 重排逻辑，收益 < 复杂度（重启后提醒丢失是可接受的当前行为）。
///
/// ⚠️ **失败一律抛出**（平台异常 / `ArgumentError`），不在这里吞也不映射 `Failure`
/// —— 那是调用方（presentation）的活，它才有 l10n 与 Snackbar。
class ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// 幂等初始化：时区库 + 插件。**每次 [schedule] 前都会自己调一次**，所以调用方
  /// 不必记得先 init（冷启动到用户点「设置提醒」之间可能隔很久）。
  Future<void> init() async {
    if (_ready) return;
    // `tz.local` 自己读不到系统时区（Dart 拿不到），只能由 flutter_timezone 问原生。
    tz_data.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        // 桌面端（开发时最常撞的两个）：插件对每个平台都强制校验 settings，
        // 少给一个就在 init() 直接抛 ArgumentError。
        macOS: DarwinInitializationSettings(),
        windows: WindowsInitializationSettings(
          appName: 'MyNote',
          // 跟 android applicationId 对齐；Windows 靠它把 toast 归到本应用
          appUserModelId: 'com.wode.mynote',
          // ⚠️ toast 点击回调的标识，**定死**。换掉 = 已弹出的通知点不动。
          guid: '8f3c1a52-6d47-4b9e-a1c8-5e2f7d306b94',
        ),
      ),
    );
    _ready = true;
  }

  /// 请求通知权限。已授权 / 平台不拦（桌面）返回 true。
  ///
  /// ⚠️ Android 6.0~12 没有运行时通知权限，插件返回 null → 按「已授权」处理，
  /// 免得老机型上直接把功能判死。
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? true;
    }
    // ⛔ 不给 Windows 请求权限：toast 开关在系统「通知」设置里，插件没提供接口，
    // 这里只能当已授权。代价是「没开通知 → 到点静默不弹」
    // （同见 `docs/FEATURES.md`「已知限制」）。
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) {
      return await macos.requestPermissions(alert: true, sound: true) ?? true;
    }
    return true;
  }

  /// 注册一条定时通知。[at] 必须是**将来**的时刻（插件对过去时间抛
  /// `ArgumentError`），判断在调用方做（它要拿这个结果去提示用户）。
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(_channelId, _channelName),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// 取消一条定时通知。通知本来就不存在时插件是静默的，不抛。
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  /// 通知渠道。⚠️ 渠道名**故意不本地化**：它显示在系统设置里，且 Android 上渠道
  /// 一旦创建就改不了名字 —— 随语言变只会留下两个名字不一致的僵尸渠道。
  static const String _channelId = 'todo_reminders';
  static const String _channelName = 'Todo reminders';
}

/// 通知 id：由待办 id 派生，⛔ 不另存一列。
///
/// ponytail: `hashCode` 掩码到 31 位（插件要求 id 落在 32 位整数内）。碰撞会让两条
/// 待办互相顶掉提醒，百级数据下概率 ≈ 2e-6，可接受；真撞了再给 `todos` 加
/// `reminder_id` 自增列，届时只需改这一行。
int reminderNotificationId(String todoId) => todoId.hashCode & 0x7FFFFFFF;

/// 全局单例：插件实例本身是进程级的，重复 new 会重复注册渠道；用 `Provider` 让
/// 测试能整体替换成 mock。
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return ReminderScheduler();
});
