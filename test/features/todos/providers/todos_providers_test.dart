import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:init/core/database/app_database.dart';
import 'package:init/core/providers/database_providers.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/core/usecases/usecase.dart';
import 'package:init/features/todos/data/datasources/todo_local_data_source.dart';
import 'package:init/features/todos/domain/repositories/todo_repository.dart';
import 'package:init/features/todos/domain/usecases/create_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/delete_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/toggle_todo_params.dart';
import 'package:init/features/todos/domain/usecases/toggle_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/update_todo_use_case.dart';
import 'package:init/features/todos/domain/usecases/watch_todos_use_case.dart';
import 'package:init/features/todos/providers/todos_providers.dart';
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

  test('data source + repository 可解析', () {
    expect(
      container.read(todoLocalDataSourceProvider),
      isA<TodoLocalDataSource>(),
    );
    expect(container.read(todoRepositoryProvider), isA<TodoRepository>());
  });

  test('5 个 use case provider 全部可解析', () {
    expect(container.read(watchTodosUseCaseProvider), isA<WatchTodosUseCase>());
    expect(container.read(createTodoUseCaseProvider), isA<CreateTodoUseCase>());
    expect(container.read(toggleTodoUseCaseProvider), isA<ToggleTodoUseCase>());
    expect(container.read(updateTodoUseCaseProvider), isA<UpdateTodoUseCase>());
    expect(container.read(deleteTodoUseCaseProvider), isA<DeleteTodoUseCase>());
  });

  test('端到端：create -> watchAll -> toggle 目标值落库', () async {
    final created = await container.read(createTodoUseCaseProvider)('买牛奶');
    final todo = created.fold((f) => null, (t) => t);
    expect(todo, isNotNull, reason: 'create 应返回 Right');
    expect(todo!.isDone, isFalse);

    await container.read(toggleTodoUseCaseProvider)(
      ToggleTodoParams(todoId: todo.id, title: todo.title, isDone: true),
    );

    final all = await container
        .read(watchTodosUseCaseProvider)(NoParams())
        .first;
    expect(all.single.isDone, isTrue);
  });
}
