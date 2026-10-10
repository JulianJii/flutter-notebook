import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/utils/app_clock.dart';

/// [AppClock] 的契约。
///
/// ⛔ 测试只碰纯 Dart 的 [AppClock]，不碰 provider —— 偏差的**持久化**（启动恢复、
/// 写盘）由 `ClockOffsetNotifier` 负责，那是另一回事。
void main() {
  tearDown(AppClock.reset);

  test('默认零偏移：appNow() 就是 DateTime.now()', () {
    expect(AppClock.offset, Duration.zero);
    final before = DateTime.now();
    final now = AppClock.appNow();
    final after = DateTime.now();

    // 不比较相等（调用之间真实时间在走），而是落在调用前后夹出的区间里。
    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });

  test('setOffset 后整体平移，方向正确', () {
    AppClock.setOffset(const Duration(hours: 5));
    final now = AppClock.appNow();

    expect(AppClock.offset, const Duration(hours: 5));
    expect(
      now.difference(DateTime.now()).inMinutes,
      closeTo(5 * 60, 2),
      reason: '往前拨 5 小时 —— 时钟快的设备要靠这个把时间戳拉到与对端一致',
    );
  });

  test('负偏移（对端慢）同样生效', () {
    AppClock.setOffset(const Duration(minutes: -30));
    expect(
      AppClock.appNow().difference(DateTime.now()).inMinutes,
      closeTo(-30, 2),
    );
  });

  test('reset 回到系统时钟', () {
    AppClock.setOffset(const Duration(hours: 9));
    AppClock.reset();

    expect(AppClock.offset, Duration.zero);
    expect(
      AppClock.appNow().difference(DateTime.now()).inSeconds.abs(),
      lessThan(2),
    );
  });

  test('重复设置是覆盖不是累加（同步多轮不会漂移）', () {
    AppClock.setOffset(const Duration(hours: 1));
    AppClock.setOffset(const Duration(hours: 2));

    expect(AppClock.offset, const Duration(hours: 2));
    expect(
      AppClock.appNow().difference(DateTime.now()).inMinutes,
      closeTo(120, 2),
      reason: '累加的话每同步一次就快一点，一周后差出几小时',
    );
  });
}