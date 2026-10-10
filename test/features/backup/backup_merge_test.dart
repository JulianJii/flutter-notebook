import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/domain/entities/backup_import_result.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';

/// drift 存 `DateTime` 用 unix **秒**，毫秒级的值会全部塌成 0（与库里读回的
/// 值对不上）。所有时间戳都用整秒。
final DateTime t1 = DateTime.fromMillisecondsSinceEpoch(100 * 1000);
final DateTime t2 = DateTime.fromMillisecondsSinceEpoch(200 * 1000);
final DateTime t3 = DateTime.fromMillisecondsSinceEpoch(300 * 1000);

BackupNote note({
  String id = 'n1',
  String title = '标题',
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    BackupNote(
      id: id,
      title: title,
      content: '正文',
      folderId: null,
      background: null,
      createdAt: t1,
      updatedAt: updatedAt ?? t2,
      deletedAt: deletedAt,
    );

BackupFolder folder(
  String id,
  String name, {
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    BackupFolder(
      id: id,
      name: name,
      createdAt: t1,
      updatedAt: updatedAt ?? t2,
      sortIndex: 0,
      deletedAt: deletedAt,
    );

BackupTodo todo(
  String id,
  String title, {
  DateTime? updatedAt,
  DateTime? deletedAt,
  DateTime? reminderAt,
}) =>
    BackupTodo(
      id: id,
      title: title,
      isDone: false,
      createdAt: t1,
      updatedAt: updatedAt ?? t2,
      deletedAt: deletedAt,
      reminderAt: reminderAt,
    );

BackupSnapshot snapshot({
  List<BackupNote> notes = const <BackupNote>[],
  List<BackupFolder> folders = const <BackupFolder>[],
  List<BackupTodo> todos = const <BackupTodo>[],
}) =>
    BackupSnapshot(
      exportedAt: t3,
      notes: notes,
      folders: folders,
      todos: todos,
    );

void main() {
  group('BackupSnapshot.merge', () {
    test('对端更新更晚 → 对端赢，计入 updated', () {
      final merged = BackupSnapshot.merge(
        snapshot(notes: <BackupNote>[note(title: '本地', updatedAt: t2)]),
        snapshot(notes: <BackupNote>[note(title: '对端', updatedAt: t3)]),
      );

      expect(merged.merged.notes.single.title, '对端');
      expect(merged.result, const BackupImportResult(updated: 1));
    });

    test('本地更新更晚 → 保留本地，不计 updated', () {
      final merged = BackupSnapshot.merge(
        snapshot(notes: <BackupNote>[note(title: '本地', updatedAt: t3)]),
        snapshot(notes: <BackupNote>[note(title: '对端', updatedAt: t2)]),
      );

      expect(merged.merged.notes.single.title, '本地');
      expect(merged.result, BackupImportResult.empty);
    });

    test('本地没有 → 计入 inserted', () {
      final merged = BackupSnapshot.merge(
        snapshot(),
        snapshot(notes: <BackupNote>[note()]),
      );

      expect(merged.merged.notes.single.id, 'n1');
      expect(merged.result, const BackupImportResult(inserted: 1));
    });

    /// ⚠️ 这是合并键取「`updatedAt` 与 `deletedAt` 较晚者」的唯一理由：
    /// 软删除不刷新 `updatedAt`，只比 `updatedAt` 的话，一条更早的编辑会把
    /// 已删除的笔记复活。
    test('删除比本地编辑更晚 → 删除赢，不复活', () {
      final merged = BackupSnapshot.merge(
        // 本地 t2 改过标题；对端 t1 的版本在 t3 被删了。
        snapshot(notes: <BackupNote>[note(title: '本地改过', updatedAt: t2)]),
        snapshot(
          notes: <BackupNote>[note(title: '对端', updatedAt: t1, deletedAt: t3)],
        ),
      );

      expect(merged.merged.notes.single.deletedAt, t3);
      expect(merged.result, const BackupImportResult(updated: 1));
    });

    test('本地独有的行原样保留（合并是并集，不删东西）', () {
      final merged = BackupSnapshot.merge(
        snapshot(notes: <BackupNote>[note(id: 'n1')]),
        snapshot(notes: <BackupNote>[note(id: 'n2')]),
      );

      expect(merged.merged.notes.map((n) => n.id), <String>{'n1', 'n2'});
      expect(merged.result, const BackupImportResult(inserted: 1));
    });

    // ---- 删除跨设备传播（v2：文件夹 / 待办也软删除）----
    //
    // 机制：库里存的是墓碑（`deleted_at`），合并键是 `max(updatedAt, deletedAt)`。
    // 以前待办/文件夹是硬删除，A 机删完 B 机会原样带回来 —— 这几条钉的就是
    // 那条链路。

    test('文件夹删除跨设备传播：对端墓碑更新 → 本地进回收站', () {
      final merged = BackupSnapshot.merge(
        snapshot(folders: <BackupFolder>[folder('f1', '工作', updatedAt: t1)]),
        snapshot(
          folders: <BackupFolder>[folder('f1', '工作#f1', deletedAt: t3)],
        ),
      );

      expect(merged.merged.folders.single.deletedAt, t3, reason: '删除要传得过去');
      expect(merged.merged.folders.single.name, '工作#f1',
          reason: '让出的名字随快照一起走');
    });

    test('待办删除跨设备传播：对端墓碑更新 → 本地进回收站', () {
      final merged = BackupSnapshot.merge(
        snapshot(todos: <BackupTodo>[todo('d1', '买牛奶', updatedAt: t1)]),
        snapshot(todos: <BackupTodo>[todo('d1', '买牛奶', deletedAt: t3)]),
      );

      expect(merged.merged.todos.single.deletedAt, t3);
    });

    test('恢复跨设备传播：本地墓碑较旧 → 对端的恢复赢', () {
      final merged = BackupSnapshot.merge(
        snapshot(folders: <BackupFolder>[folder('f1', '工作#f1', deletedAt: t2)]),
        snapshot(folders: <BackupFolder>[folder('f1', '工作', updatedAt: t3)]),
      );

      expect(merged.merged.folders.single.deletedAt, isNull,
          reason: '恢复必须跨设备传得过去，否则恢复完下次同步又滚回收站');
      expect(merged.merged.folders.single.name, '工作');
    });

    test('删除比本地编辑更晚 → 删除赢（软删除不被更晚的编辑复活）', () {
      final merged = BackupSnapshot.merge(
        snapshot(todos: <BackupTodo>[todo('d1', '本地改过', updatedAt: t2)]),
        snapshot(todos: <BackupTodo>[todo('d1', '远端', deletedAt: t3)]),
      );

      expect(merged.merged.todos.single.deletedAt, t3);
    });
  });

  group('BackupSnapshot.parse', () {
    test('JSON 往返不丢字段', () {
      final original = snapshot(
        notes: <BackupNote>[note(deletedAt: t3)],
        folders: <BackupFolder>[folder('f1', '工作')],
      );

      final parsed = BackupSnapshot.parse(original.toJson());

      expect(parsed.skipped, 0);
      expect(parsed.snapshot.notes.single.title, '标题');
      expect(parsed.snapshot.notes.single.deletedAt, t3);
      expect(parsed.snapshot.folders.single.name, '工作');
    });

    test('坏行跳过并计数，好行照读', () {
      final raw = <String, Object?>{
        'version': backupSnapshotVersion,
        'notes': <Object?>[
          note(id: 'ok').toJson(),
          <String, Object?>{'createdAt': t1.toIso8601String()}, // 缺 id
          42, // 不是对象
        ],
      };

      final parsed = BackupSnapshot.parse(raw);

      expect(parsed.skipped, 2);
      expect(parsed.snapshot.notes.single.id, 'ok');
    });

    test('顶层不是对象 → 空快照', () {
      expect(BackupSnapshot.parse('not a map').snapshot.isEmpty, isTrue);
    });

    /// v1 快照里没有 `deletedAt`（那时文件夹 / 待办还是硬删除）。因为 v2 只加
    /// 字段、不改语义，老文件解析出来必须是 `null` = 未删除 —— 与 v1 时代
    /// 「全部可见」的行为一致。老用户升级后导入旧备份，不该凭空少一半数据，
    /// 也不该突然多出一堆「已删」。
    test('v1 老快照（无 deletedAt）照样能解析，全视为未删除', () {
      final v1 = <String, Object?>{
        'version': 1,
        'exportedAt': t3.toIso8601String(),
        'notes': <Object?>[note(id: 'n1').toJson()],
        'folders': <Object?>[
          <String, Object?>{
            'id': 'f1',
            'name': '工作',
            'createdAt': t1.toIso8601String(),
            'updatedAt': t2.toIso8601String(),
            'sortIndex': 0,
          },
        ],
        'todos': <Object?>[
          <String, Object?>{
            'id': 'd1',
            'title': '买牛奶',
            'isDone': false,
            'createdAt': t1.toIso8601String(),
            'updatedAt': t2.toIso8601String(),
          },
        ],
      };

      final parsed = BackupSnapshot.parse(v1);

      expect(parsed.skipped, 0);
      expect(parsed.snapshot.folders.single.deletedAt, isNull);
      expect(parsed.snapshot.todos.single.deletedAt, isNull);
      expect(parsed.snapshot.todos.single.reminderAt, isNull,
          reason: 'v1 根本没同步过提醒，导入后是「没提醒」而不是编一个假时间');
      expect(parsed.snapshot.folders.single.name, '工作',
          reason: 'v1 的 name 没有让出后缀，不该被剥');
    });
  });

  group('BackupLocalDataSource', () {
    late AppDatabase db;
    late BackupLocalDataSource source;

    setUp(() {
      db = AppDatabase.memory();
      source = BackupLocalDataSource(db);
    });

    tearDown(() => db.close());

    test('写入后读回一致（含回收站里的软删除笔记）', () async {
      final skipped = await source.write(
        snapshot(
          notes: <BackupNote>[note(deletedAt: t3)],
          folders: <BackupFolder>[folder('f1', '工作')],
        ),
      );

      expect(skipped, 0);
      final read = await source.read();
      expect(read.notes.single.id, 'n1');
      expect(read.notes.single.deletedAt, t3);
      expect(read.folders.single.name, '工作');
    });

    /// `note_folders.name` 是 UNIQUE，跨设备各建同名文件夹必然撞车。撞了改名，
    /// 不丢数据。
    test('同名文件夹改名而不是丢弃', () async {
      final skipped = await source.write(
        snapshot(
          folders: <BackupFolder>[folder('f1', '工作'), folder('f2', '工作')],
        ),
      );

      expect(skipped, 0);
      final read = await source.read();
      expect(
        read.folders.map((f) => f.name).toList()..sort(),
        <String>['工作', '工作 (2)'],
      );
    });

    test('指向不存在文件夹的 folderId 被清洗成 null', () async {
      await source.write(
        snapshot(
          notes: <BackupNote>[
            BackupNote(
              id: 'n1',
              title: '标题',
              content: '',
              folderId: '不存在的文件夹',
              background: null,
              createdAt: t1,
              updatedAt: t2,
              deletedAt: null,
            ),
          ],
        ),
      );

      final read = await source.read();
      // 外键开着，不清洗这条根本插不进去。
      expect(read.notes.single.folderId, isNull);
    });

    test('重复写入是幂等的（同步可以随时重试）', () async {
      final payload = snapshot(notes: <BackupNote>[note()]);
      await source.write(payload);
      await source.write(payload);

      final read = await source.read();
      expect(read.notes.length, 1);
    });

    /// 防回归 B1：`_writeTodos` 用 `insertOrReplace`，而 SQLite 的
    /// `INSERT OR REPLACE` 是 DELETE+INSERT —— **未列出的列取默认值 NULL**。
    /// 少写 `reminder_at` 一列，就不是「提醒不同步」而是「每次同步把接收端
    /// 全部待办的提醒时间清零」。这条钉的是「写入的快照带提醒 → 读回还在」。
    test('待办的 reminder_at 往返不丢（写回不把它清成 null）', () async {
      final payload = BackupSnapshot(
        exportedAt: t3,
        notes: const <BackupNote>[],
        folders: const <BackupFolder>[],
        todos: <BackupTodo>[
          BackupTodo(
            id: 'd1',
            title: '买牛奶',
            isDone: false,
            createdAt: t1,
            updatedAt: t2,
            reminderAt: t3,
          ),
        ],
      );

      await source.write(payload);

      final read = await source.read();
      expect(read.todos.single.reminderAt, t3);
      // 再写一次（模拟下一次同步）：仍必须留着。
      await source.write(read);
      expect((await source.read()).todos.single.reminderAt, t3);
    });

    /// 同上，但提醒为空的那条也不能被写成别的东西。
    test('没设提醒的待办往返后 reminder_at 仍为 null', () async {
      await source.write(
        BackupSnapshot(
          exportedAt: t3,
          notes: const <BackupNote>[],
          folders: const <BackupFolder>[],
          todos: <BackupTodo>[
            BackupTodo(
              id: 'd1',
              title: '不提醒',
              isDone: true,
              createdAt: t1,
              updatedAt: t2,
            ),
          ],
        ),
      );

      expect((await source.read()).todos.single.reminderAt, isNull);
    });

    /// 防回归（v2 引入 `deleted_at` 时最容易踩的坑，与 `reminder_at` 同源）：
    /// `_writeTodos` 用 `insertOrReplace` = DELETE+INSERT，**未列出的列取 NULL**。
    /// 漏写 `deleted_at` 的后果不是「墓碑不传播」，而是**每次同步把所有已删的
    /// 待办和文件夹复活一批** —— 比不传播更糟：它让删除看起来是坏的。
    test('已删待办往返后仍在回收站（写回不把 deleted_at 清成 null）', () async {
      final payload = BackupSnapshot(
        exportedAt: t3,
        notes: const <BackupNote>[],
        folders: const <BackupFolder>[],
        todos: <BackupTodo>[todo('d1', '买牛奶', deletedAt: t3)],
      );

      await source.write(payload);
      expect((await source.read()).todos.single.deletedAt, t3);

      // 再写一次（模拟下一次同步）：必须还是墓碑。
      await source.write(await source.read());
      expect((await source.read()).todos.single.deletedAt, t3,
          reason: '漏写 deleted_at 时这里会变成 null —— 待办被复活');
    });

    test('已删文件夹往返后仍在回收站，且让出的名字原样保留', () async {
      await source.write(
        BackupSnapshot(
          exportedAt: t3,
          notes: const <BackupNote>[],
          folders: <BackupFolder>[folder('f1', '工作#f1', deletedAt: t3)],
          todos: const <BackupTodo>[],
        ),
      );

      final read = await source.read();
      expect(read.folders.single.deletedAt, t3);
      expect(read.folders.single.name, '工作#f1',
          reason: '让出版是跨设备约定，剥后缀只发生在展示层');
    });

    /// 防回归 B2：用户在 A 机把笔记从回收站恢复。恢复**必须**刷 `updated_at`
    /// （见 `NoteDao.restoreById`），否则本地的 version 退回旧 `updatedAt`，
    /// 比远端那条的 `deletedAt` 还早 → 下一轮同步远端胜出，笔记自己滚回回收站。
    test('恢复笔记（deletedAt 清空 + updatedAt 刷新）不会被远端的删除态压回去', () {
      final merged = BackupSnapshot.merge(
        // 本地：刚从回收站恢复，updatedAt = t3 > 远端的 deletedAt = t2。
        snapshot(
          notes: <BackupNote>[note(title: '恢复后的', updatedAt: t3)],
        ),
        snapshot(
          notes: <BackupNote>[note(title: '远端', updatedAt: t1, deletedAt: t2)],
        ),
      );

      expect(
        merged.merged.notes.single.deletedAt,
        isNull,
        reason: '恢复比删除更晚，恢复必须赢 —— 否则同步会把恢复回滚掉',
      );
      expect(merged.merged.notes.single.title, '恢复后的');
    });

    /// 上面那条的**前提**：恢复必须严格晚于删除才赢。
    ///
    /// drift 把 `DateTime` 按 unix **秒**存，所以「同一秒内删除又编辑」是可能的；
    /// 这时合并键打平，按既有规则**保留本地** —— 也就是本地那次编辑赢。
    /// 反向同理：同一秒内的编辑挡不住删除（同样打平、同样保留本地，但本地
    /// 若已删除则是删除赢）。这条钉住平局的既有行为，避免有人给 `version`
    /// 加 `>=` 时无声改掉合并语义。
    test('恢复与删除同一秒 → 键打平，保留本地（不靠比较符定胜负）', () {
      final merged = BackupSnapshot.merge(
        snapshot(notes: <BackupNote>[note(title: '本地', updatedAt: t3)]),
        snapshot(
          notes: <BackupNote>[note(title: '对端', updatedAt: t1, deletedAt: t3)],
        ),
      );

      expect(merged.merged.notes.single.title, '本地');
      expect(merged.merged.notes.single.deletedAt, isNull);
      expect(merged.result, BackupImportResult.empty);
    });
  });
}
