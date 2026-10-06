import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:init/features/notes/data/repositories/folder_repository_impl.dart';
import 'package:init/features/notes/domain/entities/folder_with_count.dart';
import 'package:init/features/notes/domain/entities/note_folder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class _MockFolderLocalDataSource extends Mock
    implements FolderLocalDataSource {}

class _MockUuid extends Mock implements Uuid {}

final DateTime _t1 = DateTime(2026, 10, 3);

NoteFolder _folder({String id = 'f1', String name = '词声笔记'}) =>
    NoteFolder(id: id, name: name, createdAt: _t1, updatedAt: _t1);

void main() {
  late _MockFolderLocalDataSource ds;
  late FolderRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(_folder());
    // `reorder(List<String>)` 的 ids：mocktail 的 any() 要它。
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    ds = _MockFolderLocalDataSource();
    repo = FolderRepositoryImpl(ds);
  });

  group('create', () {
    test('id 为空时生成 uuid', () async {
      final uuid = _MockUuid();
      when(() => uuid.v4()).thenReturn('generated');
      when(
        () => ds.insert(any()),
      ).thenAnswer((_) async => _folder(id: 'generated'));

      await FolderRepositoryImpl(ds, uuid: uuid).create(_folder(id: ''));

      final captured =
          verify(() => ds.insert(captureAny())).captured.single as NoteFolder;
      expect(captured.id, 'generated');
    });

    test('UNIQUE 冲突 -> Left(InputFailure)', () async {
      when(() => ds.insert(any())).thenThrow(
        CacheException(
          message: '$kUniqueConstraintPrefix UNIQUE constraint failed',
        ),
      );
      final result = await repo.create(_folder(id: ''));
      result.fold(
        (f) => expect(f, isA<InputFailure>()),
        (_) => fail('应为 Left(InputFailure)'),
      );
    });

    test('其余 CacheException -> Left(CacheFailure)', () async {
      when(
        () => ds.insert(any()),
      ).thenThrow(CacheException(message: 'disk full'));
      expect(
        await repo.create(_folder(id: '')),
        const Left<Failure, NoteFolder>(CacheFailure(message: 'disk full')),
      );
    });

    test('未知异常 -> Left(CacheFailure)，不 rethrow', () async {
      when(() => ds.insert(any())).thenThrow(StateError('boom'));
      final result = await repo.create(_folder(id: ''));
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('rename', () {
    test('正常 -> Right(回读实体)，参数为 (folderId, name)', () async {
      when(
        () => ds.rename(any(), any()),
      ).thenAnswer((_) async => _folder(name: '改名了'));
      expect(
        await repo.rename('f1', '改名了'),
        Right<Failure, NoteFolder>(_folder(name: '改名了')),
      );
      verify(() => ds.rename('f1', '改名了')).called(1);
    });

    test('UNIQUE 冲突 -> Left(InputFailure)', () async {
      when(() => ds.rename(any(), any())).thenThrow(
        CacheException(
          message: '$kUniqueConstraintPrefix UNIQUE constraint failed',
        ),
      );
      final result = await repo.rename('f1', '词声笔记');
      result.fold(
        (f) => expect(f, isA<InputFailure>()),
        (_) => fail('应为 Left(InputFailure)'),
      );
    });

    test('不存在 -> Left(CacheFailure)', () async {
      when(
        () => ds.rename(any(), any()),
      ).thenThrow(CacheException(message: 'Folder not found: nope'));
      expect(
        await repo.rename('nope', 'x'),
        const Left<Failure, NoteFolder>(
          CacheFailure(message: 'Folder not found: nope'),
        ),
      );
    });
  });

  group('delete', () {
    test('成功 -> Right(unit)', () async {
      when(() => ds.delete(any())).thenAnswer((_) async {});
      expect(await repo.delete('f1'), const Right<Failure, Unit>(unit));
    });

    test('CacheException -> Left(CacheFailure)', () async {
      when(
        () => ds.delete(any()),
      ).thenThrow(CacheException(message: 'Folder not found: nope'));
      expect(
        await repo.delete('nope'),
        const Left<Failure, Unit>(
          CacheFailure(message: 'Folder not found: nope'),
        ),
      );
    });
  });

  group('reorder', () {
    test('成功 -> Right(unit)，ids 原样透传', () async {
      when(() => ds.reorder(any())).thenAnswer((_) async {});
      expect(
        await repo.reorder(<String>['f2', 'f1']),
        const Right<Failure, Unit>(unit),
      );
      verify(() => ds.reorder(<String>['f2', 'f1'])).called(1);
    });

    test('CacheException -> Left(CacheFailure)', () async {
      when(
        () => ds.reorder(any()),
      ).thenThrow(CacheException(message: 'disk full'));
      expect(
        await repo.reorder(<String>['f1']),
        const Left<Failure, Unit>(CacheFailure(message: 'disk full')),
      );
    });
  });

  test('watchWithCounts 直接透传 Repository 那个流实例', () {
    final stream = Stream.value([FolderWithCount(folder: _folder(), count: 1)]);
    when(() => ds.watchWithCounts()).thenAnswer((_) => stream);
    expect(repo.watchWithCounts(), same(stream));
  });

  test('watchUncategorizedCount 直接透传那个标量流（不回退成读列表）', () {
    final stream = Stream.value(154);
    when(() => ds.watchUncategorizedCount()).thenAnswer((_) => stream);
    expect(repo.watchUncategorizedCount(), same(stream));
    verifyNever(() => ds.watchWithCounts());
  });
}
