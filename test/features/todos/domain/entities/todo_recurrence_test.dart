import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/todos/domain/entities/todo_recurrence.dart';

void main() {
  group('TodoRecurrence.nextAfter', () {
    final base = DateTime(2026, 10, 4, 9, 30);

    test('daily / weekly：分别 +1 天 / +7 天，保持钟点', () {
      expect(
        TodoRecurrence.daily.nextAfter(base),
        DateTime(2026, 10, 5, 9, 30),
      );
      expect(
        TodoRecurrence.weekly.nextAfter(base),
        DateTime(2026, 10, 11, 9, 30),
      );
    });

    test('monthly：同一天号', () {
      expect(
        TodoRecurrence.monthly.nextAfter(base),
        DateTime(2026, 11, 4, 9, 30),
      );
    });

    test('monthly 跨年', () {
      expect(
        TodoRecurrence.monthly.nextAfter(DateTime(2026, 12, 15, 9)),
        DateTime(2027, 1, 15, 9),
      );
    });

    // ⛔ 这是本文件存在的理由：Dart 的 `DateTime(2026, 2, 31)` 不会抛，它静默卷成
    // 3 月 3 号 —— 「每月 31 号」会变成「每月 3 号」，用户只觉得提醒莫名提前了。
    test('monthly 遇到没有 31 号的月份：夹到当月最后一天', () {
      expect(
        TodoRecurrence.monthly.nextAfter(DateTime(2026, 1, 31, 8)),
        DateTime(2026, 2, 28, 8),
        reason: '2026 不是闰年',
      );
      expect(
        TodoRecurrence.monthly.nextAfter(DateTime(2028, 1, 31, 8)),
        DateTime(2028, 2, 29, 8),
        reason: '闰年',
      );
    });

    test('monthly 链式前进不会被卷跑（1/31 起连续 4 个月）', () {
      var at = DateTime(2026, 1, 31, 8);
      final seen = <DateTime>[];
      for (var i = 0; i < 4; i++) {
        at = TodoRecurrence.monthly.nextAfter(at);
        seen.add(at);
      }
      expect(seen, <DateTime>[
        DateTime(2026, 2, 28, 8),
        DateTime(2026, 3, 28, 8),
        DateTime(2026, 4, 28, 8),
        DateTime(2026, 5, 28, 8),
      ]);
    });

    test('none：原地不动（调用方负责不再往前滚）', () {
      expect(TodoRecurrence.none.nextAfter(base), base);
    });
  });

  group('TodoRecurrence.fromId', () {
    test('null / 未知值都降级成「不重复」', () {
      expect(TodoRecurrence.fromId(null), isNull);
      expect(
        TodoRecurrence.fromId('yearly'),
        isNull,
        reason: '认不出的字符串不该让整个列表打不开',
      );
    });

    test('正常往返', () {
      for (final r in TodoRecurrence.values) {
        expect(TodoRecurrence.fromId(r.id), r);
      }
    });
  });
}