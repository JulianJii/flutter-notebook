import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';

void main() {
  test('空串 → 只有尾换行的空文档（WordCounter 视作 0 字）', () {
    expect(NoteDelta.plainText(''), '\n');
  });

  test('旧数据（纯文本）原样还原，只多一个 Quill 要求的尾换行', () {
    expect(NoteDelta.plainText('三花聚顶本是幻'), '三花聚顶本是幻\n');
  });

  test('Delta JSON 还原纯文本，embed 不参与拼接', () {
    const delta = '[{"insert":"前"},{"insert":{"image":"a.png"}},'
        '{"insert":"后\\n"}]';

    expect(NoteDelta.plainText(delta), '前后\n');
  });

  test('非法 JSON 不抛，按纯文本处理', () {
    expect(NoteDelta.plainText('{不是 json'), '{不是 json\n');
  });

  test('encode → decode 往返，纯文本不丢', () {
    final encoded = NoteDelta.encode(NoteDelta.decode('普通正文'));

    expect(NoteDelta.plainText(encoded).trim(), '普通正文');
  });

  test('decode 给出的文档以换行结尾（Quill 的硬要求）', () {
    expect(
      jsonEncode(NoteDelta.decode('结尾无换行').toJson()),
      '[{"insert":"结尾无换行\\n"}]',
    );
  });

  test('memo 不改结果：重复调用同值，且撞上限清空后依然同值', () {
    // 「每卡每次 build 都重解码」是这层 memo 的唯一理由，正确性必须与无缓存
    // 完全一致 —— 所以覆盖两条路径：命中缓存、缓存被清空后重算。
    for (var i = 0; i < 80; i++) {
      expect(NoteDelta.plainText('第 $i 条\n'), '第 $i 条\n');
    }
    expect(NoteDelta.plainText('第 0 条\n'), '第 0 条\n');
  });
}
