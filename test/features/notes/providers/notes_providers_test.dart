import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/database/app_database.dart';
import 'package:init/core/providers/database_providers.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/features/notes/data/datasources/folder_local_data_source.dart';
import 'package:init/features/notes/data/datasources/note_local_data_source.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';
import 'package:init/features/notes/domain/repositories/folder_repository.dart';
import 'package:init/features/notes/domain/repositories/note_repository.dart';
import 'package:init/features/notes/domain/usecases/create_folder_use_case.dart';
import 'package:init/features/notes/domain/usecases/create_note_params.dart';
import 'package:init/features/notes/domain/usecases/create_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/delete_folder_use_case.dart';
import 'package:init/features/notes/domain/usecases/delete_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/get_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/rename_folder_use_case.dart';
import 'package:init/features/notes/domain/usecases/update_note_background_use_case.dart';
import 'package:init/features/notes/domain/usecases/update_note_use_case.dart';
import 'package:init/features/notes/domain/usecases/watch_folder_counts_use_case.dart';
import 'package:init/features/notes/domain/usecases/watch_notes_use_case.dart';
import 'package:init/features/notes/providers/notes_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('2 个 data source + 2 个 repository 可解析', () {
    expect(
      container.read(noteLocalDataSourceProvider),
      isA<NoteLocalDataSource>(),
    );
    expect(
      container.read(folderLocalDataSourceProvider),
      isA<FolderLocalDataSource>(),
    );
    expect(container.read(noteRepositoryProvider), isA<NoteRepository>());
    expect(container.read(folderRepositoryProvider), isA<FolderRepository>());
  });

  test('10 个 use case provider 全部可解析且无状态', () {
    expect(container.read(watchNotesUseCaseProvider), isA<WatchNotesUseCase>());
    expect(container.read(getNoteUseCaseProvider), isA<GetNoteUseCase>());
    expect(container.read(createNoteUseCaseProvider), isA<CreateNoteUseCase>());
    expect(container.read(updateNoteUseCaseProvider), isA<UpdateNoteUseCase>());
    expect(
      container.read(updateNoteBackgroundUseCaseProvider),
      isA<UpdateNoteBackgroundUseCase>(),
    );
    expect(container.read(deleteNoteUseCaseProvider), isA<DeleteNoteUseCase>());
    expect(
      container.read(watchFolderCountsUseCaseProvider),
      isA<WatchFolderCountsUseCase>(),
    );
    expect(
      container.read(createFolderUseCaseProvider),
      isA<CreateFolderUseCase>(),
    );
    expect(
      container.read(renameFolderUseCaseProvider),
      isA<RenameFolderUseCase>(),
    );
    expect(
      container.read(deleteFolderUseCaseProvider),
      isA<DeleteFolderUseCase>(),
    );
  });

  test('同一依赖被复用：datasource provider 只造一次', () {
    expect(
      container.read(noteLocalDataSourceProvider),
      same(container.read(noteLocalDataSourceProvider)),
    );
    expect(
      container.read(noteRepositoryProvider),
      same(container.read(noteRepositoryProvider)),
    );
  });

  test('端到端：create -> watch（走 ProviderContainer 的完整链路）', () async {
    final created = await container.read(createNoteUseCaseProvider)(
      const CreateNoteParams(title: '来自容器', content: '正文'),
    );
    final note = created.fold((f) => null, (n) => n);
    expect(note, isNotNull, reason: 'create 应返回 Right');
    expect(note!.id, isNotEmpty, reason: 'uuid 由 Repository 生成');

    final notes = await container
        .read(watchNotesUseCaseProvider)(const NoteQuery())
        .first;
    expect(notes.single.id, note.id);
  });
}
