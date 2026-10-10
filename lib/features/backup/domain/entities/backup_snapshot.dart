import 'backup_import_result.dart';

/// 快照格式版本。写进 JSON 的 `version` 字段。
///
/// ⚠️ 读的时候**据此拒绝**比它高的版本（[BackupSnapshot.parse] 不拒绝，由
/// Repository 判）：未来的格式我们读不懂，静默降级解析会造出一堆缺字段的
/// 半残数据 —— 那比「无法导入」更难收拾。
///
/// **v2**：文件夹与待办加 `deletedAt`（跨设备软删除）。**向后兼容** —— v1 文件
/// 没有这两个字段，解析出来是 `null` = 未删除，与 v1 时代「全部可见」的行为
/// 一致，所以老快照照样能导入（只有加字段、没有改语义）。
const int backupSnapshotVersion = 2;

/// 快照里的一篇笔记。`content` 是 Quill Delta 的 JSON 字符串，与库里同格式
/// （`NoteDeltaCodec` 的编解码结果），本层不做任何解释。
class BackupNote {
  const BackupNote({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.background,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String id;

  final String title;

  final String content;

  /// null = 未分类。
  final String? folderId;

  final String? background;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// 非 null = 在回收站里。
  final DateTime? deletedAt;

  /// 合并比较键。
  ///
  /// ⚠️ 取 `updatedAt` 与 `deletedAt` 的**较晚者**：软删除也是一次变更，只用
  /// `updatedAt` 比的话，「A 机删除 / B 机改标题」会让一条更晚的编辑把已删除
  /// 的笔记复活（删除不刷新 `updatedAt`，见 `NoteDao.softDeleteById`）。
  DateTime get version => deletedAt == null || deletedAt!.isBefore(updatedAt)
      ? updatedAt
      : deletedAt!;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'content': content,
    'folderId': folderId,
    'background': background,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  /// 坏行返回 `null`（由 [_rows] 计入 skipped）。外部输入，逐字段 `is` 校验。
  static BackupNote? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null || id.isEmpty || createdAt == null || updatedAt == null) {
      return null;
    }
    return BackupNote(
      id: id,
      title: _str(json['title']) ?? '',
      content: _str(json['content']) ?? '',
      folderId: _str(json['folderId']),
      background: _str(json['background']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: _date(json['deletedAt']),
    );
  }
}

/// 快照里的一个文件夹。
///
/// ⚠️ `name` 在库里是 UNIQUE。跨设备各自新建同名文件夹会撞约束 —— 由
/// `BackupLocalDataSource` 改名重试，这里**不做**去重（合并规则只认 id）。
///
/// ⚠️ `name` 存的是**让出版**（`<原名>#<id>`，见
/// `note_folders_table.dart` 的 `trashedFolderName`），不是用户看到的名字。
/// 跨设备合并时两侧都要用同一套约定，否则恢复会写回一个带 `#` 的名字。
class BackupFolder {
  const BackupFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.sortIndex,
    this.deletedAt,
  });

  final String id;

  final String name;

  final DateTime createdAt;

  final DateTime updatedAt;

  final int sortIndex;

  /// 非 null = 在回收站里。
  final DateTime? deletedAt;

  /// 合并比较键。语义同 [BackupNote.version]（软删除也是一次变更，且软删除不刷
  /// `updatedAt`），抽成共用逻辑避免三处各写一遍、各错一遍。
  DateTime get version => deletedAt == null || deletedAt!.isBefore(updatedAt)
      ? updatedAt
      : deletedAt!;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sortIndex': sortIndex,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  static BackupFolder? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final name = _str(json['name']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null ||
        id.isEmpty ||
        name == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return BackupFolder(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sortIndex: json['sortIndex'] is int ? json['sortIndex']! as int : 0,
      deletedAt: _date(json['deletedAt']),
    );
  }
}

