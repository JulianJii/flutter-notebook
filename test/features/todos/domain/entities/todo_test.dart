import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';

void main() {
  test('copyWith 切换 isDone', () {
    final t = Todo(
      id: 't1',
      title: '买牛奶',
      createdAt: DateTime(2026, 10, 3),
      updatedAt: DateTime(2026, 10, 3),
    );
    expect(t.isDone, isFalse);
    expect(t.copyWith(isDone: true).isDone, isTrue);
    expect(t.copyWith(isDone: true).copyWith(isDone: false), t);
  });

  test('copyWith(reminderAt: null) 真的清掉提醒（不是「保持原值」）', () {
    final at = DateTime(2026, 10, 8, 9, 30);
    final withReminder = Todo(
      id: 't1',
      title: '买牛奶',
      createdAt: DateTime(2026, 10, 3),
      updatedAt: DateTime(2026, 10, 3),
      reminderAt: at,
    );

    expect(withReminder.copyWith(reminderAt: at).reminderAt, at);
    expect(withReminder.copyWith(reminderAt: null).reminderAt, isNull);
    // 不传 = 不动它（`?? this.reminderAt` 管不到的「显式置空」才是哨兵的活）。
    expect(withReminder.copyWith(isDone: true).reminderAt, at);
  });
}
