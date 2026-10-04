import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 两个 ARB 的顶层 key 集合必须完全一致。
/// 命名说明：测的是一对 ARB 文件而非单个类，故不用 <被测类>_test.dart 约定。
void main() {
  test('intl_zh.arb 与 intl_en.arb 的 key 集合一致', () {
    final zh = _keysOf('lib/l10n/arb/intl_zh.arb');
    final en = _keysOf('lib/l10n/arb/intl_en.arb');

    expect(zh, isNotEmpty);
    expect(en, containsAll(zh), reason: 'en.arb 缺少 zh.arb 的 key');
    expect(zh, containsAll(en), reason: 'zh.arb 缺少 en.arb 的 key');
  });

  test('ARB 不含重复 key', () {
    for (final path in const [
      'lib/l10n/arb/intl_zh.arb',
      'lib/l10n/arb/intl_en.arb',
    ]) {
      final keys = _keysOf(path);
      expect(_declaredKeyCount(path), keys.length, reason: '$path 有重复 key');
    }
  });
}

/// 读取 ARB 的顶层 key（跳过 @@locale 与 @元数据块）。
Set<String> _keysOf(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return raw.keys.where((k) => !k.startsWith('@')).toSet();
}

/// 逐行统计非元数据 key 的声明次数（jsonDecode 会静默丢弃重复键，故不能用它查重）。
int _declaredKeyCount(String path) {
  var count = 0;
  for (final line in File(path).readAsLinesSync()) {
    if (RegExp(r'^\s{2}"(?!@)[^"]+"\s*:').hasMatch(line)) count++;
  }
  return count;
}
