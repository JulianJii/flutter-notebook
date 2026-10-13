import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:mynote/features/notes/domain/utils/note_import.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 快照落地的两个动作：**导出 = 写临时文件 + 系统分享，导入 = 选文件 + 读文本**。
/// 文章导入（[pickArticleFiles]）复用其中的「选文件 + 读文本」那半条路。
///
/// 全 App 唯一碰 `share_plus` / `file_picker` / `path_provider` 的地方：data 层
/// 不 import Flutter，所以字节与磁盘的这段路只能走 presentation。
///
/// 几个函数都是**顶层函数**而非 provider：无状态、无依赖，挂一个 provider 只是
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

/// Markdown 导出的文件名。与 [snapshotFileName] 同款命名法。
String markdownFileName(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return 'notebook-$y$m$d.md';
}

/// 把 Markdown 写成临时文件并调起系统分享面板。与 [shareSnapshotJson] 同一条路，
/// 只是换了扩展名 —— 复用同一个分享动作而不是新开一个。
Future<void> shareMarkdown(String markdown, String fileName) async {
  final directory = await getTemporaryDirectory();
  final file = File(p.join(directory.path, fileName));
  await file.writeAsString(markdown, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: <XFile>[XFile(file.path)], subject: fileName),
  );
}

/// 一个被选中的文章文件。[content] 为 `null` = 这个文件读不出文本。
typedef PickedArticle = ({String name, String? content});

/// 选文章文件（`.md` / `.markdown` / `.html` / `.htm`）并读出文本。
/// 用户取消 → 空列表。
///
/// ⚠️ 一次可以选多个 —— `FilePicker.pickFiles` 没有单选的开关，它本来就让用户
/// 多选，所以结果必然是**一批**文件、每个文件一篇笔记。
///
/// ⚠️ 单个文件读不出文本时 [PickedArticle.content] 给 `null` 而**不是抛**：一个
/// 坏文件不该让整批选择失败，调用方据此把它记成该文件自己的失败原因。
Future<List<PickedArticle>> pickArticleFiles() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: NoteImport.extensions,
  );
  final articles = <PickedArticle>[];
  for (final file in files) {
    articles.add((
      name: file.name,
      content: _decodeArticleText(await file.readAsBytes()),
    ));
  }
  return articles;
}

/// 字节 → 文本。**只认 UTF-8**（顺手削掉 BOM）。
///
/// ⛔ 不做编码探测：多数中文 `.md` 是 GBK 编码，但那要引一个探测包，且猜错比
/// 报错更糟。解不出来就返回 `null`，让用户看到「不是 UTF-8」而不是一堆乱码。
///
/// BOM 必须削：带 BOM 的 `# 标题` 会被 Markdown 解析器当成普通段落，标题就丢了
/// （Windows 上存出来的 `.md` 常带 BOM）。
String? _decodeArticleText(Uint8List bytes) {
  try {
    final text = utf8.decode(bytes);
    return text.startsWith('\uFEFF') ? text.substring(1) : text;
  } on FormatException {
    return null;
  }
}
