import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/notes/domain/entities/folder_with_count.dart';
import 'package:mynote/features/notes/domain/entities/note_folder.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_params.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_params.dart';
import 'package:mynote/features/notes/domain/usecases/watch_folder_counts_use_case.dart';
import 'package:mynote/features/notes/presentation/providers/folder_provider.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchFolderCountsUseCase extends Mock
    implements WatchFolderCountsUseCase {}

final DateTime _t0 = DateTime(2026, 1, 1);

NoteFolder _folder(String id, String name) =>
    NoteFolder(id: id, name: name, createdAt: _t0, updatedAt: _t0);

void main() {
  setUpAll(() => registerFallbackValue(NoParams()));

  late AppDatabase db;
  late ProviderContainer container;

  /// 走真实的内存 drift 库（与 `note_list_provider_test.dart` 同款）：本Task
  /// 的价值在「透传 + 派生」，用真库才能顺带钉住 DAO 的 `LEFT JOIN` 语义。
  /// 「0 笔记的文件夹仍在列表里」这条 AC 只有真库能证。
  setUp(() {
    db = AppDatabase.memory();
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// autoDispose 的 stream provider 靠 listener 续命 —— `read(p.future)` 会
  /// 立刻释放订阅并把provider 在 loading 态 dispose 掉。
  /// ⛔ 不写泛型 helper：`ProviderListenable` 在 Riverpod 3 未导出（只能从
  /// `package:riverpod/riverpod.dart` 见到 `ProviderListenableSelect` 等零散几个），
  /// 为两个 provider 引一个内部类型不划算。
  void keepAliveFolders() {
    final sub = container.listen<AsyncValue<List<FolderWithCount>>>(
      folderProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
  }

  void keepAliveUncategorized() {
    final sub = container.listen<AsyncValue<int>>(
      uncategorizedCountProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(sub.close);
  }

  Future<String> folderId(String name) async =>
      (await container.read(createFolderUseCaseProvider)(
        CreateFolderParams(name: name),
      )).fold(
        (_) => throw StateError('create folder $name failed'),
        (folder) => folder.id,
      );

  Future<void> note({String? folderId, String title = 'n'}) => container.read(
    createNoteUseCaseProvider,
  )(CreateNoteParams(title: title, content: '', folderId: folderId));

  group('folderProvider', () {
    test('透传 UseCase 的流：文件夹名 + 各自笔记数', () async {
      final id = await folderId('闻声笔记');
      await note(folderId: id);
      await note(); // 未分类

      keepAliveFolders();
      await pumpEventQueue();

      final list = container.read(folderProvider).value!;
      expect(list.single.folder.name, '闻声笔记');
      expect(list.single.count, 1);
    });

    test('0 笔记的文件夹仍在列表里，count = 0（LEFT JOIN 语义）', () async {
      await folderId('空文件夹');
      await note(title: '未分类的一条');

      keepAliveFolders();
      await pumpEventQueue();

      final list = container.read(folderProvider).value!;
      expect(list.length, 1);
      expect(list.single.folder.name, '空文件夹');
      expect(list.single.count, 0);
    });

    test('「全部」与「未分类」都不是流里的行（§5.3）', () async {
      await folderId('闻声笔记');
      await note();

      keepAliveFolders();
      await pumpEventQueue();

      final names = container
          .read(folderProvider)
          .value!
          .map((e) => e.folder.name);
      expect(names, <String>['闻声笔记']);
    });

    test('原样透传 UseCase 的顺序，不做二次排序', () async {
      // `CreateFolderUseCase` 用 `DateTime.now()`，同批建的两个文件夹
      // `createdAt` 必然相同 → `ORDER BY created_at ASC` 在 SQLite 里是**不稳定**
      // 的（实测单跑过 / 整跑挂）。排序归DAO 的 SQL（`folder_dao.dart:37`），
      // 本provider 只证明「拿到什么给什么」，故直接对 UseCase 的流断言。
      final useCase = _MockWatchFolderCountsUseCase();
      final ordered = <FolderWithCount>[
        FolderWithCount(folder: _folder('f1', '先建的'), count: 2),
        FolderWithCount(folder: _folder('f2', '后建的'), count: 0),
      ];
      when(() => useCase.call(any())).thenAnswer((_) => Stream.value(ordered));
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          watchFolderCountsUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen<AsyncValue<List<FolderWithCount>>>(
        folderProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await pumpEventQueue();

      expect(c.read(folderProvider).value, ordered);
    });

    test('空库时返回空列表，不抛异常', () async {
      keepAliveFolders();
      await pumpEventQueue();

      expect(container.read(folderProvider).value, isEmpty);
    });

    test('建文件夹后自动推送新列表（drift watch 的语义）', () async {
      final emissions = <List<FolderWithCount>>[];
      final sub = container.listen<AsyncValue<List<FolderWithCount>>>(
        folderProvider,
        (_, next) {
          final value = next.value;
          if (value != null) emissions.add(value);
        },
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await pumpEventQueue();

      await folderId('新建的');
      await pumpEventQueue();

      expect(emissions.last.single.folder.name, '新建的');
    });

    test('读库失败时落在 AsyncValue.hasError（不静默空列表）', () async {
      // 必须先写一行把连接打开 —— 对**从未打开过**的内存库调`close()` 是空操作，
      // 之后的 watch 会重新开一个库，测不到任何错误（与
      // `note_list_provider_test.dart` 同款前置条件）。
      await note();

      await db.close();

      keepAliveFolders();
      await pumpEventQueue();

      expect(container.read(folderProvider).hasError, isTrue);
    });
  });

  group('uncategorizedCountProvider', () {
    test('= 未分类笔记列表的长度（决策 A4）', () async {
      final id = await folderId('闻声笔记');
      await note(folderId: id);
      await note();
      await note();

      keepAliveUncategorized();
      await pumpEventQueue();

      expect(container.read(uncategorizedCountProvider).value, 2);
    });

    test('有分类的笔记不计入「未分类」', () async {
      final id = await folderId('闻声笔记');
      await note(folderId: id);
      for (var i = 0; i < 5; i++) {
        final other = await folderId('f$i');
        await note(folderId: other);
      }

      keepAliveUncategorized();
      await pumpEventQueue();

      expect(container.read(uncategorizedCountProvider).value, 0);
    });

    test('新建未分类笔记后计数自动 +1', () async {
      keepAliveUncategorized();
      await pumpEventQueue();
      expect(container.read(uncategorizedCountProvider).value, 0);

      await note();
      await pumpEventQueue();

      expect(container.read(uncategorizedCountProvider).value, 1);
    });

    test('未分类列表读库失败时同样落hasError', () async {
      await note();

      await db.close();

      keepAliveUncategorized();
      await pumpEventQueue();

      expect(container.read(uncategorizedCountProvider).hasError, isTrue);
    });
  });

  group('「全部」行的可求和性（文件夹管理稿: 1 + 154 = 155）', () {
    test('Σ 各文件夹 count + 未分类 = 全部', () async {
      final id = await folderId('闻声笔记');
      await note(folderId: id);
      await note();
      await note();

      keepAliveFolders();
      keepAliveUncategorized();
      await pumpEventQueue();

      final sum =
          container
              .read(folderProvider)
              .value!
              .fold<int>(0, (acc, e) => acc + e.count) +
          container.read(uncategorizedCountProvider).value!;

      expect(sum, 3);
    });
  });

  group('调用次数', () {
    test('同一query 只订阅一次上游（watch 而非多次 read）', () async {
      final useCase = _MockWatchFolderCountsUseCase();
      when(
        () => useCase.call(any()),
      ).thenAnswer((_) => const Stream<List<FolderWithCount>>.empty());
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          watchFolderCountsUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(c.dispose);

      final sub = c.listen<AsyncValue<List<FolderWithCount>>>(
        folderProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      await pumpEventQueue();

      c.read(folderProvider);
      c.read(folderProvider);
      await pumpEventQueue();

      verify(() => useCase.call(NoParams())).called(1);
    });
  });
}
