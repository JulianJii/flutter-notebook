import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mynote/core/database/tables/note_folders_table.dart';
import 'package:mynote/core/database/tables/notes_table.dart';
import 'package:mynote/core/database/tables/todo_subtasks_table.dart';
import 'package:mynote/core/database/tables/todos_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 全 App 唯一的 SQLite 出入口。不是 feature，不含业务语义。
///
/// `schemaVersion = 6`：v1 → v2 给 `notes` 加 `deleted_at` 列（软删除，见
/// `notes_table.dart` 头注）；v2 → v3 加 `background` 列（笔记纸张背景，
/// 可空 = 无背景）；v3 → v4 给 `note_folders` 加 `sort_index` 列（文件夹管理拖拽排序）；
/// v4 → v5 给 `todos` 加 `reminder_at` 列（待办提醒时刻，可空 = 无提醒）；
/// v5 → v6 给 `note_folders` 与 `todos` 加 `deleted_at` 列（**软删除**，
/// 让删除能跨设备传播 —— 硬删除不留痕，见两张表的类注释）；
/// v6 → v7 做两件事：① 三张表各加 `purged_at`（「永久删除」的墓碑，见各表列注释），
/// 否则 A 机永久删的笔记会在 B 机下次同步时复活；② `notes` 加 `is_pinned` /
/// `is_favorite` 两个置位布尔列，老数据默认 false = 都不置顶不收藏；
/// v7 → v8 加待办的 `priority`（默认 0 = 普通）与 `recurrence`（null = 不重复），
/// 并**新建** `todo_subtasks` 表（子任务，有自己的主键与外键）；
/// v8 → v9 给 `notes` 加 `editor_font_id` 列（每篇笔记的编辑器字体 id，可空 =
/// 系统默认，见 `notes_table.dart` 的列注释）。
/// ⛔ 严禁 `NativeDatabase.deleteDatabase` 删库重建（产品原则 4「永不丢数据」）。
///
/// 三张表（`notes` / `note_folders` / `todos`）在 `@DriftDatabase` 注解里声明，
/// drift 同时在本文件的 part 里生成 `NoteRow` / `NoteFolderRow` / `TodoRow`
/// 三个行类与对应 companion。
@DriftDatabase(tables: [Notes, NoteFolders, Todos, TodoSubtasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 内存库构造，供 `TASK-018~024` 的测试使用（零新依赖）。
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v1 → v2：`notes` 加软删除列。老数据的 `deleted_at` 为 null =
      // 正常笔记，无需回填。
      if (from < 2) {
        await m.addColumn(notes, notes.deletedAt);
      }
      // v2 → v3：`notes` 加背景列。老数据的 `background` 为 null = 无背景，
      // 无需回填。
      if (from < 3) {
        await m.addColumn(notes, notes.background);
      }
      // v3 → v4：`note_folders` 加排序位。老数据默认 0，排序的兜底列是
      // `created_at` → 顺序与升级前完全一致，无需回填。
      if (from < 4) {
        await m.addColumn(noteFolders, noteFolders.sortIndex);
      }
      // v4 → v5：`todos` 加提醒时刻。老数据为 null = 没设提醒，无需回填。
      if (from < 5) {
        await m.addColumn(todos, todos.reminderAt);
      }
      // v5 → v6：文件夹与待办改软删除。老数据为 null = 未删除，与升级前的
      // 「全部可见」视图一致，**无需回填**。
      if (from < 6) {
        await m.addColumn(noteFolders, noteFolders.deletedAt);
        await m.addColumn(todos, todos.deletedAt);
      }
      // v6 → v7：永久删除的墓碑列。老数据为 null = 从未被永久删除过，与升级前
      // 「回收站里的行会真的消失」这个状态等价，**无需回填**。
      // 同批加的两个置位布尔列默认值 false = 都不置顶不收藏。
      if (from < 7) {
        await m.addColumn(notes, notes.purgedAt);
        await m.addColumn(noteFolders, noteFolders.purgedAt);
        await m.addColumn(todos, todos.purgedAt);
        await m.addColumn(notes, notes.isPinned);
        await m.addColumn(notes, notes.isFavorite);
      }
      // v7 → v8：待办优先级 / 重复规则 + 子任务表。
      // 老数据 priority = 0（普通）、recurrence = null（不重复），与升级前的
      // 「待办稿只有标题和完成态」一致，**无需回填**。
      // `todo_subtasks` 是新表：drift 的 `onCreate` 会建它，`onUpgrade` 里
      // **不能**用 `m.createTable`（新装的用户走 onCreate，升级的走 onUpgrade，
      // 两条路都要有 —— createAll 在 onCreate 里已覆盖，这里只为老库补建）。
      if (from < 8) {
        await m.addColumn(todos, todos.priority);
        await m.addColumn(todos, todos.recurrence);
        await m.createTable(todoSubtasks);
      }
      // v8 → v9：`notes` 加编辑器字体列。老数据为 null = 系统默认字体，与升级前
      // 「正文的族名由工具栏按选中范围写在 Delta 里」共存，**无需回填**
      // （Delta 里已有的 font 属性照旧渲染）。
      if (from < 9) {
        await m.addColumn(notes, notes.editorFontId);
      }
    },
    beforeOpen: (details) async {
      // SQLite 默认关闭外键强制。不开这个，notes.folder_id 的
      // ON DELETE SET NULL 不生效（删文件夹会失败或留下悬挂引用）。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // ⚠️ 故意**不**覆写 `customConstraints` / `primaryKey` / `allSchemaEntities`
  //    这类全局钩子 —— 它们供自定义 SQL 与手写 schema 使用，覆写会破坏 drift
  //    生成的表与 accessor。

  /// 生产用连接：lazy 打开 + 后台 isolate。
  ///
  /// ponytail: 单连接，无并发读，故不设 `PRAGMA journal_mode = WAL`（收益为零，
  /// 多一处版本差异）。若将来上多 isolate 并发读，WAL 才是真场景，再加。
  static QueryExecutor openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'notes.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
