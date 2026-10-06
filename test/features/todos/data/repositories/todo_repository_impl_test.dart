import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:init/features/todos/data/repositories/todo_repository_impl.dart';
import 'package:init/features/todos/domain/entities/todo.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class _MockTodoLocalDataSource extends Mock implements TodoLocalDataSource {}

class _MockUuid extends Mock implements Uuid {}

final DateTime _t1 = DateTime(2026, 10, 3);
final DateTime _t2 = DateTime(2026, 10, 4);

Todo _todo({String id = 't1', String title = '买牛奶', bool isDone = false}) =>
    Todo(id: id, title: title, isDone: isDone, createdAt: _t1, updatedAt: _t1);

void main() {
  late _MockTodoLocalDataSource ds;
  late TodoRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(_todo());
  });

  setUp(() {
    ds = _MockTodoLocalDataSource();
    repo = TodoRepositoryImpl(ds);
  });

  test('create: id 为空时生成 uuid，isDone 保持 false', () async {
    final uuid = _MockUuid();
    when(() => uuid.v4()).thenReturn('generated');
    when(
      () => ds.insert(any()),
    ).thenAnswer((_) async => _todo(id: 'generated'));

    await TodoRepositoryImpl(ds, uuid: uuid).create(_todo(id: ''));

    final captured =
        verify(() => ds.insert(captureAny())).captured.single as Todo;
    expect(captured.id, 'generated');
    expect(captured.isDone, isFalse);
  });

  test('create: CacheException -> CacheFailure', () async {
    when(
      () => ds.insert(any()),
    ).thenThrow(CacheException(message: 'disk full'));
    expect(
      await repo.create(_todo(id: '')),
      const Left<Failure, Todo>(CacheFailure(message: 'disk full')),
    );
  });

  test('create: 未知异常 -> CacheFailure，不 rethrow', () async {
    when(() => ds.insert(any())).thenThrow(StateError('boom'));
    final result = await repo.create(_todo(id: ''));
    result.fold((f) => expect(f, isA<CacheFailure>()), (_) => fail('应为 Left'));
  });

  test('update: 刷新 updatedAt，保留 createdAt（勾选不跳位）', () async {
    when(() => ds.update(any())).thenAnswer((_) async => _todo(isDone: true));

    await repo.update(_todo(isDone: true));

    final saved = verify(() => ds.update(captureAny())).captured.single as Todo;
    expect(saved.isDone, isTrue, reason: '传的是目标值，不是翻转');
    expect(saved.createdAt, _t1);
    expect(saved.updatedAt.isAfter(_t2), isTrue);
  });

  test('update: CacheException -> CacheFailure（乐观更新失败的回滚信号）', () async {
    when(
      () => ds.update(any()),
    ).thenThrow(CacheException(message: 'disk full'));
    expect(
      await repo.update(_todo(isDone: true)),
      const Left<Failure, Todo>(CacheFailure(message: 'disk full')),
    );
  });

  test('delete: 成功 -> Right(unit)', () async {
    when(() => ds.delete(any())).thenAnswer((_) async {});
    expect(await repo.delete('t1'), const Right<Failure, Unit>(unit));
  });

  test('delete: 未命中 -> Left(CacheFailure)', () async {
    when(
      () => ds.delete(any()),
    ).thenThrow(CacheException(message: 'Todo not found: nope'));
    expect(
      await repo.delete('nope'),
      const Left<Failure, Unit>(CacheFailure(message: 'Todo not found: nope')),
    );
  });

  test('deleteCompleted: 成功 -> Right(删除行数)', () async {
    when(() => ds.deleteCompleted()).thenAnswer((_) async => 3);
    expect(await repo.deleteCompleted(), const Right<Failure, int>(3));
  });

  test('deleteCompleted: 0 行是合法结果（已清空），不是失败', () async {
    when(() => ds.deleteCompleted()).thenAnswer((_) async => 0);
    expect(await repo.deleteCompleted(), const Right<Failure, int>(0));
  });

  test('deleteCompleted: CacheException -> CacheFailure', () async {
    when(
      () => ds.deleteCompleted(),
    ).thenThrow(CacheException(message: 'disk full'));
    expect(
      await repo.deleteCompleted(),
      const Left<Failure, int>(CacheFailure(message: 'disk full')),
    );
  });

  test('watchAll 直接透传 Repository 那个流实例', () {    final stream = Stream.value([_todo()]);
    when(() => ds.watchAll()).thenAnswer((_) => stream);
    expect(repo.watchAll(), same(stream));
  });
}
