import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 待办提醒的唯一平台出入口：把「某个时刻」注册 / 注销成一条系统通知。
///
/// ⛔ 不做通用「通知服务」抽象：推送（FCM）那套没有定时能力，实现也只是 Debug
/// 空壳（已随死代码清理删除）。本类是**本地定时通知**，只服务待办。
///
/// ⛔ 不做「重复提醒」：待办稿没有入口，真要做要加 recurrence 列 + RRULE 解析。
/// ✅ 做「重启后恢复」，但**不走原生 boot receiver** —— 见 [ReminderScheduler.rescheduleAll]
/// 的说明：库是唯一真相源，对账就够了，不需要在开机时抢一次平台通道。
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

  /// **全量对账**：先撤光所有已排通知，再按 [entries] 重建。
  ///
  /// 库是平台通知的唯一真相源，本方法是「把库投影到平台」这一件事的**唯一**入口。
  /// 它取代了「谁改谁去撤」的散点调用 —— 那套做法有三个必然的漏点：
  /// 设备重启后平台侧全丢（没有 boot receiver）、软删除 / 恢复各有各的调用点、
  /// 批量清除要逐条撤。漏一个 = 一条无主通知，表现为「删掉的待办到点照响」。
  ///
  /// ⚠️ 用的是 `cancelAll` 而非逐条 [cancel]：本 App 唯一的定时通知就是待办提醒
  /// （推送抽象已删除），撤光等价于撤全。将来若引入别的通知种类，这里要改成
  /// 按 id 集合求差。
  ///
  /// 单条失败不中断其余 —— 一条提醒排不上不该让其他待办集体失去提醒。整批失败也
  /// **不抛**：调用点是后台对账，没有 UI 能接住异常，抛了只会变成一条无主的日志。
  Future<void> rescheduleAll(List<ReminderEntry> entries) async {
    await init();
    await _plugin.cancelAll();
    for (final entry in entries) {
      try {
        await _plugin.zonedSchedule(
          id: entry.id,
          title: entry.title,
          body: entry.body,
          scheduledDate: tz.TZDateTime.from(entry.at, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(_channelId, _channelName),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        // 排不上就跳过这一条，其余照排。
      }
    }
  }

  /// 通知渠道。⚠️ 渠道名**故意不本地化**：它显示在系统设置里，且 Android 上渠道
  /// 一旦创建就改不了名字 —— 随语言变只会留下两个名字不一致的僵尸渠道。
  static const String _channelId = 'todo_reminders';
  static const String _channelName = 'Todo reminders';
}

/// 一条应当已排好的提醒。[ReminderScheduler.rescheduleAll] 的输入单元。
///
/// 用 record 而不是 class：四个字段全部按名访问、只在构造与解构处出现，
/// 没有第二个消费者，因此不值得一个具名类型。
typedef ReminderEntry = ({
  int id,
  String title,
  String body,
  DateTime at,
});

/// 同一串重复提醒的后续第 `index` 次（index ≥ 1）的通知 id。
///
/// 重复提醒要**一次排多场**（见 [ReminderScheduler.rescheduleAll] 的说明），所以
/// 每场得有自己的 id。做法是在基 id 上加一个**很大的步长** `kOccurrenceStride`
/// 而不是连续 +1 —— 连续加会让「第 1 次重复」和别的待办撞 id（两者的基 id 本来
/// 就可能只差 1），撞了就是互相顶掉提醒。步长远大于待办数量级（10 万）时，
/// 同一条待办的各次之间与不同待办之间都不会重叠。
int occurrenceNotificationId(String todoId, int index) =>
    reminderNotificationId(todoId) + index * kOccurrenceStride;

/// 重复提醒各次之间的 id 步长。见 [occurrenceNotificationId]。
///
/// ⚠️ 上限约束：插件要求 id 落在 32 位有符号整数内。基 id 掩码到 31 位，
/// 加上 `index * 100000` 后要仍 < 2^31，因此 [kOccurrenceHorizon] 不能太大。
const int kOccurrenceStride = 100000;

/// 一次预排多少场重复提醒。
///
/// ponytail: 本地通知**没有可靠的「响了就回调」**（`flutter_local_notifications`
/// 只有「用户点了通知」的回调，用户永远不点就永远不触发），所以「响完再排下一场」
/// 做不到 —— 用户三天不开 App，重复就在第一次之后就断了。
///
/// 折中：**一次把未来 N 场全排上**。每次冷启动的对账会把已经响过的场次往前滚，
/// 再补满 N 场。代价是系统通知队列里躺着 N 条待触发记录（N ≤ 5，量级可忽略）；
/// 收益是「设了每天提醒，用户一周不开 App 也能收到 5 次」—— 这已经覆盖了
/// 绝大多数人的实际使用。真要无限重复就得接 `workmanager` 或 `exact alarm` 的
/// 自续期，那是另一个量级的工程。
const int kOccurrenceHorizon = 5;

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
