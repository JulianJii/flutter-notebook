import 'package:flutter_test/flutter_test.dart';
import 'package:init/features/todos/domain/entities/todo.dart';

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
}
