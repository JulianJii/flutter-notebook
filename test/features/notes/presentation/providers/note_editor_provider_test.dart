import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notes/domain/entities/note.dart';
import 'package:init/features/notes/domain/usecases/create_note_params.dart';
import 'package:init/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/update_note_params.dart';
import 'package:init/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:init/features/notes/presentation/providers/note_editor_provider.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetNote extends Mock implements GetNoteUseCase {}

class _MockCreateNote extends Mock implements CreateNoteUseCase {}

class _MockUpdateNote extends Mock implements UpdateNoteUseCase {}

Note _note({String title = '标题', String content = '正文'}) => Note(
  id: 'n1',
  title: title,
  content: content,
  createdAt: DateTime(2026, 10, 3, 6, 40),
  updatedAt: DateTime(2026, 10, 3, 6, 40),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_note());
    registerFallbackValue(
      const UpdateNoteParams(noteId: 'n1', title: '', content: ''),
    );
    registerFallbackValue(const CreateNoteParams(title: '', content: ''));
  });

  ProviderContainer containerFor(
    GetNoteUseCase get, {
    CreateNoteUseCase? create,
    UpdateNoteUseCase? update,
  }) {
    final container = ProviderContainer(
      overrides: [
        getNoteUseCaseProvider.overrideWithValue(get),
        if (create != null) createNoteUseCaseProvider.overrideWithValue(create),
        if (update != null) updateNoteUseCaseProvider.overrideWithValue(update),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// autoDispose 的 provider 靠 listener 续命 —— `read(p.future)` 会立刻释放
  /// 订阅并把 provider 在 loading 态 dispose 掉。
  void keepAlive(ProviderContainer container, String noteId) {
    final sub = container.listen<AsyncValue<NoteEditorState>>(
      noteEditorProvider(noteId),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
  }

  test('新建：build 不调任何 UseCase，草稿为空且 isDirty 为 false', () async {
    final get = _MockGetNote();
    final container = containerFor(get);
    keepAlive(container, kNewNoteId);

    final s = await container.read(noteEditorProvider(kNewNoteId).future);

    expect(s.draftTitle, isEmpty);
    expect(s.draftContent, isEmpty);
    expect(s.isDirty, isFalse);
    expect(s.isNew, isTrue);
    verifyZeroInteractions(get);
  });

  test('既有笔记：build 走 getNote，draft 与 saved 同时就位', () async {
    final get = _MockGetNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note()));
    final container = containerFor(get);
    keepAlive(container, 'n1');

    final s = await container.read(noteEditorProvider('n1').future);

    expect(s.draftTitle, '标题');
    expect(s.savedContent, '正文');
    expect(s.isDirty, isFalse);
    expect(s.isNew, isFalse);
  });

  test('读取失败：state 进入 error，携带 CacheFailure', () async {
    final get = _MockGetNote();
    when(
      () => get('n1'),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'boom')));
    final container = containerFor(get);

    Object? error;
    final sub = container.listen<AsyncValue<NoteEditorState>>(
      noteEditorProvider('n1'),
      (_, next) {
        if (next.hasError) error = next.error;
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await pumpEventQueue();

    expect(container.read(noteEditorProvider('n1')).hasError, isTrue);
    expect(error, isA<CacheFailure>());
  });

  test('setTitle 只改草稿并标脏，不立即落库', () async {
    final get = _MockGetNote();
    final update = _MockUpdateNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note()));
    when(
      () => update(any()),
    ).thenAnswer((_) async => Right(_note(title: '新标题')));
    final container = containerFor(get, update: update);
    keepAlive(container, 'n1');
    await container.read(noteEditorProvider('n1').future);

    container.read(noteEditorProvider('n1').notifier).setTitle('新标题');

    final s = container.read(noteEditorProvider('n1')).value!;
    expect(s.draftTitle, '新标题');
    expect(s.isDirty, isTrue);
    verifyNever(() => update(any()));
  });

  test('停止输入 500ms 后自动落库，isDirty 归零', () async {
    final get = _MockGetNote();
    final update = _MockUpdateNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note()));
    when(
      () => update(any()),
    ).thenAnswer((_) async => Right(_note(title: '新标题')));
    final container = containerFor(get, update: update);
    keepAlive(container, 'n1');
    await container.read(noteEditorProvider('n1').future);

    container.read(noteEditorProvider('n1').notifier).setTitle('新标题');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await Future<void>.delayed(Duration.zero);

    final s = container.read(noteEditorProvider('n1')).value!;
    expect(s.savedTitle, '新标题');
    expect(s.isDirty, isFalse);
    final params =
        verify(() => update(captureAny())).captured.single as UpdateNoteParams;
    expect(params.noteId, 'n1');
    expect(params.title, '新标题');
    expect(params.content, '正文');
  });

  test('连续输入只落库一次（debounce 生效）', () async {
    final get = _MockGetNote();
    final update = _MockUpdateNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note()));
    when(() => update(any())).thenAnswer((_) async => Right(_note()));
    final container = containerFor(get, update: update);
    keepAlive(container, 'n1');
    await container.read(noteEditorProvider('n1').future);

    final notifier = container.read(noteEditorProvider('n1').notifier);
    notifier.setTitle('a');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    notifier.setTitle('ab');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    notifier.setTitle('abc');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await Future<void>.delayed(Duration.zero);

    final captured = verify(() => update(captureAny())).captured;
    expect(captured, hasLength(1), reason: 'debounce 只落库一次');
    expect((captured.single as UpdateNoteParams).title, 'abc');
  });

  test('保存失败：草稿保留，isDirty 仍为 true', () async {
    final get = _MockGetNote();
    final update = _MockUpdateNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note()));
    when(
      () => update(any()),
    ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
    final container = containerFor(get, update: update);
    keepAlive(container, 'n1');
    await container.read(noteEditorProvider('n1').future);

    final notifier = container.read(noteEditorProvider('n1').notifier);
    notifier.setTitle('新标题');
    await notifier.flush();

    final s = container.read(noteEditorProvider('n1')).value!;
    expect(s.draftTitle, '新标题');
    expect(s.savedTitle, '标题');
    expect(s.isDirty, isTrue);
    expect(s.isSaving, isFalse);
  });

  test('新建笔记 flush 走 create，并用返回的 createdAt 覆盖草稿', () async {
    final get = _MockGetNote();
    final create = _MockCreateNote();
    when(
      () => create(any()),
    ).thenAnswer((_) async => Right(_note(title: '新标题')));
    final container = containerFor(get, create: create);
    keepAlive(container, kNewNoteId);
    await container.read(noteEditorProvider(kNewNoteId).future);

    final notifier = container.read(noteEditorProvider(kNewNoteId).notifier);
    notifier.setTitle('新标题');
    await notifier.flush();

    final s = container.read(noteEditorProvider(kNewNoteId)).value!;
    expect(s.isNew, isFalse);
    expect(s.savedTitle, '新标题');
    final captured = verify(() => create(captureAny())).captured;
    expect(captured, hasLength(1));
    final params = captured.single as CreateNoteParams;
    expect(params.title, '新标题');
    expect(params.content, isEmpty);
  });

  test('flush 幂等：非 dirty 时不调 UseCase', () async {
    final get = _MockGetNote();
    final update = _MockUpdateNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note()));
    final container = containerFor(get, update: update);
    keepAlive(container, 'n1');
    await container.read(noteEditorProvider('n1').future);

    await container.read(noteEditorProvider('n1').notifier).flush();
    await container.read(noteEditorProvider('n1').notifier).flush();

    verifyZeroInteractions(update);
  });

  test('wordCount 由 WordCounter 派生', () async {
    final get = _MockGetNote();
    when(
      () => get('n1'),
    ).thenAnswer((_) async => Right(_note(content: '脚下腾云亦非真')));
    final container = containerFor(get);
    keepAlive(container, 'n1');

    final s = await container.read(noteEditorProvider('n1').future);

    expect(s.wordCount, 7);
  });

  test('setContent 同样标脏并在 debounce 后落库', () async {
    final get = _MockGetNote();
    final update = _MockUpdateNote();
    when(() => get('n1')).thenAnswer((_) async => Right(_note()));
    when(
      () => update(any()),
    ).thenAnswer((_) async => Right(_note(content: '新正文')));
    final container = containerFor(get, update: update);
    keepAlive(container, 'n1');
    await container.read(noteEditorProvider('n1').future);

    final notifier = container.read(noteEditorProvider('n1').notifier);
    notifier.setContent('新正文');
    expect(container.read(noteEditorProvider('n1')).value!.isDirty, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 600));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(noteEditorProvider('n1')).value!.isDirty, isFalse);
  });
}
