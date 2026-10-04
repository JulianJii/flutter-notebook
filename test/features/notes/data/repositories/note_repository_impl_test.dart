import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/data/datasources/note_local_data_source.dart';
import 'package:init/features/notes/data/repositories/note_repository_impl.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class _MockNoteLocalDataSource extends Mock implements NoteLocalDataSource {}

class _MockUuid extends Mock implements Uuid {}

final DateTime _t1 = DateTime(2026, 10, 3);
final DateTime _t2 = DateTime(2026, 10, 4);

Note _note({String id = 'n1', String title = 't', String content = 'c'}) =>
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: _t1,
      updatedAt: _t1,
    );

void main() {
  late _MockNoteLocalDataSource ds;
  late NoteRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(_note());
  });

  setUp(() {
    ds = _MockNoteLocalDataSource();
    repo = NoteRepositoryImpl(ds);
  });

  group('create', () {
    test('id 为空时生成 uuid v4 传给 datasource', () async {
      final uuid = _MockUuid();
      when(() => uuid.v4()).thenReturn('generated-id');
      final target = NoteRepositoryImpl(ds, uuid: uuid);
      when(
        () => ds.insert(any()),
      ).thenAnswer((_) async => _note(id: 'generated-id'));

      await target.create(_note(id: ''));

      final captured =
          verify(() => ds.insert(captureAny())).captured.single as Note;
      expect(captured.id, 'generated-id');
    });

    test('id 非空时原样透传，不生成 uuid', () async {
      final uuid = _MockUuid();
      final target = NoteRepositoryImpl(ds, uuid: uuid);
      when(() => ds.insert(any())).thenAnswer((_) async => _note());

      await target.create(_note(id: 'given'));

      verifyNever(() => uuid.v4());
      final captured =
          verify(() => ds.insert(captureAny())).captured.single as Note;
      expect(captured.id, 'given');
    });

    test('成功 -> Right(datasource 返回的实体)', () async {
      when(
        () => ds.insert(any()),
      ).thenAnswer((_) async => _note(id: 'generated'));
      expect(
        await repo.create(_note(id: '')),
        Right<Failure, Note>(_note(id: 'generated')),
      );
    });

    test('CacheException -> CacheFailure，message 原样', () async {
      when(
        () => ds.insert(any()),
      ).thenThrow(CacheException(message: 'disk full'));
      expect(
        await repo.create(_note(id: '')),
        const Left<Failure, Note>(CacheFailure(message: 'disk full')),
      );
    });

    test('未知异常 -> CacheFailure，且不 rethrow', () async {
      when(() => ds.insert(any())).thenThrow(StateError('boom'));
      final result = await repo.create(_note(id: ''));
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('getById', () {
    test('透传 Right', () async {
      when(() => ds.getById(any())).thenAnswer((_) async => _note());
      expect(await repo.getById('n1'), Right<Failure, Note>(_note()));
      verify(() => ds.getById('n1')).called(1);
    });

    test('「找不到」的 CacheException -> CacheFailure（不是 NotFound 类）', () async {
      when(
        () => ds.getById('nope'),
      ).thenThrow(CacheException(message: 'Note not found: nope'));
      final result = await repo.getById('nope');
      result.fold(
        (f) => expect((f as CacheFailure).message, 'Note not found: nope'),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('update', () {
    test('刷新 updatedAt，但保留 createdAt 与其余字段', () async {
      when(() => ds.update(any())).thenAnswer((_) async => _note());
      await repo.update(_note(title: 't2', content: 'c2'));

      final saved =
          verify(() => ds.update(captureAny())).captured.single as Note;
      expect(saved.title, 't2');
      expect(saved.content, 'c2');
      expect(saved.createdAt, _t1, reason: 'createdAt 不能被自动保存覆盖');
      expect(saved.updatedAt.isAfter(_t2), isTrue, reason: 'updatedAt 应被刷新');
    });

    test('CacheException -> CacheFailure', () async {
      when(
        () => ds.update(any()),
      ).thenThrow(CacheException(message: 'disk full'));
      expect(
        await repo.update(_note()),
        const Left<Failure, Note>(CacheFailure(message: 'disk full')),
      );
    });
  });

  group('delete', () {
    test('成功 -> Right(unit)', () async {
      when(() => ds.delete(any())).thenAnswer((_) async {});
      expect(await repo.delete('n1'), const Right<Failure, Unit>(unit));
    });

    test('CacheException -> CacheFailure', () async {
      when(
        () => ds.delete(any()),
      ).thenThrow(CacheException(message: 'Note not found: nope'));
      expect(
        await repo.delete('nope'),
        const Left<Failure, Unit>(
          CacheFailure(message: 'Note not found: nope'),
        ),
      );
    });
  });

  test('watch 直接透传 Repository 那个流实例（不加 try、不包 Either）', () {
    final stream = Stream.value([_note()]);
    when(() => ds.watch(any())).thenAnswer((_) => stream);
    expect(repo.watch(const NoteQuery()), same(stream));
  });
}
