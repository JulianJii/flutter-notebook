import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 快照落地的两个动作：**导出 = 写临时文件 + 系统分享，导入 = 选文件 + 读文本**。
///
/// 全 App 唯一碰 `share_plus` / `file_picker` / `path_provider` 的地方：data 层
/// 不 import Flutter，所以字节与磁盘的这段路只能走 presentation。
///
/// 两个函数都是**顶层函数**而非 provider：无状态、无依赖，挂一个 provider 只是
/// 为它多生成一份 codegen。

/// 快照文件名。带日期，用户存下来能一眼看出是哪天的（`SharePlus` 的分享目标
/// 常把文件名直接暴露给用户）。
String snapshotFileName(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return 'notebook-$y$m$d.json';
}

/// 写临时文件并调起系统分享面板。存到哪由用户自己选（相册 / 网盘 / 微信…）。
Future<void> shareSnapshotJson(String json, String fileName) async {
  final directory = await getTemporaryDirectory();
  final file = File(p.join(directory.path, fileName));
  await file.writeAsString(json);
  await SharePlus.instance.share(
    ShareParams(files: <XFile>[XFile(file.path)], subject: fileName),
  );
}

/// 选一个 `.json` 文件并读出文本。用户取消 → `null`。
///
/// ⛔ **这里不设体积上限**：上限是「本应用的快照能有多大」的性质，属
/// `BackupRepositoryImpl._decode`，那里一处管住文件导入、WebDAV 远端与局域网
/// 同步三条路径（远端文件此前完全没有上限）。
Future<String?> pickSnapshotJson() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const <String>['json'],
  );
  // 用户取消 → 空列表。
  if (files.isEmpty) return null;

  // `readAsBytes()` 跨平台：本地路径 / blob / content URI 怎么读由平台实现负责，
  // 这里不碰 `path`（Web 上它是 null）。
  return utf8.decode(await files.first.readAsBytes());
}
