import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/error/exceptions.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';
import 'package:mynote/features/todos/domain/entities/todo_priority.dart';

/// 七张表 ↔ [BackupSnapshot] 的双向通道。
///
/// ⛔ 不 import Flutter、不做 Exception → Failure（那是 Repository 的活）。
/// drift 的 `SqliteException` / `DriftWrappedException` 在出口处包成
/// `CacheException`（与另三个 datasource 同约定：SQL 细节不往外漏）。
///
/// 写入顺序**必须是 folders → notes → todos → 子项 → tags → versions → links**
/// （外键约束 + `PRAGMA foreign_keys = ON`）：`notes.folder_id` 指向本地不存在
/// 文件夹的行会被清洗成 null（见 [_writeNotes]）；`note_tag_links` 的两个外键
/// 分别指向 notes 与 note_tags，必须最后写（见 [_writeNoteTagLinks]）。
class BackupLocalDataSource {
  BackupLocalDataSource(this._db);

  final AppDatabase _db;

  /// 全量读。**含回收站里的软删除笔记与已永久删除的墓碑行** —— 删除也是数据，
  /// 不同步过去的话，换台设备就会看到「删掉的笔记又回来了」。
  ///
  /// ⚠️ 墓碑行**必须**读出来：它们是「永久删除」能跨设备传播的唯一载体。
  /// 这里若加一个 `purged_at IS NULL` 过滤，删除就静默退化成 v2 的行为。
  Future<BackupSnapshot> read() => _guard(() async {
    final notes = await _db.select(_db.notes).get();
    final folders = await _db.select(_db.noteFolders).get();
    final todos = await _db.select(_db.todos).get();
    final subtasks = await _db.select(_db.todoSubtasks).get();
    // 三张新表同样**全量读**（含墓碑行）：删除与摘除都是数据，不同步过去
    // 就会在别的设备上「复活」。
    final tags = await _db.select(_db.noteTags).get();
    final tagLinks = await _db.select(_db.noteTagLinks).get();
    final noteVersions = await _db.select(_db.noteVersions).get();

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
            editorFontId: row.editorFontId,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt,
            purgedAt: row.purgedAt,
            isPinned: row.isPinned,
            isFavorite: row.isFavorite,
          ),
      ],
      folders: <BackupFolder>[
        for (final row in folders)
          BackupFolder(
            id: row.id,
            // 存**让出版**（`<原名>#<id>`），不是用户看到的名字。跨设备合并与恢复
            // 都依赖两侧用同一套约定，剥后缀只发生在展示层（`folder_local_data_source`
            // 的 `_toEntity`）。
            name: row.name,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            sortIndex: row.sortIndex,
            deletedAt: row.deletedAt,
            purgedAt: row.purgedAt,
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
            reminderAt: row.reminderAt,
            deletedAt: row.deletedAt,
            purgedAt: row.purgedAt,
            priority: TodoPriority.fromLevel(row.priority).id,
            recurrence: row.recurrence,
            linkedNoteId: row.linkedNoteId,
          ),
      ],
      // ⚠️ 子项**无条件全量读**：不同步的话 A 机勾掉的勾会在 B 机同步后被抹掉。
      subtasks: <BackupTodoSubtask>[
        for (final row in subtasks)
          BackupTodoSubtask(
            id: row.id,
            todoId: row.todoId,
            title: row.title,
            isDone: row.isDone,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
          ),
      ],
      tags: <BackupNoteTag>[
        for (final row in tags)
          BackupNoteTag(
            id: row.id,
            name: row.name,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt,
          ),
      ],
      tagLinks: <BackupNoteTagLink>[
        for (final row in tagLinks)
          BackupNoteTagLink(
            noteId: row.noteId,
            tagId: row.tagId,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            deletedAt: row.deletedAt,
          ),
      ],
      noteVersions: <BackupNoteVersion>[
        for (final row in noteVersions)
          BackupNoteVersion(
            id: row.id,
            noteId: row.noteId,
            title: row.title,
            content: row.content,
            createdAt: row.createdAt,
          ),
      ],
    );
  });

  /// 保留期清扫不在这里 —— 那个方法需要**本地时钟**（判据是「本机现在」），
  /// 而本文件的每条时间戳都必须来自对端。两者的边界由
  /// `test/core/utils/app_clock_usage_test.dart` 钉住，见 `TombstoneSweeper`。

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
      // ⚠️ 子项**必须最后写**：它的外键指向 `todos`，而 `PRAGMA foreign_keys = ON`
      // 在事务内是即时生效的 —— 先写子项会整批失败。
      await _writeSubtasks(snapshot.subtasks);
      // v10 的三张新表。links 压轴：外键同时指向 notes 与 note_tags。
      await _writeNoteTags(snapshot.tags);
      await _writeNoteVersions(snapshot.noteVersions, snapshot.noteIds);
      await _writeNoteTagLinks(snapshot.tagLinks, snapshot.noteIds, snapshot.tagIds);
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
      // ⚠️ 必须显式写：`deletedAt` 漏掉的话，来端「已删」的文件夹会被当成正常的
      // 插入 —— 每同步一次，回收站里的文件夹就复活一批。
      deletedAt: Value(folder.deletedAt),
      // ⚠️ 同理：漏了 `purgedAt`，来端的永久删除会被抹掉，对端已删的文件夹
      // 会在本机复活。
      purgedAt: Value(folder.purgedAt),
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
    } on DriftWrappedException {
      // 同上：drift 会把底层异常包一层再抛。只 catch `SqliteException` 时，
      // 撞 UNIQUE 若以这层形式出现，改名重试不生效 → 整批同步事务回滚。
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
            // ⚠️ 墓碑必须显式写出：`insertOrReplace` 是 DELETE+INSERT，漏掉的列
            // 取默认值（NULL）。漏 `purgedAt` = 每同步一次就把接收端「已永久删除」
            // 的笔记复活一批 —— 与漏 `deletedAt` 同一类错误，只是更晚才被发现。
            purgedAt: Value(note.purgedAt),
            // 同理：置顶与收藏是用户数据，漏了会被同步静默清零。
            isPinned: Value(note.isPinned),
            isFavorite: Value(note.isFavorite),
            background: Value(note.background),
            // ⚠️ 同理：漏一次就把接收端全部笔记的字体清零（含「系统默认」这个
            // 合法取值 —— 它也是 null，与「漏了」在库里长得一模一样）。
            editorFontId: Value(note.editorFontId),
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
            reminderAt: Value(todo.reminderAt),
            // ⚠️ 同理：`insertOrReplace` 会把未列出的列清成 NULL，漏了 `deletedAt`
            // 就等于每次同步清空全部「已删」状态。
            deletedAt: Value(todo.deletedAt),
            // ⚠️ 墓碑，同理。漏了它，接收端「已永久删除」的待办每次同步复活一批。
            purgedAt: Value(todo.purgedAt),
            // ⚠️ 同样必须显式写：漏了 `priority` 等于每次同步把接收端全部待办的
            // 优先级重置成「普通」；漏了 `recurrence` 等于全部重复提醒消失。
            priority: Value(TodoPriority.fromId(todo.priority).level),
            recurrence: Value(todo.recurrence),
            // ⚠️ 同理：漏了 `linkedNoteId` 等于每次同步把接收端全部待办的
            // 挂接清掉。
            linkedNoteId: Value(todo.linkedNoteId),
          ),
          // ⚠️ `reminderAt` 必须显式写出：`insertOrReplace` 是 DELETE+INSERT，
          // 漏掉的列取默认值（NULL），等于每次同步都把接收端的提醒时间清零。
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 写子项。⚠️ **排在 [write] 的最后**：外键指向 `todos`，`PRAGMA foreign_keys = ON`
  /// 在事务内即时生效，先写会整批失败。
  ///
  /// `insertOrReplace` 的 DELETE+INSERT 语义在这里**是想要的**：它让「父待办被对端
  /// 物理清扫掉」这类情况自动把子项一并带走（外键 CASCADE），不用手工对账。
  Future<void> _writeSubtasks(List<BackupTodoSubtask> subtasks) {
    return _db.batch((batch) {
      for (final subtask in subtasks) {
        batch.insert(
          _db.todoSubtasks,
          TodoSubtasksCompanion.insert(
            id: subtask.id,
            todoId: subtask.todoId,
            title: subtask.title,
            isDone: Value(subtask.isDone),
            createdAt: subtask.createdAt,
            updatedAt: subtask.updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 写标签。没有 UNIQUE(name) 约束（见 `note_tags_table.dart` 类注释），
  /// 可以像 notes 一样放心走 batch。
  Future<void> _writeNoteTags(List<BackupNoteTag> tags) {
    return _db.batch((batch) {
      for (final tag in tags) {
        batch.insert(
          _db.noteTags,
          NoteTagsCompanion(
            id: Value(tag.id),
            name: Value(tag.name),
            createdAt: Value(tag.createdAt),
            // ⚠️ 墓碑必须显式写出：漏了 `deletedAt`，来端「已删」的标签每同步
            // 一次复活一批（`insertOrReplace` 是 DELETE+INSERT，未列出的列取
            // 默认值 NULL —— 与 `_writeNotes` 同一类错误）。
            updatedAt: Value(tag.updatedAt),
            deletedAt: Value(tag.deletedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 写单篇版本。`noteIds` 是快照里出现过的笔记 id：parse 跳过某条坏笔记行时，
  /// 它挂的版本就成了孤儿，外键开着写进去会整批失败 —— 与 `_writeNotes` 清洗
  /// `folderId` 同一手法，这里选**跳过**而不是清键（版本没有「未归属」语义）。
  Future<void> _writeNoteVersions(
    List<BackupNoteVersion> versions,
    Set<String> noteIds,
  ) {
    return _db.batch((batch) {
      for (final version in versions) {
        if (!noteIds.contains(version.noteId)) continue;
        batch.insert(
          _db.noteVersions,
          NoteVersionsCompanion(
            id: Value(version.id),
            noteId: Value(version.noteId),
            title: Value(version.title),
            content: Value(version.content),
            createdAt: Value(version.createdAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// 写笔记↔标签链接。⚠️ **必须最后写**：外键同时指向 notes 与 note_tags，
  /// `PRAGMA foreign_keys = ON` 在事务内即时生效。孤儿行（noteId / tagId 不在
  /// 快照里）跳过，理由同 [_writeNoteVersions]。
  Future<void> _writeNoteTagLinks(
    List<BackupNoteTagLink> links,
    Set<String> noteIds,
    Set<String> tagIds,
  ) {
    return _db.batch((batch) {
      for (final link in links) {
        if (!noteIds.contains(link.noteId) || !tagIds.contains(link.tagId)) {
          continue;
        }
        batch.insert(
          _db.noteTagLinks,
          NoteTagLinksCompanion.insert(
            noteId: link.noteId,
            tagId: link.tagId,
            createdAt: link.createdAt,
            updatedAt: link.updatedAt,
            // ⚠️ 墓碑必须显式写出，漏了摘除状态每同步一次复活一批。
            deletedAt: Value(link.deletedAt),
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
