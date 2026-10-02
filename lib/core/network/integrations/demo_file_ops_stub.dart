import 'package:flutter/material.dart';

/// Web 回退：没有文件系统可以写入临时文件，Dio 的 `download()` 无法像
/// 在其他平台上那样将任意字节保存到磁盘（浏览器只能触发用户可见的保存对话框）。
/// 此演示仅在非 Web 平台上提供。
Future<String> writeUploadDemoFile() {
  throw UnsupportedError(
    'This demo writes a temp file to disk and is not available on web.',
  );
}

int demoFileSizeBytes(String path) => 0;

Future<String> demoTempPath(String filename) {
  throw UnsupportedError('There is no temp directory to save into on web.');
}

Widget buildDownloadedImage(String path, {double height = 200}) =>
    const SizedBox.shrink();
