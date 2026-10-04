import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/database/app_database.dart';
import 'package:init/core/database/daos/todo_dao.dart';

/// [createdAt] 单位是**秒**：drift 默认把 `DateTime` 存成 unix 秒，毫秒级的值
/// 会全部塌成 0（于是排序键相同，测不出方向）。
TodosCompanion _row(String id, String title, {required int createdAt}) {
  return TodosCompanion.insert(
    id: id,
    title: title,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt * 1000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(createdAt * 1000),
  );
}

void main() {
  late AppDatabase db;
  late TodoDao dao;

  setUp(() async {
    db = AppDatabase.memory();
    dao = TodoDao(db);
    await dao.insert(_row('t1', '买牛奶', createdAt: 100));
    await dao.insert(_row('t2', '写周报', createdAt: 200));
  });

  tearDown(() async => db.close());

  test('watchAll 按 createdAt DESC（新建在上）', () async {
    final rows = await dao.watchAll().first;
    expect(rows.map((r) => r.id), ['t2', 't1']);
  });

  test('update 是部分写入：只改 is_done，不动 title / created_at', () async {
    final before = (await dao.watchAll().first).firstWhere((r) => r.id == 't1');

    final hit = await dao.updateById(
      TodosCompanion(id: const Value('t1'), isDone: const Value(true)),
    );

    final after = (await dao.watchAll().first).firstWhere((r) => r.id == 't1');
    expect(hit, isTrue);
    expect(after.isDone, isTrue);
    expect(after.title, before.title, reason: '没被动');
    expect(after.createdAt, before.createdAt, reason: '没被动 → 列表不会跳位');
  });

  test('失败回滚：再 write 一次旧值即可还原', () async {
    await dao.updateById(
      TodosCompanion(id: const Value('t1'), isDone: const Value(true)),
    );
    await dao.updateById(
      TodosCompanion(id: const Value('t1'), isDone: const Value(false)),
    );

    final row = (await dao.watchAll().first).firstWhere((r) => r.id == 't1');
    expect(row.isDone, isFalse);
  });

  test('update 未命中返回 false；delete 返回受影响行数', () async {
    expect(
      await dao.updateById(
        TodosCompanion(id: const Value('nope'), isDone: const Value(true)),
      ),
      isFalse,
    );
    expect(await dao.deleteById('t1'), 1);
    expect(await dao.deleteById('t1'), 0);
  });

  test('is_done 默认 false（Companion 省略该列）', () async {
    expect((await dao.watchAll().first).every((r) => !r.isDone), isTrue);
  });

  test('updateById 缺 id 时抛 ArgumentError（否则会全表更新）', () {
    expect(
      () => dao.updateById(const TodosCompanion(isDone: Value(true))),
      throwsArgumentError,
    );
  });
}
