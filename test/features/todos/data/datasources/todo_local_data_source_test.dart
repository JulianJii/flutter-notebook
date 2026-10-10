import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';

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

  test('watchAll 未完成置顶，同组内 createdAt DESC', () async {
    final older = await source.insert(_todo('t1'));
    await source.insert(_todo('t2', createdAt: _t2));
    await source.update(older.copyWith(isDone: true));
    expect((await source.watchAll().first).map((t) => t.id), ['t2', 't1']);
  });

  test('deleteCompleted 只清已完成；无已完成时返回 0 且不抛', () async {
    final older = await source.insert(_todo('t1'));
    await source.insert(_todo('t2', createdAt: _t2));
    await source.update(older.copyWith(isDone: true));

    expect(await source.deleteCompleted(), 1);
    expect((await source.watchAll().first).map((t) => t.id), ['t2']);
    expect(await source.deleteCompleted(), 0);
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

  test('reminderAt 落库往返：写入可读回，显式置 null 即清除', () async {
    final todo = await source.insert(_todo('t1'));
    expect(todo.reminderAt, isNull);

    final at = DateTime.fromMillisecondsSinceEpoch(300 * 1000);
    final withReminder = await source.update(todo.copyWith(reminderAt: at));
    expect(withReminder.reminderAt, at);
    expect((await source.watchAll().first).single.reminderAt, at);

    final cleared = await source.update(
      withReminder.copyWith(reminderAt: null),
    );
    expect(cleared.reminderAt, isNull);
    expect((await source.watchAll().first).single.reminderAt, isNull);
  });

  test('update 未命中 -> CacheException', () async {
    await expectLater(
      source.update(_todo('nope')),
      throwsA(isA<CacheException>()),
    );
  });

  test('delete 是软删除：列表消失、行进回收站；再删一次不报错', () async {
    await source.insert(_todo('t1'));
    await source.delete('t1');

    expect(await source.watchAll().first, isEmpty, reason: '列表只看未删除的');
    expect(
      (await source.watchTrashed().first).map((t) => t.id),
      <String>['t1'],
      reason: '软删除 = 行还在。硬删除不留痕，跨设备传不过去',
    );
    // 重复软删**不再抛**：行确实还在（只是标记），这是幂等操作。
    // 抛错的是 purge —— 它才是物理删。
    await source.delete('t1');
    await expectLater(source.delete('nope'), throwsA(isA<CacheException>()));
  });

  test('restore 出回收站并刷 updated_at', () async {
    await source.insert(_todo('t1'));
    final before = (await source.watchAll().first).single.updatedAt;

    await source.delete('t1');
    await source.restore('t1');

    final after = (await source.watchAll().first).single;
    expect(after.deletedAt, isNull);
    expect(await source.watchTrashed().first, isEmpty);
    expect(
      after.updatedAt.isAfter(before),
      isTrue,
      reason: '恢复必须刷 updated_at —— 合并键是 max(updatedAt, deletedAt)，'
          '不刷则 version 退回旧值、同步时恢复被远端的删除态压回去',
    );
  });

  test('purge 是物理删（回收站的「永久删除」）', () async {
    await source.insert(_todo('t1'));
    await source.delete('t1');

    await source.purge('t1');

    expect(await source.watchTrashed().first, isEmpty);
    await expectLater(source.purge('t1'), throwsA(isA<CacheException>()));
  });
}
