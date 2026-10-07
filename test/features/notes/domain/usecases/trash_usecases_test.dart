import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/empty_trash_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/purge_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/restore_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_deleted_notes_use_case.dart';
import 'package:mocktail/mocktail.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

final Note _note = Note(
  id: 'n1',
  title: '标题',
  content: '[]',
  createdAt: DateTime(2026, 10, 3),
  updatedAt: DateTime(2026, 10, 3),
);

void main() {
  late _MockNoteRepository repo;

  setUp(() => repo = _MockNoteRepository());

  /// 校验类断言：既要 `Left(InputFailure)`，又要证明 Repository 没被碰过。
  void expectInputFailure(Future<Either<Failure, Object?>> result) async {
    final value = await result;
    value.fold(
      (f) => expect(f, isA<InputFailure>()),
      (_) => fail('应为 Left(InputFailure)'),
    );
    verifyZeroInteractions(repo);
  }

  group('WatchDeletedNotesUseCase', () {
    test('原样返回 Repository 那个流实例', () {
      final stream = Stream.value(<Note>[_note]);
      when(() => repo.watchDeleted()).thenAnswer((_) => stream);
      expect(WatchDeletedNotesUseCase(repo)(), same(stream));
    });
  });

  group('RestoreNoteUseCase', () {
    test('空 noteId -> InputFailure 且不调 Repository', () {
      expectInputFailure(RestoreNoteUseCase(repo)(''));
    });

    test('成功：原样透传 noteId', () async {
      when(
        () => repo.restore(any()),
      ).thenAnswer((_) async => const Right(unit));
      expect(
        await RestoreNoteUseCase(repo)('n1'),
        const Right<Failure, Unit>(unit),
      );
      verify(() => repo.restore('n1')).called(1);
    });

    test('失败透传：Left 原样', () async {
      when(
        () => repo.restore(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'not found')));
      final result = await RestoreNoteUseCase(repo)('nope');
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('PurgeNoteUseCase', () {
    test('空 noteId -> InputFailure 且不调 Repository', () {
      expectInputFailure(PurgeNoteUseCase(repo)(''));
    });

    test('成功：原样透传 noteId', () async {
      when(() => repo.purge(any())).thenAnswer((_) async => const Right(unit));
      expect(
        await PurgeNoteUseCase(repo)('n1'),
        const Right<Failure, Unit>(unit),
      );
      verify(() => repo.purge('n1')).called(1);
    });

    test('失败透传：Left 原样', () async {
      when(
        () => repo.purge(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'boom')));
      final result = await PurgeNoteUseCase(repo)('n1');
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('EmptyTrashUseCase', () {
    test('成功：透传 purgeAll', () async {
      when(
        () => repo.purgeAll(),
      ).thenAnswer((_) async => const Right(unit));
      expect(await EmptyTrashUseCase(repo)(), const Right<Failure, Unit>(unit));
      verify(() => repo.purgeAll()).called(1);
    });

    test('失败透传：Left 原样', () async {
      when(
        () => repo.purgeAll(),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await EmptyTrashUseCase(repo)();
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });
}