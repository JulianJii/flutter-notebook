import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_params.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_params.dart';
import 'package:mynote/features/notes/presentation/providers/note_list_provider.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  ProviderContainer containerFor(AppDatabase database) => ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );

  /// autoDispose 的 stream provider 靠 listener 续命 —— `read(p.future)` 会
  /// 立刻释放订阅并把 provider 在 loading 态 dispose 掉。
  void keepAlive(NoteQuery query) {
    final sub = container.listen<AsyncValue<List<Note>>>(
      noteListProvider(query),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
  }

  setUp(() async {
    db = AppDatabase.memory();
    container = containerFor(db);

    final folders = container.read(createFolderUseCaseProvider);
    final notes = container.read(createNoteUseCaseProvider);

    Future<String> folderId(String name) async =>
        (await folders(CreateFolderParams(name: name))).fold(
          (_) => throw StateError('create folder $name failed'),
          (folder) => folder.id,
        );

    final first = await folderId('词声笔记');
    final second = await folderId('工作');

    await notes(CreateNoteParams(title: '有文件夹', content: '', folderId: first));
    await notes(const CreateNoteParams(title: '未分类', content: ''));
    await notes(
      CreateNoteParams(title: '另一个文件夹', content: '', folderId: second),
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('不同 NoteQuery 是独立的 family 实例，互不覆盖', () async {
    keepAlive(const NoteQuery());
    keepAlive(NoteQuery.uncategorized());
    await pumpEventQueue();

    final all = container.read(noteListProvider(const NoteQuery())).value!;
    final uncat = container
        .read(noteListProvider(NoteQuery.uncategorized()))
        .value!;

    expect(all.length, 3);
    expect(uncat.length, 1);
    expect(uncat.single.title, '未分类');
  });

  test('相同 NoteQuery（值相等）命中同一缓存，不重复订阅', () async {
    keepAlive(const NoteQuery());
    await pumpEventQueue();

    expect(
      container.read(noteListProvider(const NoteQuery())),
      same(container.read(noteListProvider(const NoteQuery()))),
      reason: '值相等的 NoteQuery 必须落同一个 family key，否则每次 build 都会重建流',
    );
  });

  test('按 folderId 筛选：只返回该文件夹下的笔记', () async {
    final counts = await container
        .read(watchFolderCountsUseCaseProvider)(NoParams())
        .first;
    final target = counts.firstWhere((f) => f.folder.name == '工作').folder.id;

    keepAlive(NoteQuery.of(target));
    await pumpEventQueue();

    final filtered = container
        .read(noteListProvider(NoteQuery.of(target)))
        .value!;

    expect(filtered.single.title, '另一个文件夹');
  });

  test('数据变更后 stream 自动推送新列表（无需 ref.invalidate）', () async {
    final emissions = <List<Note>>[];
    final sub = container.listen<AsyncValue<List<Note>>>(
      noteListProvider(const NoteQuery()),
      (_, next) {
        final value = next.value;
        if (value != null) emissions.add(value);
      },
      fireImmediately: true,
    );
    addTearDown(sub.close);
    await pumpEventQueue();

    await container.read(createNoteUseCaseProvider)(
      const CreateNoteParams(title: '新笔记', content: ''),
    );
    await pumpEventQueue();

    expect(emissions.last.length, 4);
    expect(emissions.last.map((n) => n.title), contains('新笔记'));
  });

  test('读库失败时落在 AsyncValue.hasError（不静默空列表）', () async {
    await db.close();

    keepAlive(const NoteQuery());
    await pumpEventQueue();

    final async = container.read(noteListProvider(const NoteQuery()));
    expect(async.hasError, isTrue);
    expect(async.value, isNull);
  });
}