/// 快照里的一条待办。
///
/// ⚠️ `reminderAt`（提醒时刻）**必须出现在这里**：`BackupLocalDataSource._writeTodos`
/// 用的是 `InsertMode.insertOrReplace`，而 SQLite 的 `INSERT OR REPLACE` 语义是
/// 「DELETE + INSERT」—— **未列出的列一律取默认值**。少写这一列 = 每同步一次就把
/// 接收端全部待办的提醒时间清零（不是「不同步」，是「清空」）。
/// 同理适用于 [deletedAt]：漏了它，每同步一次就把所有已删待办复活。
class BackupTodo {
  const BackupTodo({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    required this.updatedAt,
    this.reminderAt,
    this.deletedAt,
  });

  final String id;

  final String title;

  final bool isDone;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// null = 没设提醒。
  final DateTime? reminderAt;

  /// 非 null = 在回收站里。
  final DateTime? deletedAt;

  /// 合并比较键。语义同 [BackupNote.version]。
  DateTime get version => deletedAt == null || deletedAt!.isBefore(updatedAt)
      ? updatedAt
      : deletedAt!;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  static BackupTodo? fromJson(Map<String, Object?> json) {
    final id = _str(json['id']);
    final title = _str(json['title']);
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    if (id == null ||
        id.isEmpty ||
        title == null ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return BackupTodo(
      id: id,
      title: title,
      isDone: json['isDone'] == true,
      createdAt: createdAt,
      updatedAt: updatedAt,
      reminderAt: _date(json['reminderAt']),
      deletedAt: _date(json['deletedAt']),
    );
  }
}

/// 一份完整的数据快照 = `notes` + `note_folders` + `todos` 三张表的全量。
///
/// 导出、导入、WebDAV 同步共用这一个模型，差别只在「字节从哪来到哪去」。
///
/// ⚠️ **不含设置偏好**：偏好在 SharedPreferences 里，与本 App 的数据库不同源，
/// 一起搬会让「换设备」变成「连主题一起换」，不是用户要的。
class BackupSnapshot {
  const BackupSnapshot({
    required this.exportedAt,
    required this.notes,
    required this.folders,
    required this.todos,
  });

  /// 「远端还没有文件」的空快照。同步首推时用它当基线。
  factory BackupSnapshot.empty() => BackupSnapshot(
    exportedAt: DateTime.fromMillisecondsSinceEpoch(0),
    notes: const <BackupNote>[],
    folders: const <BackupFolder>[],
    todos: const <BackupTodo>[],
  );

  final DateTime exportedAt;

  final List<BackupNote> notes;

  final List<BackupFolder> folders;

  final List<BackupTodo> todos;

  bool get isEmpty => notes.isEmpty && folders.isEmpty && todos.isEmpty;

  int get count => notes.length + folders.length + todos.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'version': backupSnapshotVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'notes': notes.map((n) => n.toJson()).toList(growable: false),
    'folders': folders.map((f) => f.toJson()).toList(growable: false),
    'todos': todos.map((t) => t.toJson()).toList(growable: false),
  };

  /// 解析一份 JSON 已 decode 的对象。**不校验版本**（Repository 负责）。
  ///
  /// 返回 `skipped`：坏行（缺 id / 时间戳不是 ISO 串 / 不是对象）逐条跳过计数 ——
  /// 导入的是外部输入，一条脏数据不该炸掉整个导入，但也不该被静默吞掉。
  static ({BackupSnapshot snapshot, int skipped}) parse(Object? raw) {
    if (raw is! Map) return (snapshot: BackupSnapshot.empty(), skipped: 0);
    final json = raw.cast<String, Object?>();

    final notes = _rows(json['notes'], BackupNote.fromJson);
    final folders = _rows(json['folders'], BackupFolder.fromJson);
    final todos = _rows(json['todos'], BackupTodo.fromJson);

    return (
      snapshot: BackupSnapshot(
        exportedAt: _date(json['exportedAt']) ?? DateTime.now(),
        notes: notes.rows,
        folders: folders.rows,
        todos: todos.rows,
      ),
      skipped: notes.skipped + folders.skipped + todos.skipped,
    );
  }

