import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/features/notes/domain/entities/note_query.dart';
import 'package:mynote/features/notes/domain/usecases/create_folder_params.dart';
import 'package:mynote/features/notes/domain/usecases/create_note_params.dart';
import 'package:mynote/features/notes/providers/notes_providers.dart';
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

  test('端到端：create -> watch（走 ProviderContainer 的完整链路）', () async {
    // 文件夹与笔记各走一遍：DI 装错线（接错 data source / repository）只有真链路
    // 才测得出来，`isA<X>()` 那种类型断言是编译期就定死的，测不出东西。
    final folder = await container.read(createFolderUseCaseProvider)(
      const CreateFolderParams(name: '词声笔记'),
    );
    final folderId = folder.fold((f) => null, (v) => v.id);
    expect(folderId, isNotNull);

    final created = await container.read(createNoteUseCaseProvider)(
      CreateNoteParams(title: '来自容器', content: '正文', folderId: folderId),
    );
    final note = created.fold((f) => null, (n) => n);
    expect(note, isNotNull, reason: 'create 应返回 Right');
    expect(note!.id, isNotEmpty, reason: 'uuid 由 Repository 生成');

    final notes = await container
        .read(watchNotesUseCaseProvider)(NoteQuery.of(folderId!))
        .first;
    expect(notes.single.id, note.id);
  });
}
