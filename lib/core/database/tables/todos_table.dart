import 'package:drift/drift.dart';

/// 待办表。实体见 `features/todos/domain/entities/todo.dart`。
///
/// 排序固定 `created_at DESC`（在 `TodoDao` 里做），不存 `sort_index`。
/// 待办稿「无日期、无优先级」→ 无 `due_date` / `priority` 列。
/// ⚠️ **有 `reminder_at`**：它不是「截止日期」，是提醒功能的触发点（可空 = 无提醒），
/// 由 v5 迁移加上 ——「无日期」指的是没有待办稿上不存在的截止日字段。
///
/// ## 删除语义
///
/// 软删除（`deleted_at`），与 `notes` 同形。删除必须能跨设备传播
/// （见 `BackupTodo.version`），硬删除不留痕。
/// 「清除已完成」也是软删除（`TodoDao.trashCompleted`），否则批量清空无法传播。
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

  /// 提醒时刻，null = 没设提醒。⛔ 不存「是否已提醒 / 是否已响铃」这类
  /// 通知侧状态 —— 那是 `flutter_local_notifications` 的事，库里只留用户意图。
  DateTimeColumn get reminderAt => dateTime().nullable()();

  /// 软删除时刻。null = 正常待办；非 null = 在回收站里。恢复即置回 null。
  ///
  /// ⚠️ 软删除**不**清 `reminder_at`：进回收站不等于取消提醒意图，
  /// 恢复后提醒仍在（撤掉已排的通知是平台侧的事，见 `TodoListScreen._cancelReminder`）。
  /// 物理 DELETE 只由回收站的「永久删除」发起。
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
