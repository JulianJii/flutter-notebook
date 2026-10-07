import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/usecases/usecase.dart';
import 'package:mynote/features/todos/domain/entities/todo.dart';
import 'package:mynote/features/todos/domain/repositories/todo_repository.dart';
import 'package:mynote/features/todos/domain/usecases/create_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/delete_completed_todos_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/delete_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/toggle_todo_params.dart';
import 'package:mynote/features/todos/domain/usecases/toggle_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/update_todo_params.dart';
import 'package:mynote/features/todos/domain/usecases/update_todo_use_case.dart';
import 'package:mynote/features/todos/domain/usecases/watch_todos_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

final DateTime _t1 = DateTime(2026, 8, 25);

final Todo _todo = Todo(
  id: 't1',
  title: '买牛奶',
  isDone: false,
  createdAt: _t1,
  updatedAt: _t1,
);

void main() {
  late MockTodoRepository repo;

  setUpAll(() {
    registerFallbackValue(_todo);
    registerFallbackValue(
      const ToggleTodoParams(
        todoId: 't',
        title: 'x',
        isDone: false,
        reminderAt: null,
      ),
    );
    registerFallbackValue(
      const UpdateTodoParams(
        todoId: 't',
        title: 'x',
        isDone: false,
        reminderAt: null,
      ),
    );
    registerFallbackValue(NoParams());
  });

  setUp(() {
    repo = MockTodoRepository();
  });

  /// 校验失败的断言：**既要 Left(InputFailure)，又要证明 Repository 没被碰过**。
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

  group('WatchTodosUseCase', () {
    test('原样返回 Repository 那个流实例', () {
      final stream = Stream.value([_todo]);
      when(() => repo.watchAll()).thenAnswer((_) => stream);
      expect(WatchTodosUseCase(repo)(NoParams()), same(stream));
    });
  });

  group('CreateTodoUseCase', () {
    test('#10 标题为空串 -> InputFailure 且不调 Repository', () {
      expectInputFailure(CreateTodoUseCase(repo)(''), repo);
    });

    test('#10 标题全是空格 -> InputFailure 且不调 Repository', () {
      expectInputFailure(CreateTodoUseCase(repo)('   '), repo);
    });

    test('成功：id 传空串、isDone 为 false、标题是 trim 后的值', () async {
      when(
        () => repo.create(any()),
      ).thenAnswer((_) async => Right<Failure, Todo>(_todo));
      expect(
        await CreateTodoUseCase(repo)('  买牛奶  '),
        Right<Failure, Todo>(_todo),
      );
      final captured =
          verify(() => repo.create(captureAny())).captured.single as Todo;
      expect(captured.id, '', reason: 'uuid 由 Repository 生成');
      expect(captured.isDone, isFalse);
      expect(captured.title, '买牛奶');
    });

    test('失败透传：Left(CacheFailure) 原样', () async {
      when(
        () => repo.create(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await CreateTodoUseCase(repo)('买牛奶');
      result.fold(
        (f) => expect((f as CacheFailure).message, 'disk full'),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('ToggleTodoUseCase', () {
    test('#11 空 todoId -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        ToggleTodoUseCase(repo)(
          const ToggleTodoParams(
            todoId: '',
            title: 'x',
            isDone: true,
            reminderAt: null,
          ),
        ),
        repo,
      );
    });

    test('目标值 true 原样落库（不是翻转）', () async {
      when(
        () => repo.update(any()),
      ).thenAnswer((_) async => Right<Failure, Todo>(_todo));
      await ToggleTodoUseCase(repo)(
        const ToggleTodoParams(
          todoId: 't1',
          title: '买牛奶',
          isDone: true,
          reminderAt: null,
        ),
      );
      final captured =
          verify(() => repo.update(captureAny())).captured.single as Todo;
      expect(captured.isDone, isTrue);
      expect(captured.title, '买牛奶');
      expect(captured.id, 't1');
    });

    test('目标值 false 原样落库（取消勾选）', () async {
      when(
        () => repo.update(any()),
      ).thenAnswer((_) async => Right<Failure, Todo>(_todo));
      await ToggleTodoUseCase(repo)(
        const ToggleTodoParams(
          todoId: 't1',
          title: '买牛奶',
          isDone: false,
          reminderAt: null,
        ),
      );
      final captured =
          verify(() => repo.update(captureAny())).captured.single as Todo;
      expect(captured.isDone, isFalse);
    });

    test('失败透传：Left 原样（UI 据此回滚乐观更新）', () async {
      when(
        () => repo.update(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await ToggleTodoUseCase(repo)(
        const ToggleTodoParams(
          todoId: 't1',
          title: 'x',
          isDone: true,
          reminderAt: null,
        ),
      );
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('UpdateTodoUseCase', () {
    test('空 todoId -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        UpdateTodoUseCase(repo)(
          const UpdateTodoParams(
            todoId: '',
            title: 'x',
            isDone: false,
            reminderAt: null,
          ),
        ),
        repo,
      );
    });

    test('空标题 -> InputFailure 且不调 Repository', () {
      expectInputFailure(
        UpdateTodoUseCase(repo)(
          const UpdateTodoParams(
            todoId: 't1',
            title: '   ',
            isDone: false,
            reminderAt: null,
          ),
        ),
        repo,
      );
    });

    test('成功：标题为 trim 后值，isDone 原样', () async {
      when(
        () => repo.update(any()),
      ).thenAnswer((_) async => Right<Failure, Todo>(_todo));
      await UpdateTodoUseCase(repo)(
        const UpdateTodoParams(
          todoId: 't1',
          title: '  写周报 ',
          isDone: true,
          reminderAt: null,
        ),
      );
      final captured =
          verify(() => repo.update(captureAny())).captured.single as Todo;
      expect(captured.title, '写周报');
      expect(captured.isDone, isTrue);
    });

    test('失败透传：Left 原样', () async {
      when(
        () => repo.update(any()),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await UpdateTodoUseCase(repo)(
        const UpdateTodoParams(
          todoId: 't1',
          title: 'x',
          isDone: false,
          reminderAt: null,
        ),
      );
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('DeleteTodoUseCase', () {
    test('#12 空 todoId -> InputFailure 且不调 Repository', () {
      expectInputFailure(DeleteTodoUseCase(repo)(''), repo);
    });

    test('成功：原样透传', () async {
      when(() => repo.delete('t1')).thenAnswer((_) async => const Right(unit));
      expect(
        await DeleteTodoUseCase(repo)('t1'),
        const Right<Failure, Unit>(unit),
      );
      verify(() => repo.delete('t1')).called(1);
    });

    test('失败透传：Left 原样', () async {
      when(
        () => repo.delete('nope'),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'not found')));
      final result = await DeleteTodoUseCase(repo)('nope');
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });

  group('DeleteCompletedTodosUseCase', () {
    test('成功：原样透传删除行数', () async {
      when(
        () => repo.deleteCompleted(),
      ).thenAnswer((_) async => const Right(2));
      expect(
        await DeleteCompletedTodosUseCase(repo)(),
        const Right<Failure, int>(2),
      );
      verify(() => repo.deleteCompleted()).called(1);
    });

    test('0 行不是失败（已经清空）', () async {
      when(
        () => repo.deleteCompleted(),
      ).thenAnswer((_) async => const Right(0));
      expect(
        await DeleteCompletedTodosUseCase(repo)(),
        const Right<Failure, int>(0),
      );
    });

    test('失败透传：Left 原样', () async {
      when(
        () => repo.deleteCompleted(),
      ).thenAnswer((_) async => const Left(CacheFailure(message: 'disk full')));
      final result = await DeleteCompletedTodosUseCase(repo)();
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('应为 Left'),
      );
    });
  });
}
