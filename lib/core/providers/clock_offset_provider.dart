import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/core/utils/app_clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_offset_provider.g.dart';

/// 偏差在 SharedPreferences 里的 key。
const String _kClockOffsetMs = 'clock_offset_ms';

/// 启动时恢复偏差，并提供「设置并落盘」的入口。
///
/// ⚛️ **为什么要持久化**：偏差是在局域网同步那一刻算出来的。若不存盘，设备一
/// 重启就回到自己那个不准的系统时钟，而用户可能几天内不再同步 —— 偏移量白校了。
/// 存的是毫秒数（设备时钟偏差常见到分钟级，秒精度够用且数值可读）。
@Riverpod(keepAlive: true)
class ClockOffsetNotifier extends _$ClockOffsetNotifier {
  @override
  void build() {
    final saved = ref.read(localStorageServiceProvider).getInt(_kClockOffsetMs);
    if (saved != null && saved != 0) {
      AppClock.setOffset(Duration(milliseconds: saved));
    }
  }

  /// 设置偏差并落盘。局域网同步握手成功后调用。
  Future<void> set(Duration offset) async {
    AppClock.setOffset(offset);
    await ref.read(localStorageServiceProvider).setInt(
      _kClockOffsetMs,
      offset.inMilliseconds,
    );
  }

  /// 清零并落盘（不再信任对端时钟）。
  Future<void> clear() async {
    AppClock.reset();
    await ref.read(localStorageServiceProvider).setInt(_kClockOffsetMs, 0);
  }
}