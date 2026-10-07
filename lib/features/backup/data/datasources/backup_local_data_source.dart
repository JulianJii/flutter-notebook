import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';

/// 三张表 ↔ [BackupSnapshot] 的双向通道。
///
/// ⛔ 不 import Flutter、不做 Exception → Failure（那是 Repository 的活）。
/// drift 的 `SqliteException` / `DriftWrappedException` 在出口处包成
/// `CacheException`（与另三个 datasource 同约定：SQL 细节不往外漏）。
///
/// 写入顺序**必须是 folders → notes → todos**：`notes.folder_id` 有外键且
/// `PRAGMA foreign_keys = ON`，快照里指向本地不存在文件夹的 `folderId` 会在
/// 写 folders 之后被清洗成 null（见 [_writeNotes]）。
class BackupLocalDataSource {
  BackupLocalDataSource(this._db);

  final AppDatabase _db;

  /// 全量读。**含回收站里的软删除笔记** —— 删除也是数据，不同步过去的话，
  /// 换台设备就会看到「删掉的笔记又回来了」。
  Future<BackupSnapshot> read() => _guard(() async {
    final notes = await _db.select(_db.notes).get();
    final folders = await _db.select(_db.noteFolders).get();
    final todos = await _db.select(_db.todos).get();

    return BackupSnapshot(
      exportedAt: DateTime.now(),
      notes: <BackupNote>[
        for (final row in notes)
          BackupNote(
            id: row.id,
            title: row.title,
            content: row.content,
            folderId: row.folderId,
            background: row.background,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt,
          ),
      ],
      folders: <BackupFolder>[
        for (final row in folders)
          BackupFolder(
            id: row.id,
            name: row.name,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            sortIndex: row.sortIndex,
          ),
      ],
      todos: <BackupTodo>[
        for (final row in todos)
          BackupTodo(
            id: row.id,
            title: row.title,
            isDone: row.isDone,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
      ],
    );
  });

  /// 写回一份**已合并**的快照，返回因文件夹重名而跳过的条数。
  ///
  /// 新增 / 更新计数不在这里算 —— 它们由 `BackupSnapshot.merge` 得出（合并时
  /// 才知道谁赢了），这里只补充「写完才发现写不进去」的那部分。
  ///
  /// 全量写、不做逐行 diff：写入的值与库里相同时 SQLite 只是重写一遍同样的
  /// 字节，`updated_at` 不变，列表排序不会抖。为省这点 IO 去读一遍全部行做
  /// 比较，是拿复杂度换零收益。
  Future<int> write(BackupSnapshot snapshot) => _guard(() async {
    var skipped = 0;
    await _db.transaction(() async {
      skipped = await _writeFolders(snapshot.folders);
      final knownFolderIds = await _knownFolderIds();
      await _writeNotes(snapshot.notes, knownFolderIds);
      await _writeTodos(snapshot.todos);
    });
    return skipped;
  });

  /// 文件夹逐条写，不用 batch：`name` 是 UNIQUE，跨设备各自新建同名文件夹会
  /// 撞约束，得逐条改名重试（batch 里拿不到「哪一条撞了」）。
  Future<int> _writeFolders(List<BackupFolder> folders) async {
    final existing = await _db.select(_db.noteFolders).get();
    final existingIds = <String>{for (final row in existing) row.id};

    var skipped = 0;
    for (final folder in folders) {
      final exists = existingIds.contains(folder.id);
      var ok = await _tryWriteFolder(folder, folder.name, exists);
      if (!ok) {
        // UNIQUE(name) 撞车。改名而不是丢弃 —— 用户的文件夹不能因为两台设备
        // 想到同一个名字就少一个。仍撞（第三个同名）才计入 skipped，由 UI 报出。
        ok = await _tryWriteFolder(folder, '${folder.name} (2)', exists);
      }
      if (!ok) skipped++;
    }
    return skipped;
  }

  /// ⚠️ 必须 `async` + `await`：`try` 套一个**未 await 的 Future** 抓不到它的
  /// 错误（UNIQUE 冲突会在 Future 里抛出，同步 catch 拦不住）。
  Future<bool> _tryWriteFolder(
    BackupFolder folder,
    String name,
    bool exists,
  ) async {
    final row = NoteFoldersCompanion(
      id: Value(folder.id),
      name: Value(name),
      createdAt: Value(folder.createdAt),
      updatedAt: Value(folder.updatedAt),
      sortIndex: Value(folder.sortIndex),
    );
    try {
      if (exists) {
        final affected = await (_db.update(
          _db.noteFolders,
        )..where((t) => t.id.equals(folder.id))).write(row);
        return affected > 0;
      }
      await _db.into(_db.noteFolders).insert(row);
      return true;
    } on SqliteException {
      return false;
    }
  }

  /// 写 folders 之后重新读一次存在的 id：快照里的 `folderId` 可能指向一个
  /// 对端还留着、本地已永久删除的文件夹 —— 外键开着，写进去会整批失败。
  Future<Set<String>> _knownFolderIds() async {
    final rows = await _db.select(_db.noteFolders).get();
    return <String>{for (final row in rows) row.id};
  }

  Future<void> _writeNotes(List<BackupNote> notes, Set<String> folderIds) {
    return _db.batch((batch) {
      for (final note in notes) {
        batch.insert(
          _db.notes,
          NotesCompanion(
            id: Value(note.id),
            title: Value(note.title),
            content: Value(note.content),
            folderId: Value(
              note.folderId != null && folderIds.contains(note.folderId)
                  ? note.folderId
                  : null,
            ),
            createdAt: Value(note.createdAt),
            updatedAt: Value(note.updatedAt),
            deletedAt: Value(note.deletedAt),
            background: Value(note.background),
          ),
          // `insertOrReplace`：主键撞车时整行替换。两张表都只按主键判重
          // （`note_folders.name` 的 UNIQUE 由 [_writeFolders] 逐条处理），
          // 所以「替换」等于「用合并后的胜出行覆盖」，不会误伤别的行。
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _writeTodos(List<BackupTodo> todos) {
    return _db.batch((batch) {
      for (final todo in todos) {
        batch.insert(
          _db.todos,
          TodosCompanion(
            id: Value(todo.id),
            title: Value(todo.title),
            isDone: Value(todo.isDone),
            createdAt: Value(todo.createdAt),
            updatedAt: Value(todo.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 读库失败的统一出口：`SqliteException` / `DriftWrappedException` →
  /// `CacheException`。与另三个 datasource 的 `_guard` 同形。
  ///
  /// ⚠️ 不消化 UNIQUE 冲突：那由 [_tryWriteFolder] 就地判成 `false`（重名改名，
  /// 不是失败），走到这里的异常都是真的读写失败。
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
}
