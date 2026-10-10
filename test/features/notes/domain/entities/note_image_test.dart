import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';

void main() {
  final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

  test('embedData → tryFromEmbedData 是 round-trip', () {
    final image = NoteImage(bytes: bytes, mime: 'image/png');

    expect(
      image.embedData,
      'data:image/png;base64,${base64Encode(bytes)}',
      reason: '带 data URI 前缀，渲染侧不必猜图片格式',
    );

    final parsed = NoteImage.tryFromEmbedData(image.embedData)!;
    expect(parsed.mime, 'image/png');
    // `Uint8List` 不重写 `==`，比内容要用 matcher。
    expect(parsed.bytes, orderedEquals(bytes));
  });

  group('解不出来的 payload 一律返回 null（不崩笔记详情页）', () {
    for (final bad in <Object?>[
      null,
      42,
      '',
      'https://example.com/a.png',
      'not-a-data-uri',
      'data:image/png,${base64Encode(bytes)}', // 缺 ;base64
      'data:text/plain;base64,${base64Encode(bytes)}', // 不是图片
      'data:image/png;base64,!!!not base64!!!',
    ]) {
      test('$bad', () => expect(NoteImage.tryFromEmbedData(bad), isNull));
    }
  });

  test('单张上限 < 总量上限', () {
    expect(NoteImage.maxSingleBytes < NoteImage.maxTotalBytes, isTrue);
  });
}
