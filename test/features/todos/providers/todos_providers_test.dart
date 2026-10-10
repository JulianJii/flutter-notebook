import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/providers/database_providers.dart';
import 'package:mynote/core/providers/storage_providers.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/todos/domain/usecases/toggle_todo_params.dart';
import 'package:mynote/features/todos/providers/todos_providers.dart';
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

  test('端到端：create -> watchAll -> toggle 目标值落库', () async {
    final created = await container.read(createTodoUseCaseProvider)('买牛奶');
    final todo = created.fold((f) => null, (t) => t);
    expect(todo, isNotNull, reason: 'create 应返回 Right');
    expect(todo!.isDone, isFalse);

    await container.read(toggleTodoUseCaseProvider)(
      ToggleTodoParams(
        todoId: todo.id,
        title: todo.title,
        isDone: true,
        reminderAt: null,
      ),
    );

    final all = await container
        .read(watchTodosUseCaseProvider)(NoParams())
        .first;
    expect(all.single.isDone, isTrue);
  });
}
