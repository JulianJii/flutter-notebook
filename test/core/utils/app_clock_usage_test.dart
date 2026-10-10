import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 守「落库时间戳只能走 `AppClock.appNow()`」这条规矩。
///
/// ⚠️ **为什么需要一条扫源码的测试**：合并键是 `max(updatedAt, deletedAt)`，比的是
/// 各设备自己的时钟（`BackupSnapshot.merge`）。某人新加一条写路径时图省事写了
/// `DateTime.now()`，**没有任何编译期或运行期信号** —— 只是这台时钟不准的设备
/// 会在同步时静默覆盖另一台的改动。没有测试就只能等用户丢数据才发现。
///
/// 断言写成「这些文件里不许出现 `DateTime.now()`」而不是「必须出现
/// `appNow()`」：前者钉住现状（新加文件不在名单里时不会误报），后者在有人刻意
/// 写了一处合理例外后会逼着他改名单。
void main() {
  // 名单 = 全部会写 `created_at` / `updated_at` / `deleted_at` 的地方。
  // DAO 层刻意不在名单里：DAO 不取时钟（时间戳由调用方经 Companion 传入），
  // 那正是这个约定要维持的形状。
  const guarded = <String>[
    'lib/features/notes/domain/usecases/create_note_use_case.dart',
    'lib/features/notes/domain/usecases/update_note_use_case.dart',
    'lib/features/notes/domain/usecases/create_folder_use_case.dart',
    'lib/features/notes/data/repositories/note_repository_impl.dart',
    'lib/features/notes/data/datasources/note_local_data_source.dart',
    'lib/features/notes/data/datasources/folder_local_data_source.dart',
    'lib/features/todos/domain/usecases/create_todo_use_case.dart',
    'lib/features/todos/domain/usecases/update_todo_use_case.dart',
    'lib/features/todos/domain/usecases/toggle_todo_use_case.dart',
    'lib/features/todos/data/repositories/todo_repository_impl.dart',
    'lib/features/todos/data/datasources/todo_local_data_source.dart',
  ];

  test('写时间戳的文件里没有裸 DateTime.now()', () {
    final offenders = <String>[];
    for (final path in guarded) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path 不存在，名单该更新了');

      final hits = RegExp(r'DateTime\.now\(\)')
          .allMatches(file.readAsStringSync())
          .length;
      if (hits > 0) offenders.add('$path ($hits 处)');
    }

    expect(
      offenders,
      isEmpty,
      reason: '这些时间戳会进合并比较键，必须走 AppClock.appNow()',
    );
  });

  /// 反向钉住：**写回快照**的时间戳来自对端，**不能**换成 `appNow()`。
  /// 换了的话每条合并进来的记录都会变成「刚刚编辑过」，`BackupNote.version`
  /// 全都相等 —— 合并静默退化成「本地全胜」，等于同步失效且无人察觉。
  test('备份写回路径不碰 appNow（时间戳来自对端，不能本地重打）', () {
    final source = File(
      'lib/features/backup/data/datasources/backup_local_data_source.dart',
    ).readAsStringSync();

    expect(source.contains('AppClock.appNow()'), isFalse);
    // 它写的是 `folder.createdAt` / `note.updatedAt` 等来自快照的值。
    expect(source.contains('Value(note.updatedAt)'), isTrue);
    expect(source.contains('Value(todo.createdAt)'), isTrue);
  });
}