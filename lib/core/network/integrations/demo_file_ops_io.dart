import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// 将生成的文本文件写入临时目录，供上传演示发送，并返回其路径。
Future<String> writeUploadDemoFile() async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/template_upload_demo.txt');
  await file.writeAsString('Sample upload content. ' * 5000);
  return file.path;
}

int demoFileSizeBytes(String path) => File(path).lengthSync();

/// 临时目录下 [filename] 的路径，供下载演示保存使用。
Future<String> demoTempPath(String filename) async {
  final dir = await getTemporaryDirectory();
  return '${dir.path}/$filename';
}

/// 渲染下载演示刚保存的文件。
Widget buildDownloadedImage(String path, {double height = 200}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(File(path), height: height),
  );
}
