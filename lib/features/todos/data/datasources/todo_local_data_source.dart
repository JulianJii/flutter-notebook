import 'package:drift/drift.dart' show DriftWrappedException, Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:init/core/database/app_database.dart';
import 'package:init/core/database/daos/todo_dao.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/features/todos/domain/entities/todo.dart';

/// 待办的本地数据源。D2 是一张平铺列表：⛔ 无筛选、无搜索、无分页、无排序入口
/// （`created_at DESC` 在 [TodoDao] 的 SQL 里排完，这里不二次排序）。
abstract class TodoLocalDataSource {
  /// 订阅全量待办。
  ///
  /// 错误传播：drift 的 watch 不在流里抛同步异常；读库失败以
  /// `Stream.error(CacheException)` 出现，由 Repository 映射为 `CacheFailure`，
  /// UI 侧只会看到 `AsyncValue.error(CacheFailure)`。
  Stream<List<Todo>> watchAll();

  /// 插入。[Todo.id] 必须已由 Repository 填好 uuid。
  Future<Todo> insert(Todo todo);

  /// 更新。命中 0 行 → 抛 [CacheException]。勾选切换复用本方法（传目标 `isDone`）。
  Future<Todo> update(Todo todo);

  /// 删除。命中 0 行 → 抛 [CacheException]。
  Future<void> delete(String todoId);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  /// [dao] 是可选命名参数：测试可注入 mock DAO 断言参数翻译。
  /// 持有 [AppDatabase] 是为了 [update] 的回读（`createdAt` 不写、调用方也给不出）。
  TodoLocalDataSourceImpl(this._db, {TodoDao? dao})
    : _dao = dao ?? TodoDao(_db);

  final AppDatabase _db;
  final TodoDao _dao;

  @override
  Stream<List<Todo>> watchAll() {
    return _dao.watchAll().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Todo> insert(Todo todo) => _guard(() async {
    final row = await _dao.insert(
      TodosCompanion.insert(
        id: todo.id,
        title: todo.title,
        isDone: Value(todo.isDone),
        createdAt: todo.createdAt,
        updatedAt: todo.updatedAt,
      ),
    );
    return _toEntity(row);
  });

  @override
  Future<Todo> update(Todo todo) => _guard(() async {
    // ⛔ createdAt **不写**：乐观更新会带着「旧快照」调本方法，写了它会让
    // 待办在 `createdAt DESC` 的列表里跳位（`todo_dao_test` 已钉住）。
    final hit = await _dao.updateById(
      TodosCompanion(
        id: Value(todo.id),
        title: Value(todo.title),
        isDone: Value(todo.isDone),
        updatedAt: Value(todo.updatedAt),
      ),
    );
    if (!hit) {
      throw CacheException(message: 'Todo not found: ${todo.id}');
    }
    // 回读：入参的 createdAt 是调用方给的（`ToggleTodoUseCase` 没有时间戳参数），
    // 不是库里的值。回读让返回的实体与库保持一致。
    final row = await _read(todo.id);
    if (row == null) {
      throw CacheException(message: 'Todo not found: ${todo.id}');
    }
    return _toEntity(row);
  });

  @override
  Future<void> delete(String todoId) => _guard(() async {
    final removed = await _dao.deleteById(todoId);
    if (removed == 0) {
      throw CacheException(message: 'Todo not found: $todoId');
    }
  });

  /// 更新后回读单行。`TodoDao` 没有 `getById`，而 `createdAt` 既不写、调用方也
  /// 给不出 —— 不回读就得把一个假时间戳交给上层。用 drift DSL 单表查询，
  /// 不新增 DAO 方法（DAO 是 `TASK-020` 的产物，本轮不改）。
  Future<TodoRow?> _read(String todoId) {
    return (_db.select(
      _db.todos,
    )..where((t) => t.id.equals(todoId))).getSingleOrNull();
  }
}

/// drift 行 → 领域实体的**直连**（⛔ 不建 Model 层）。
/// `isDone` 由 drift 的 `boolean()` 负责 0/1 ↔ bool，⛔ 不手写 `== 1`。
Todo _toEntity(TodoRow row) {
  return Todo(
    id: row.id,
    title: row.title,
    isDone: row.isDone,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

/// 读库失败的统一边界：`SqliteException` / `DriftWrappedException` → [CacheException]。
/// `CacheException` 走 `rethrow`，不二次包装；**不**转成 `Failure`（Repository 的活）。
Future<T> _guard<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on CacheException {
    rethrow;
  } on SqliteException catch (e) {
    throw CacheException(message: e.message);
  } on DriftWrappedException catch (e) {
    throw CacheException(message: e.message);
  } on Exception catch (e) {
    throw CacheException(message: e.toString());
  }
}
