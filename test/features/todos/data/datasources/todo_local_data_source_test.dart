import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/database/app_database.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:init/features/todos/domain/entities/todo.dart';

/// drift 存 `DateTime` 用 unix **秒**，毫秒级的值会全部塌成 0
///（排序键相同，`createdAt DESC` 测不出方向）。
final DateTime _t1 = DateTime.fromMillisecondsSinceEpoch(100 * 1000);
final DateTime _t2 = DateTime.fromMillisecondsSinceEpoch(200 * 1000);

Todo _todo(String id, {String title = '买牛奶', DateTime? createdAt}) => Todo(
  id: id,
  title: title,
  createdAt: createdAt ?? _t1,
  updatedAt: createdAt ?? _t1,
);

void main() {
  late AppDatabase db;
  late TodoLocalDataSourceImpl source;

  setUp(() {
    db = AppDatabase.memory();
    source = TodoLocalDataSourceImpl(db);
  });

  tearDown(() => db.close());

  test('insert -> watchAll 回读，isDone 默认 false', () async {
    final saved = await source.insert(_todo('t1'));
    expect(saved.isDone, isFalse);

    final all = await source.watchAll().first;
    expect(all.single.title, '买牛奶');
    expect(all.single.id, 't1');
  });

  test('watchAll 按 createdAt DESC（新建在上）', () async {
    await source.insert(_todo('t1'));
    await source.insert(_todo('t2', createdAt: _t2));
    expect((await source.watchAll().first).map((t) => t.id), ['t2', 't1']);
  });

  test('update 勾选后 watchAll 反映新值，且 createdAt 不动', () async {
    final todo = await source.insert(_todo('t1'));

    // 调用方（ToggleTodoUseCase）没有时间戳参数，createdAt 传的是 now()。
    final updated = await source.update(
      todo.copyWith(isDone: true, updatedAt: _t2),
    );
    expect(updated.isDone, isTrue);
    expect(updated.createdAt, _t1, reason: '勾选不该让待办在列表里跳位');

    expect((await source.watchAll().first).single.isDone, isTrue);
  });

  test('update 未命中 -> CacheException', () async {
    await expectLater(
      source.update(_todo('nope')),
      throwsA(isA<CacheException>()),
    );
  });

  test('delete 后列表为空；再删一次 -> CacheException', () async {
    await source.insert(_todo('t1'));
    await source.delete('t1');
    expect(await source.watchAll().first, isEmpty);
    await expectLater(source.delete('t1'), throwsA(isA<CacheException>()));
  });
}
