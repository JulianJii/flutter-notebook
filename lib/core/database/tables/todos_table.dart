import 'package:drift/drift.dart';

/// 待办表。实体见 `features/todos/domain/entities/todo.dart`。
///
/// 排序固定 `created_at DESC`（在 `TodoDao` 里做），不存 `sort_index`。
/// D2「无日期、无优先级」→ 无 `due_date` / `priority` / `reminder_at` 列。
@DataClassName('TodoRow')
class Todos extends Table {
  @override
  String get tableName => 'todos';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  TextColumn get title => text()();

  /// `BoolColumn` 而非 `IntColumn` —— 让 drift 处理 0/1 与 `bool` 的映射，
  /// DAO 与 datasource 里不出现手写转换。
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
