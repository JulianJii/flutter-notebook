import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:init/core/database/tables/note_folders_table.dart';
import 'package:init/core/database/tables/notes_table.dart';
import 'package:init/core/database/tables/todos_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// 全 App 唯一的 SQLite 出入口。不是 feature，不含业务语义。
///
/// `schemaVersion = 1`，v1 无历史数据 → **不写 `onUpgrade`**
/// （第一次 schema 变更时再建，且必须同时加迁移测试）。
/// ⛔ 严禁 `NativeDatabase.deleteDatabase` 删库重建（产品原则 4「永不丢数据」）。
///
/// 三张表（`notes` / `note_folders` / `todos`）在 `@DriftDatabase` 注解里声明，
/// drift 同时在本文件的 part 里生成 `NoteRow` / `NoteFolderRow` / `TodoRow`
/// 三个行类与对应 companion。
@DriftDatabase(tables: [Notes, NoteFolders, Todos])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 内存库构造，供 `TASK-018~024` 的测试使用（零新依赖）。
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
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