  /// 双向合并：逐条比 [version]，新的赢；一样新保留 [local]（避免无意义写库）。
  ///
  /// 三类实体用**同一个**比较键 `max(updatedAt, deletedAt)` —— 软删除也是一次变更。
  /// 这是删除能跨设备传播的全部机制：库里存的是墓碑（`deleted_at`），不是硬删除。
  ///
  /// ⚠️ 仍然只增不删（见 [_mergeById]）：物理删除（回收站的「永久删除」）不传播，
  /// 见 `docs/FEATURES.md`「已知限制」。
  static ({BackupSnapshot merged, BackupImportResult result}) merge(
    BackupSnapshot local,
    BackupSnapshot incoming,
  ) {
    final folders = _mergeById(
      local.folders,
      incoming.folders,
      (f) => f.id,
      (f) => f.version,
    );
    final notes = _mergeById(
      local.notes,
      incoming.notes,
      (n) => n.id,
      (n) => n.version,
    );
    final todos = _mergeById(
      local.todos,
      incoming.todos,
      (t) => t.id,
      (t) => t.version,
    );

    final result = BackupImportResult(
      inserted: folders.inserted + notes.inserted + todos.inserted,
      updated: folders.updated + notes.updated + todos.updated,
      skipped: 0,
    );

    return (
      merged: BackupSnapshot(
        exportedAt: DateTime.now(),
        notes: notes.rows,
        folders: folders.rows,
        todos: todos.rows,
      ),
      result: result,
    );
  }
}

/// 按 id 合并两批行。[versionOf] 给比较键，相等时保留本地。
({List<T> rows, int inserted, int updated}) _mergeById<T>(
  List<T> local,
  List<T> incoming,
  String Function(T) idOf,
  DateTime Function(T) versionOf,
) {
  final localById = <String, T>{for (final row in local) idOf(row): row};
  final incomingIds = <String>{for (final row in incoming) idOf(row)};

  var inserted = 0;
  var updated = 0;
  final rows = <T>[];

  for (final row in incoming) {
    final mine = localById[idOf(row)];
    if (mine == null) {
      inserted++;
      rows.add(row);
    } else if (versionOf(row).isAfter(versionOf(mine))) {
      updated++;
      rows.add(row);
    } else {
      rows.add(mine);
    }
  }

  /// 本地独有（对端没有 / 对端已物理删除）的行原样保留。
  ///
  /// ⚠️ 保留不等于「不删」：**软删除的行会带着 `deletedAt` 一起被保留下来**，
  /// 写库后仍然是回收站态 —— 删除正是这样传播的。这里保留的只是「对方没提过的
  /// 行」，软删除是对方**提了**、且提了墓碑的那一类。
  for (final row in local) {
    if (!incomingIds.contains(idOf(row))) rows.add(row);
  }

  return (rows: rows, inserted: inserted, updated: updated);
}

/// 解析一个数组，逐行容错。`decode` 返回 null = 坏行。
({List<T> rows, int skipped}) _rows<T>(
  Object? raw,
  T? Function(Map<String, Object?> json) decode,
) {
  var skipped = 0;
  final rows = <T>[];
  if (raw is! List) return (rows: rows, skipped: skipped);

  for (final item in raw) {
    if (item is! Map) {
      skipped++;
      continue;
    }
    final row = decode(item.cast<String, Object?>());
    if (row == null) {
      skipped++;
    } else {
      rows.add(row);
    }
  }
  return (rows: rows, skipped: skipped);
}

/// 取值：不是 `String` 就当没有。导入的文件是外部输入，不做 `as` 强转。
String? _str(Object? value) => value is String ? value : null;

/// 取时间戳：只认 ISO-8601（库里写进去的格式）。
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
