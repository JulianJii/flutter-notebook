import 'package:drift/drift.dart' show DriftWrappedException, Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/database/daos/todo_subtask_dao.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/core/utils/app_clock.dart';
import 'package:mynote/features/todos/domain/entities/todo_subtask.dart';

/// 子项的数据源。⛔ 不 import Flutter、不做 Exception → Failure。
///
/// 父子关系由**外键**保证（`todo_subtasks.todo_id → todos.id ON DELETE CASCADE`），
/// 所以这里**不**做「父还在不在」的检查 —— 那是一次多余的查询，而写不进去时
/// SQLite 会用外键约束自己拦（`PRAGMA foreign_keys = ON` 在 `beforeOpen` 里）。
abstract class TodoSubtaskLocalDataSource {
  /// 某条待办的子项，按加入顺序。⛔ 不过滤父待办的删除态 —— 见 DAO 注释。
  Stream<List<TodoSubtask>> watchByTodo(String todoId);

  Future<void> insert(TodoSubtask subtask);

  /// 局部更新（勾选 / 改标题），**必须刷 `updated_at`** —— 那是跨设备合并的键。
  Future<void> update(TodoSubtask subtask);

  Future<void> delete(String subtaskId);
}

class TodoSubtaskLocalDataSourceImpl implements TodoSubtaskLocalDataSource {
  TodoSubtaskLocalDataSourceImpl(this._dao);

  final TodoSubtaskDao _dao;

  @override
  Stream<List<TodoSubtask>> watchByTodo(String todoId) {
    return _guardStream(
      _dao.watchByTodo(todoId).map(
        (rows) => rows.map(_toEntity).toList(),
      ),
    );
  }

  @override
  Future<void> insert(TodoSubtask subtask) => _guard(() async {
    await _dao.insert(
      TodoSubtasksCompanion.insert(
        id: subtask.id,
        todoId: subtask.todoId,
        title: subtask.title,
        createdAt: subtask.createdAt,
        updatedAt: subtask.updatedAt,
        isDone: Value(subtask.isDone),
      ),
    );
  });

  @override
  Future<void> update(TodoSubtask subtask) => _guard(() async {
    final hit = await _dao.updateById(
      TodoSubtasksCompanion(
        id: Value(subtask.id),
        title: Value(subtask.title),
        isDone: Value(subtask.isDone),
        // ⚠️ **必须刷**：不刷的话 A 机勾完同步过去，B 机那条更老，会被判成本地
        // 胜出并把勾选抹掉 —— 静默丢数据，且只在两台设备之间来回同步才显形。
        updatedAt: Value(subtask.updatedAt),
      ),
    );
    if (!hit) {
      throw CacheException(message: 'Subtask not found: ${subtask.id}');
    }
  });

  @override
  Future<void> delete(String subtaskId) => _guard(() async {
    final removed = await _dao.deleteById(subtaskId);
    if (removed == 0) {
      throw CacheException(message: 'Subtask not found: $subtaskId');
    }
  });
}

/// drift 行 → 领域实体的直连（⛔ 不建 Model 层）。
TodoSubtask _toEntity(TodoSubtaskRow row) {
  return TodoSubtask(
    id: row.id,
    todoId: row.todoId,
    title: row.title,
    isDone: row.isDone,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

/// 子项没有「读库失败要重新查询」的场景（它不是任何列表的数据源），故不需要
/// 这个带时间戳兜底的工厂 —— 插入时的时间戳由调用方给（Repository 用
/// [AppClock]），DAO 不取时钟。
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

Stream<T> _guardStream<T>(Stream<T> source) {
  return source.handleError((Object e) {
    if (e is CacheException) throw e;
    if (e is SqliteException) throw CacheException(message: e.message);
    if (e is DriftWrappedException) throw CacheException(message: e.message);
    throw CacheException(message: e.toString());
  });
}