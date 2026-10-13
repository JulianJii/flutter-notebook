import 'package:drift/drift.dart';

import 'notes_table.dart';

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

  /// **永久删除的墓碑时刻**。语义同 `notes.purged_at`：回收站的「永久删除」写这一列
  /// 而不物理 DELETE，否则 A 机删掉的待办会在 B 机下次同步时原样回来。
  /// 物理删除由保留期清扫在墓碑过期后做。
  DateTimeColumn get purgedAt => dateTime().nullable()();

  /// 优先级。**数值越大越靠前**（`TodoPriority` 是有序枚举，0 = 普通）。
  ///
  /// 存 int 而不是文本：排序要的是比较而不是显示，而排序在 SQL 里做
  /// （`TodoDao.watchAll`），文本枚举每次比较都要 `CASE WHEN`，而 drift 的
  /// `BoolColumn` 只有两档表达不了三档。
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// 重复规则的稳定 id（`TodoRecurrence.id`）。null = 不重复（绝大多数待办）。
  ///
  /// ⛔ 存 id 字符串而非 `FREQ=` 那种 RRULE 片段：只支持三种，写解析器、
  /// 校验语法、还要处理「不支持的 RRULE」这种分支，全是为了一个我们自己
  /// 不会生成的输入。真要支持任意 RRULE 时换掉这一列（迁移只影响本列）。
  TextColumn get recurrence => text().nullable()();

  /// 挂接的笔记 id（一对一，可空 = 未挂接，绝大多数待办）。
  ///
  /// ⚠️ 只存「挂上」这个用户意图，**不做双向反查列**：笔记侧的关联待办由
  /// `todos.linked_note_id` 反向查询（索引见迁移）。外键 `ON DELETE SET NULL`
  /// 在笔记被保留期物理清扫时自动摘掉挂接；软删除不清它 —— 进回收站不等于
  /// 笔记消失，恢复后挂接仍在。
  ///
  /// SET NULL 不刷 `todos.updated_at`，该变更不跨设备传播：对端可能仍挂着
  /// 一个已被清扫的笔记 id，跳转时由 UI 兜底提示（见 `TodoCard`）。
  TextColumn get linkedNoteId => text().nullable().references(
    Notes,
    #id,
    onDelete: KeyAction.setNull,
  )();
}
