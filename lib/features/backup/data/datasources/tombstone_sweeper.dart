import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/utils/app_clock.dart';

/// 永久删除墓碑的**本地保留期清扫**。
///
/// ⛔ **故意独立于 `BackupLocalDataSource`**：那个文件是快照合并的写回路径，它
/// 写进库的每个时间戳都**来自对端**，重打本地戳会让每条合并进来的记录都变成
/// 「刚刚编辑过」，合并静默退化成「本地全胜」（`test/core/utils/app_clock_usage_test.dart`
/// 扫源码钉住这条边界）。而清扫判据是「本机现在是什么时候」，它属于本地维护，
/// **就该**用本地时钟 —— 混进那个文件会让那条测试永远无法正确表达边界，
/// 于是以后没人敢再碰它。
///
/// ponytail: 三条 DELETE 各自只有一个调用点，没有值得抽的 DAO。
class TombstoneSweeper {
  TombstoneSweeper(this._db);

  final AppDatabase _db;

  /// 墓碑保留期。⚠️ 必须**长于任何一台设备的可能离线时长**，否则一台离线一个月的
  /// 设备重新上线时，会把对方早已清扫掉的行当成「本地独有」原样保留 ——
  /// 用户会看到自己永久删除的东西重新出现。30 天是刻意保守的取值。
  static const Duration retention = Duration(days: 30);

  /// 物理删掉墓碑早于保留期的所有行，返回条数。
  Future<int> sweep({Duration retention = retention}) => _guard(() async {
    final before = AppClock.appNow().subtract(retention);
    return (await (_db.delete(
      _db.notes,
    )..where((t) => t.purgedAt.isNotNull() & t.purgedAt.isSmallerThanValue(before)))
            .go()) +
        (await (_db.delete(
          _db.noteFolders,
        )..where((t) => t.purgedAt.isNotNull() & t.purgedAt.isSmallerThanValue(before)))
            .go()) +
        (await (_db.delete(
          _db.todos,
        )..where((t) => t.purgedAt.isNotNull() & t.purgedAt.isSmallerThanValue(before)))
            .go());
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on CacheException {
      rethrow;
    } on SqliteException catch (e) {
      throw CacheException(message: e.message);
    } on DriftWrappedException catch (e) {
      throw CacheException(message: e.message);
    } on Exception catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}