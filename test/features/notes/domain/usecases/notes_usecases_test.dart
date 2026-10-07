import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/repositories/folder_repository.dart';
import 'package:mynote/features/notes/domain/repositories/note_repository.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_params.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_params.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/delete_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/delete_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/rename_folder_params.dart';
import 'package:mynote/features/notes/domain/usecases/rename_folder_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/reorder_folders_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_background_params.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_background_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_params.dart';
import 'package:mynote/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_folder_counts_use_case.dart';
import 'package:mynote/features/notes/domain/usecases/watch_notes_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

class MockFolderRepository extends Mock implements FolderRepository {}

final DateTime _t1 = DateTime(2026, 8, 25);

final Note _note = Note(
  id: 'n1',
  title: 't',
  content: 'c',
  folderId: null,
  createdAt: _t1,
  updatedAt: _t1,
);

final NoteFolder _folder = NoteFolder(
  id: 'f1',
  name: '词声笔记',
  createdAt: _t1,
  updatedAt: _t1,
);

void main() {
  late MockNoteRepository notes;
  late MockFolderRepository folders;

  setUpAll(() {
    registerFallbackValue(_note);
    registerFallbackValue(_folder);
    registerFallbackValue(const NoteQuery());
    registerFallbackValue(const CreateNoteParams(title: 'x', content: 'y'));
    registerFallbackValue(
      const UpdateNoteParams(noteId: 'n', title: 'x', content: 'y'),
    );
    registerFallbackValue(const CreateFolderParams(name: 'x'));
    registerFallbackValue(const RenameFolderParams(folderId: 'f', name: 'x'));
    registerFallbackValue(
      const UpdateNoteBackgroundParams(
        noteId: 'n',
        background: NoteBackground.paper,
      ),
    );
    registerFallbackValue(NoParams());
  });

  setUp(() {
    notes = MockNoteRepository();
    folders = MockFolderRepository();
  });

  /// 校验失败的断言：**既要 Left(InputFailure)，又要证明 Repository 没被碰过**。
  /// 只断言前者的话，「校验写在 Repository 之前」还是「之后」分不清。
  void expectInputFailure(
    Future<Either<Failure, Object?>> result,
    Object mock,
  ) async {
    final value = await result;
    value.fold(
      (f) => expect(f, isA<InputFailure>()),
      (_) => fail('应为 Left(InputFailure)'),
    );
    verifyZeroInteractions(mock);
  }

  group('WatchNotesUseCase', () {
    test('原样返回 Repository 那个流实例', () {
      final stream = Stream.value([_note]);
      when(() => notes.watch(any())).thenAnswer((_) => stream);
      expect(WatchNotesUseCase(notes)(const NoteQuery()), same(stream));
    });

    test('limit < 0 -> 空流且不调 Repository（不抛异常、不返回 Left）', () async {
      final result = await WatchNotesUseCase(notes)(
        const NoteQuery(limit: -1),
      ).toList();
      expect(result, isEmpty);
      verifyZeroInteractions(notes);
    });
  });

  group('GetNoteUseCase', () {
    test('#1 空 noteId -> InputFailure 且不调 Repository', () {
      expectInputFailure(GetNoteUseCase(notes)(''), notes);
    });

    test('成功：noteId 原样透传，Right(note)', () async {
      when(
        () => notes.getById('n1'),
      ).thenAnswer((_) async => Right<Failure, Note>(_note));
      expect(await GetNoteUseCase(notes)('n1'), Right<Failure, Note>(_note));
      verify(() => notes.getById('n1')).called(1);
    });

    test('失败透传：Left(CacheFailure) 原样，不二次包装', () async {
      when(
        () => notes.getById('n1'),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await GetNoteUseCase(notes)('n1');
      result.fold(
        (f) => expect((f as CacheFailure).message, 'disk full'),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('CreateNoteUseCase', () {
    test('#2 title 与 content 同时为空（trim 后）-> InputFailure 且不调 Repository', () {
      expectInputFailure(
        CreateNoteUseCase(notes)(
          const CreateNoteParams(title: '  ', content: ''),
        ),
        notes,
      );
    });

    test('成功：仅 content 有值时放行，且 id 传空串交给 Repository 生成', () async {
      when(
        () => notes.create(any()),
      ).thenAnswer((_) async => Right<Failure, Note>(_note));
      expect(
        await CreateNoteUseCase(notes)(
          const CreateNoteParams(title: '', content: '正文'),
        ),
        Right<Failure, Note>(_note),
      );
      final captured =
          verify(() => notes.create(captureAny())).captured.single as Note;
      expect(captured.id, '', reason: 'uuid 由 Repository 生成');
      expect(captured.title, '', reason: '不擅自补标题');
      expect(captured.content, '正文');
    });

    test('成功：标题与正文都原样透传（校验用 trim，存回原值）', () async {
      when(
        () => notes.create(any()),
      ).thenAnswer((_) async => Right<Failure, Note>(_note));
      await CreateNoteUseCase(notes)(
        const CreateNoteParams(
          title: ' 留空格的标题 ',
          content: ' c ',
          folderId: 'f1',
        ),
      );
      final captured =
          verify(() => notes.create(captureAny())).captured.single as Note;
      expect(captured.title, ' 留空格的标题 ');
      expect(captured.content, ' c ');
      expect(captured.folderId, 'f1');
    });

    test('成功：新笔记上先选的背景随首次落库一起写入', () async {
      when(
        () => notes.create(any()),
      ).thenAnswer((_) async => Right<Failure, Note>(_note));
      await CreateNoteUseCase(notes)(
        const CreateNoteParams(
          title: 't',
          content: 'c',
          background: NoteBackground.mint,
        ),
      );
      final captured =
          verify(() => notes.create(captureAny())).captured.single as Note;
      expect(captured.background, NoteBackground.mint);
    });

    test('失败透传：Left(CacheFailure) 原样', () async {
      when(
        () => notes.create(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await CreateNoteUseCase(notes)(
        const CreateNoteParams(title: 't', content: 'c'),
      );
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left(CacheFailure)，不能被包成 InputFailure'),
      );
    });
  });

  group('UpdateNoteUseCase', () {
    test('#3 空 noteId -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        UpdateNoteUseCase(notes)(
          const UpdateNoteParams(noteId: '', title: 't', content: 'c'),
        ),
        notes,
      );
    });

    test('#4 title 与 content 同时为空 -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        UpdateNoteUseCase(notes)(
          const UpdateNoteParams(noteId: 'n1', title: '', content: '  '),
        ),
        notes,
      );
    });

    test('成功：只把 title / content / folderId 交给 Repository', () async {
      when(
        () => notes.update(any()),
      ).thenAnswer((_) async => Right<Failure, Note>(_note));
      expect(
        await UpdateNoteUseCase(notes)(
          const UpdateNoteParams(
            noteId: 'n1',
            title: '新标题',
            content: '新正文',
            folderId: 'f2',
          ),
        ),
        Right<Failure, Note>(_note),
      );
      final captured =
          verify(() => notes.update(captureAny())).captured.single as Note;
      expect(captured.id, 'n1');
      expect(captured.title, '新标题');
      expect(captured.content, '新正文');
      expect(captured.folderId, 'f2');
    });

    test('成功：clearFolderId 把笔记移回未分类（folderId 真的置 null）', () async {
      when(
        () => notes.update(any()),
      ).thenAnswer((_) async => Right<Failure, Note>(_note));
      await UpdateNoteUseCase(notes)(
        const UpdateNoteParams(
          noteId: 'n1',
          title: 't',
          content: 'c',
          folderId: 'f2',
          clearFolderId: true,
        ),
      );
      final captured =
          verify(() => notes.update(captureAny())).captured.single as Note;
      expect(captured.folderId, isNull, reason: 'clearFolderId 优先于 folderId');
    });

    test('失败透传：Left(CacheFailure) 原样', () async {
      when(
        () => notes.update(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await UpdateNoteUseCase(notes)(
        const UpdateNoteParams(noteId: 'n1', title: 't', content: 'c'),
      );
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('UpdateNoteBackgroundUseCase', () {
    test('空 noteId -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        UpdateNoteBackgroundUseCase(notes)(
          const UpdateNoteBackgroundParams(
            noteId: '',
            background: NoteBackground.paper,
          ),
        ),
        notes,
      );
    });

    test('成功：走 updateBackground 窄通道，不碰整行 update', () async {
      when(
        () => notes.updateBackground('n1', NoteBackground.blush),
      ).thenAnswer((_) async => const Right(unit));
      expect(
        await UpdateNoteBackgroundUseCase(notes)(
          const UpdateNoteBackgroundParams(
            noteId: 'n1',
            background: NoteBackground.blush,
          ),
        ),
        const Right<Failure, Unit>(unit),
      );
      verify(
        () => notes.updateBackground('n1', NoteBackground.blush),
      ).called(1);
      // 整行 update 会刷新 updatedAt，换背景不该走它。
      verifyNever(() => notes.update(any()));
    });

    test('成功：background 为 null 时清除背景', () async {
      when(
        () => notes.updateBackground('n1', null),
      ).thenAnswer((_) async => const Right(unit));
      await UpdateNoteBackgroundUseCase(notes)(
        const UpdateNoteBackgroundParams(noteId: 'n1', background: null),
      );
      verify(() => notes.updateBackground('n1', null)).called(1);
    });

    test('失败透传：Left(CacheFailure) 原样', () async {
      when(
        () => notes.updateBackground(any(), any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await UpdateNoteBackgroundUseCase(notes)(
        const UpdateNoteBackgroundParams(
          noteId: 'n1',
          background: NoteBackground.paper,
        ),
      );
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('DeleteNoteUseCase', () {
    test('#5 空 noteId -> InputFailure 且不调 Repository', () {
      expectInputFailure(DeleteNoteUseCase(notes)(''), notes);
    });

    test('成功：原样透传，不做存在性预检', () async {
      when(() => notes.delete('n1')).thenAnswer((_) async => const Right(unit));
      expect(
        await DeleteNoteUseCase(notes)('n1'),
        const Right<Failure, Unit>(unit),
      );
      verify(() => notes.delete('n1')).called(1);
    });

    test('失败透传：Repository 的 Left 原样', () async {
      when(
        () => notes.delete('nope'),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'not found')));
      final result = await DeleteNoteUseCase(notes)('nope');
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('CreateFolderUseCase', () {
    test('#6 名称 trim 后为空 -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        CreateFolderUseCase(folders)(const CreateFolderParams(name: '  ')),
        folders,
      );
    });

    test('#7 名称 41 字符 -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        CreateFolderUseCase(folders)(CreateFolderParams(name: 'a' * 41)),
        folders,
      );
    });

    test('成功：40 字符放行，id 传空串，名称是 trim 后的值', () async {
      when(
        () => folders.create(any()),
      ).thenAnswer((_) async => Right<Failure, NoteFolder>(_folder));
      final result = await CreateFolderUseCase(folders)(
        const CreateFolderParams(name: '  词声笔记  '),
      );
      expect(result, Right<Failure, NoteFolder>(_folder));
      final captured =
          verify(() => folders.create(captureAny())).captured.single
              as NoteFolder;
      expect(captured.id, '');
      expect(captured.name, '词声笔记', reason: '存回 trim 后的值');
    });

    test('失败透传：重名的 Left(InputFailure) 原样透传，不二次包装', () async {
      when(() => folders.create(any())).thenAnswer(
        (_) async => const Left(InputFailure(message: 'UNIQUE: ...')),
      );
      final result = await CreateFolderUseCase(folders)(
        const CreateFolderParams(name: '词声笔记'),
      );
      result.fold(
        (f) => expect(f, isA<InputFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('RenameFolderUseCase', () {
    test('#8 空 folderId -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        RenameFolderUseCase(folders)(
          const RenameFolderParams(folderId: '', name: 'x'),
        ),
        folders,
      );
    });

    test('#9 空名称 -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        RenameFolderUseCase(folders)(
          const RenameFolderParams(folderId: 'f1', name: ''),
        ),
        folders,
      );
    });

    test('超长名称 -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        RenameFolderUseCase(folders)(
          RenameFolderParams(folderId: 'f1', name: 'a' * 41),
        ),
        folders,
      );
    });

    test('成功：参数为 (folderId, trim 后名称)', () async {
      when(
        () => folders.rename(any(), any()),
      ).thenAnswer((_) async => Right<Failure, NoteFolder>(_folder));
      expect(
        await RenameFolderUseCase(folders)(
          const RenameFolderParams(folderId: 'f1', name: ' 改名了 '),
        ),
        Right<Failure, NoteFolder>(_folder),
      );
      verify(() => folders.rename('f1', '改名了')).called(1);
    });

    test('失败透传：Left 原样', () async {
      when(
        () => folders.rename(any(), any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await RenameFolderUseCase(folders)(
        const RenameFolderParams(folderId: 'f1', name: 'x'),
      );
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('DeleteFolderUseCase', () {
    test('空 folderId -> InputFailure 且不调 Repository', () {
      expectInputFailure(DeleteFolderUseCase(folders)(''), folders);
    });

    test('成功：原样透传', () async {
      when(
        () => folders.delete('f1'),
      ).thenAnswer((_) async => const Right(unit));
      expect(
        await DeleteFolderUseCase(folders)('f1'),
        const Right<Failure, Unit>(unit),
      );
      verify(() => folders.delete('f1')).called(1);
    });

    test('失败透传：Left 原样', () async {
      when(
        () => folders.delete('nope'),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'not found')));
      final result = await DeleteFolderUseCase(folders)('nope');
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('ReorderFoldersUseCase', () {
    test('成功：整份顺序原样透传（不预检、不比较）', () async {
      // 同一个 List 实例贯穿 when / call / verify —— mocktail 对 List 参数
      // 走 `==`（即同一性），换一个字面量就匹配不上。
      final ids = <String>['f2', 'f1'];
      when(
        () => folders.reorder(ids),
      ).thenAnswer((_) async => const Right(unit));

      expect(
        await ReorderFoldersUseCase(folders)(ids),
        const Right<Failure, Unit>(unit),
      );
      verify(() => folders.reorder(ids)).called(1);
    });

    test('失败透传：Left 原样，不二次包装', () async {
      final ids = <String>['f1', 'f2'];
      when(
        () => folders.reorder(ids),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));

      final result = await ReorderFoldersUseCase(folders)(ids);
      expect(
        result,
        const Left<Failure, Unit>(CacheFailure(message: 'disk full')),
      );
    });
  });

  group('WatchFolderCountsUseCase', () {
    test('原样返回 Repository 那个流实例（不做二次排序）', () {
      final stream = Stream.value([FolderWithCount(folder: _folder, count: 3)]);
      when(() => folders.watchWithCounts()).thenAnswer((_) => stream);
      expect(WatchFolderCountsUseCase(folders)(NoParams()), same(stream));
    });
  });
}
