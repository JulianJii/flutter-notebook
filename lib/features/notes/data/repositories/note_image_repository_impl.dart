import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';
import 'package:mynote/features/notes/domain/repositories/note_image_repository.dart';

/// `NoteImageRepository` 的唯一实现：**选文件 → 校验上限 → （可选）压缩**。
///
/// ⛔ **不建 datasource**：这里就三件事（挑、压、转），拆一层只多两个文件和一份
/// 转发代码。⛔ 也不碰 `path_provider` —— 图片不落文件系统，整段路都在内存里
/// 走完，最后变成 embed 里的一个字符串。
class NoteImageRepositoryImpl implements NoteImageRepository {
  @override
  Future<Either<Failure, List<NoteImage>>> pickImages({
    required bool compress,
  }) async {
    try {
      final picked = await FilePicker.pickFiles(type: FileType.image);
      if (picked.isEmpty) return const Right(<NoteImage>[]); // 用户取消

      // 先只看 size，超限就直接拒 —— **不先把字节读进来**。多选时每个文件都会
      // 被完整读进内存，先读再判会让「一次选了 50 张」变成一次 OOM。
      var total = 0;
      for (final file in picked) {
        final size = file.lengthSync() ?? await file.length() ?? 0;
        if (size > NoteImage.maxSingleBytes) {
          return const Left(ImageFailure(message: 'single image too large'));
        }
        total += size;
        if (total > NoteImage.maxTotalBytes) {
          return const Left(ImageFailure(message: 'total images too large'));
        }
      }

      final images = <NoteImage>[];
      for (final file in picked) {
        final bytes = await file.readAsBytes();
        images.add(await _encode(bytes, _mimeOf(file.extension), compress));
      }
      return Right(images);
    } on Object catch (e) {
      // file_picker 在无权限 / 平台未实现时抛，压缩遇到解不了的格式也抛。
      // ⚠️ 不用 debugPrint（data 层禁 Flutter），原因放进 Failure 的 message。
      return Left(ImageFailure(message: 'pick failed: $e'));
    }
  }

  /// [compress] = true 时每张图都压，不看原始大小。压完一律是 JPEG（PNG 的透明
  /// 通道会变黑，这是 JPEG 的固有行为，不是 bug）。
  ///
  /// 压缩失败退回原字节：让用户拿到一张大图，好过让这次插入直接失败。
  Future<NoteImage> _encode(Uint8List bytes, String mime, bool compress) async {
    if (!compress) return NoteImage(bytes: bytes, mime: mime);
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: NoteImage.compressedMaxDimension,
        minHeight: NoteImage.compressedMaxDimension,
        quality: NoteImage.compressedQuality,
        format: CompressFormat.jpeg,
      );
      return NoteImage(bytes: compressed, mime: 'image/jpeg');
    } on Object {
      return NoteImage(bytes: bytes, mime: mime);
    }
  }
}

/// 扩展名 → MIME。认不出来的一律当 JPEG：选择器已按 `FileType.image` 过滤，
/// 已知静态图后缀就这几个；退回 JPEG 而不是报错，是为了别让用户为 HEIC 这类
/// 冷门格式白挑一次。
String _mimeOf(String? extension) => switch (extension?.toLowerCase()) {
  'png' => 'image/png',
  'gif' => 'image/gif',
  'webp' => 'image/webp',
  'bmp' => 'image/bmp',
  _ => 'image/jpeg',
};
