import 'package:equatable/equatable.dart';

/// 远端保留的一个历史版本。
///
/// **一条记录 = 一个快照文件**。文件名带毫秒时间戳（`notebook-20261010-120000-123.json`），
/// 人类可读且天然按时间排序；毫秒精度让「同一秒内两次同步撞名」不可能发生
/// （一次同步要上百毫秒）。
class BackupVersionEntry extends Equatable {
  const BackupVersionEntry({
    required this.file,
    required this.at,
    required this.hash,
    required this.count,
  });

  /// 相对于 WebDAV **目录**的文件名，不含 `history/` 前缀。
  ///
  /// ⚠️ 只存文件名不存完整路径：换 WebDAV 根目录时历史仍在，而存绝对路径会在
  /// 用户改配置后全部失效。
  final String file;

  /// 这份快照对应的**数据时刻**（不是归档时刻）。
  ///
  /// ⚠️ 取快照里的 `exportedAt` 而不是归档时的时间 —— 用户看的是「这份数据是
  /// 什么时候的」，不是「我什么时候存的」。`exportedAt` 缺失时回落归档时刻。
  final DateTime at;

  /// 快照正文的 sha256。用来判断「这次同步有没有真的改动远端」。
  final String hash;

  /// 记录条数（笔记 + 文件夹 + 待办），只用于列表上显示规模。
  final int count;

  Map<String, Object?> toJson() => <String, Object?>{
    'file': file,
    'at': at.toIso8601String(),
    'hash': hash,
    'count': count,
  };

  /// 坏记录返回 `null`（由调用方计数跳过），与 `BackupSnapshot.parse` 的逐行容错
  /// 同一套约定：索引文件也是外部输入，一条脏数据不该炸掉整个历史列表。
  static BackupVersionEntry? fromJson(Map<String, Object?> json) {
    final file = json['file'];
    final at = json['at'];
    if (file is! String || file.isEmpty || at is! String) return null;

    final parsedAt = DateTime.tryParse(at);
    if (parsedAt == null) return null;

    return BackupVersionEntry(
      file: file,
      at: parsedAt,
      hash: json['hash'] is String ? json['hash']! as String : '',
      count: json['count'] is int ? json['count']! as int : 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[file, at, hash, count];
}

/// 历史归档目录名（相对 WebDAV 目录）。
const String kHistoryDir = 'history';

/// 历史索引文件名（在 [kHistoryDir] 内）。
const String kHistoryIndexFile = 'index.json';

/// 保留的历史版本条数上限。
///
/// ⚠️ **为什么是 20 而不是可配置**：多一个设置项就多一处「用户存心把配额改小、
/// 然后某天发现老版本被自动删了」的投诉路径，而手动删历史这个动作的频率极低。
/// 嫌不够就改这一个常量。
const int kHistoryLimit = 20;

/// 版本文件名：`notebook-20261010-120000-123.json`。
///
/// 毫秒精度是刻意的：一次同步要上百毫秒，同毫秒两次归档不可能；而只到秒的话
/// 「秒内两次同步」会把前一份**静默覆盖**（PUT 同名），历史就少了一条且无人察觉。
String historyFileName(DateTime at) {
  String two(int v) => v.toString().padLeft(2, '0');
  String three(int v) => v.toString().padLeft(3, '0');

  final y = at.year.toString().padLeft(4, '0');
  final date = '$y${two(at.month)}${two(at.day)}';
  final time = '${two(at.hour)}${two(at.minute)}${two(at.second)}';
  return 'notebook-$date-$time-${three(at.millisecond)}.json';
}