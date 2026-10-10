import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mynote/core/database/app_database.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/storage/local_storage_service.dart';
import 'package:mynote/features/backup/data/datasources/backup_local_data_source.dart';
import 'package:mynote/features/backup/data/datasources/webdav_data_source.dart';
import 'package:mynote/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:mynote/features/backup/domain/entities/backup_snapshot.dart';
import 'package:mynote/features/backup/domain/entities/backup_version_entry.dart';
import 'package:mynote/features/backup/domain/entities/webdav_config.dart';

class _MockWebDav extends Mock implements WebDavDataSource {}

class _MockStorage extends Mock implements LocalStorageService {}

/// 历史版本的编排规则。
///
/// ⚠️ 用**真 `AppDatabase.memory()`** 而不是 mock 掉 `BackupLocalDataSource`：归档
/// 逻辑判的是「上传前远端内容 vs 本地合并结果」是否真的不同，这条规则的价值全在
/// 那次比较上，mock 掉写入就等于把被测的东西也 mock 掉了。
void main() {
  late AppDatabase db;
  late BackupLocalDataSource local;
  late _MockWebDav webDav;
  late _MockStorage storage;
  late BackupRepositoryImpl repo;

  const config = WebDavConfig(url: 'https://dav.example.com/notes/');
  final entries = <BackupVersionEntry>[];
  final deleted = <String>[];
  var remoteBody = '';
  var remoteExists = false;

  BackupVersionEntry entryAt(int minute) => BackupVersionEntry(
    file: 'notebook-20261010-1200${minute.toString().padLeft(2, '0')}-000.json',
    at: DateTime(2026, 10, 10, 12, minute),
    hash: 'h$minute',
    count: 1,
  );

  setUp(() async {
    // `any()` 打在非可空的自定义类型上时 mocktail 需要一个 fallback 实例。
    registerFallbackValue(const WebDavConfig());
    db = AppDatabase.memory();
    local = BackupLocalDataSource(db);
    webDav = _MockWebDav();
    storage = _MockStorage();

    entries.clear();
    deleted.clear();
    remoteBody = '';
    remoteExists = false;

    when(() => storage.getObject(any())).thenReturn(<String, Object?>{
      'url': config.url,
      'autoSyncOnStart': false,
    });
    when(() => storage.setObject(any(), any())).thenAnswer((_) async => true);

    when(() => webDav.fetch(any())).thenAnswer((_) async => remoteExists ? remoteBody : null);
    when(() => webDav.fetchHistoryIndex(any())).thenAnswer(
      (_) async => entries.isEmpty ? null : List.of(entries),
    );
    when(() => webDav.uploadVersion(any(), any(), any())).thenAnswer((_) async {});
    when(() => webDav.putHistoryIndex(any(), any())).thenAnswer((invocation) async {
      final written = invocation.positionalArguments[1] as List<BackupVersionEntry>;
      entries
        ..clear()
        ..addAll(written);
    });
    when(() => webDav.deleteVersion(any(), any())).thenAnswer((invocation) async {
      deleted.add(invocation.positionalArguments[1] as String);
    });
    when(() => webDav.upload(any(), any())).thenAnswer((invocation) async {
      remoteBody = invocation.positionalArguments[1] as String;
      remoteExists = true;
    });

    repo = BackupRepositoryImpl(local, webDav, storage);
  });

  tearDown(() => db.close());

  /// 把一份快照塞进「远端当前内容」。
  Future<void> seedRemote(BackupSnapshot snapshot) async {
    remoteBody = jsonEncode(snapshot.toJson());
    remoteExists = true;
  }

  BackupSnapshot snapWith(String noteTitle, {DateTime? updatedAt}) {
    final at = updatedAt ?? DateTime.fromMillisecondsSinceEpoch(1000 * 1000);
    return BackupSnapshot(
      exportedAt: at,
      notes: <BackupNote>[
        BackupNote(
          id: 'n1',
          title: noteTitle,
          content: '[]',
          folderId: null,
          background: null,
          createdAt: at,
          updatedAt: at,
          deletedAt: null,
        ),
      ],
      folders: const <BackupFolder>[],
      todos: const <BackupTodo>[],
    );
  }

  test('远端无文件（首次推送）→ 不归档', () async {
    final result = await repo.sync();

    expect(result.isRight(), isTrue);
    expect(entries, isEmpty, reason: '没有「覆盖前的内容」可存');
    verifyNever(() => webDav.uploadVersion(any(), any(), any()));
  });

  /// 归档只在**内容真的变了**时发生。否则每次空同步都往 NAS 堆一份一模一样的
  /// 快照，20 条配额几天就耗光，而用户根本用不到它们。
  test('远端与合并结果一致 → 不归档（空同步不产生垃圾）', () async {
    final snapshot = snapWith('一样的');
    await seedRemote(snapshot);

    final result = await repo.sync();

    expect(result.isRight(), isTrue);
    expect(
      entries,
      isEmpty,
      reason: 'sha256 相同 → 这次同步没改动远端 → 不该有历史',
    );
    verifyNever(() => webDav.uploadVersion(any(), any(), any()));
  });

  test('本地有新增 → 归档覆盖前的那一份', () async {
    final before = snapWith('远端的');
    await seedRemote(before);
    await local.write(before);
    await db.customStatement(
      'INSERT INTO notes (id, title, content, created_at, updated_at) '
      'VALUES (?,?,?,?,?)',
      ['n2', '本地新增的', '[]', 1000, 1000],
    );
    // 必须在 sync **之前**取值：`upload` 会把 remoteBody 覆写成合并后的内容，
    // 而 `verify` 的参数是惰性求值的，到那时拿到的是新值。
    final archived = remoteBody;

    await repo.sync();

    expect(entries, hasLength(1));
    expect(entries.single.count, 1, reason: '归的是**覆盖前**的远端内容（1 条）');
    expect(entries.single.hash, isNotEmpty);
    verify(() => webDav.uploadVersion(any(), entries.single.file, archived)).called(1);
  });

  /// ⚠️ 这条钉的是本轮实现里真实踩过的坑：`BackupSnapshot.merge` 每次都把
  /// `exportedAt` 写成 `DateTime.now()`，所以哪怕数据一个字没动，重序列化出来的
  /// JSON 也字节不同。若拿整份 JSON 的 sha256 去判「变了没有」，**每次空同步都会
  /// 归档一次**，20 条配额几天就耗光 —— 而空同步恰恰是最常见的情况。
  test('空同步（只改了 exportedAt）→ 判为未变化，不归档', () async {
    final snapshot = snapWith('一样的');
    await seedRemote(snapshot);
    await local.write(snapshot);

    await repo.sync();

    expect(
      entries,
      isEmpty,
      reason: '内容指纹刻意排除 exportedAt —— 它每次同步都在变，不能算作「变化」',
    );
  });

  test('只改标题也算变化（指纹覆盖字段值，不只是条数）', () async {
    await seedRemote(snapWith('原来的'));
    await local.write(snapWith('原来的'));
    await db.customStatement('UPDATE notes SET title = ? WHERE id = ?', [
      '改过的',
      'n1',
    ]);

    await repo.sync();

    expect(entries, hasLength(1));
  });

  test('归档时先传文件、后写索引（索引是指针，文件是数据）', () async {
    final order = <String>[];
    when(() => webDav.uploadVersion(any(), any(), any())).thenAnswer((_) async {
      order.add('upload');
    });
    when(() => webDav.putHistoryIndex(any(), any())).thenAnswer((_) async {
      order.add('index');
      entries.clear();
    });
    await seedRemote(snapWith('远端的'));
    await db.customStatement(
      'INSERT INTO notes (id, title, content, created_at, updated_at) '
      'VALUES (?,?,?,?,?)',
      ['n2', '新增', '[]', 1000, 1000],
    );

    await repo.sync();

    expect(order, <String>['upload', 'index']);
  });

  test('超过保留上限 → 删最旧的文件并把索引截到上限', () async {
    entries.addAll(List<BackupVersionEntry>.generate(kHistoryLimit, entryAt));

    await seedRemote(snapWith('远端的'));
    await db.customStatement(
      'INSERT INTO notes (id, title, content, created_at, updated_at) '
      'VALUES (?,?,?,?,?)',
      ['n2', '新增', '[]', 1000, 1000],
    );

    await repo.sync();

    expect(entries, hasLength(kHistoryLimit));
    expect(deleted, hasLength(1), reason: '超出的那一条要被真删掉');
    expect(
      entries.any((e) => e.file == deleted.single),
      isFalse,
      reason: '被删的那条不该还留在索引里',
    );
  });

  test('listHistory 没归档过 → 空列表而不是错误', () async {
    final result = await repo.listHistory();

    expect(result.isRight(), isTrue);
    expect(result.fold((_) => const <BackupVersionEntry>[], (e) => e), isEmpty);
  });

  test('未配置 WebDAV 时列历史 → ValidationFailure', () async {
    when(() => storage.getObject(any())).thenReturn(null);

    final result = await repo.listHistory();

    expect(result.isLeft(), isTrue);
    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
  });

  test('restoreVersion：版本文件缺失 → ValidationFailure，不静默当「没变化」', () async {
    when(() => webDav.fetchVersion(any(), any())).thenAnswer((_) async => null);

    final result = await repo.restoreVersion(entryAt(1));

    expect(result.isLeft(), isTrue);
    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
  });

  test('restoreVersion：走与文件导入完全相同的合并路径', () async {
    final snapshot = snapWith(
      '历史里的笔记',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(5000 * 1000),
    );
    when(() => webDav.fetchVersion(any(), any())).thenAnswer(
      (_) async => jsonEncode(snapshot.toJson()),
    );

    final result = await repo.restoreVersion(entryAt(1));

    expect(result.isRight(), isTrue);
    final read = await local.read();
    expect(read.notes.single.title, '历史里的笔记');
    expect(result.fold((_) => 0, (r) => r.inserted), 1);
  });
}