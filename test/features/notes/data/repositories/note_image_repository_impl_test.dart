import 'dart:io';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/data/repositories/note_image_repository_impl.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';
import 'package:path/path.dart' as p;

class _MockImagePicker extends Mock implements ImagePicker {}

/// 一律用 `compress: false` 跑（压缩走 `flutter_image_compress` 平台通道，测不了），
/// 这条链路要验的是「多选 → 字节上限 → MIME」。
void main() {
  late _MockImagePicker picker;
  late NoteImageRepositoryImpl repo;

  setUp(() {
    picker = _MockImagePicker();
    repo = NoteImageRepositoryImpl(picker: picker);
  });

  void stub(List<XFile> files) {
    when(
      () => picker.pickMultiImage(requestFullMetadata: false),
    ).thenAnswer((_) async => files);
  }

  XFile image(int bytes) =>
      XFile.fromData(Uint8List(bytes), mimeType: 'image/jpeg', name: 'a.jpg');

  /// 取出 Failure；是 Right 就当场炸，不给「断言凑巧通过」留缝。
  Failure leftOf(Either<Failure, List<NoteImage>> result) =>
      result.fold((Failure f) => f, (_) => fail('应当是 Left，实际是 Right'));

  test('多选：选 N 张就返回 N 张，按原顺序', () async {
    stub(<XFile>[image(3), image(4), image(5)]);

    final images = (await repo.pickImages(
      compress: false,
    )).getOrElse((_) => fail('应当是 Right'));

    expect(images.map((NoteImage i) => i.bytes.length), <int>[3, 4, 5]);
  });

  test('用户取消 → Right([])，不是 Failure', () async {
    stub(<XFile>[]);

    final images = (await repo.pickImages(
      compress: false,
    )).getOrElse((_) => fail('应当是 Right'));

    expect(images, isEmpty);
  });

  test('单张超上限 → ImageFailure', () async {
    stub(<XFile>[image(NoteImage.maxSingleBytes + 1)]);

    expect(leftOf(await repo.pickImages(compress: false)), isA<ImageFailure>());
  });

  test('多张累加超总量上限 → ImageFailure', () async {
    stub(<XFile>[
      image(NoteImage.maxSingleBytes),
      image(NoteImage.maxTotalBytes),
    ]);

    expect(leftOf(await repo.pickImages(compress: false)), isA<ImageFailure>());
  });

  test('插件抛异常 → ImageFailure（不是把异常抛给调用方）', () async {
    when(
      () => picker.pickMultiImage(requestFullMetadata: false),
    ).thenThrow(Exception('no picker'));

    expect(leftOf(await repo.pickImages(compress: false)), isA<ImageFailure>());
  });

  // ---- 桌面拖入：imagesFromPaths（与 pickImages 共用上限校验与压缩）----

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mynote_drop_test');
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  /// 落一个真文件，返回路径 —— 这条路读的是文件系统，不是内存里的 XFile。
  String file(String name, int bytes) {
    final target = File(p.join(tempDir.path, name));
    target.writeAsBytesSync(Uint8List(bytes));
    return target.path;
  }

  test('拖入：按扩展名认 MIME，按传入顺序返回', () async {
    final images = (await repo.imagesFromPaths(<String>[
      file('a.png', 3),
      file('b.jpg', 4),
    ], compress: false)).getOrElse((_) => fail('应当是 Right'));

    expect(images.map((NoteImage i) => i.bytes.length), <int>[3, 4]);
    expect(images.map((NoteImage i) => i.mime), <String>[
      'image/png',
      'image/jpeg',
    ]);
  });

  test('拖入空列表 → Right([])', () async {
    final images = (await repo.imagesFromPaths(
      const <String>[],
      compress: false,
    )).getOrElse((_) => fail('应当是 Right'));

    expect(images, isEmpty);
  });

  test('拖入：单张超上限 → ImageFailure', () async {
    final result = await repo.imagesFromPaths(<String>[
      file('big.png', NoteImage.maxSingleBytes + 1),
    ], compress: false);

    expect(leftOf(result), isA<ImageFailure>());
  });

  test('拖入：文件不存在 → ImageFailure（不是把异常抛给调用方）', () async {
    final result = await repo.imagesFromPaths(<String>[
      p.join(tempDir.path, 'missing.png'),
    ], compress: false);

    expect(leftOf(result), isA<ImageFailure>());
  });
}
