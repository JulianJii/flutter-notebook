import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';
import 'package:mynote/features/notes/domain/repositories/note_image_repository.dart';
import 'package:path/path.dart' as p;

/// `NoteImageRepository` 的唯一实现：**系统相册多选 → 校验上限 → （可选）压缩**。
///
/// ⛔ **不建 datasource**：这里就三件事（挑、压、转），拆一层只多两个文件和一份
/// 转发代码。⛔ 也不碰 `path_provider` —— 图片不落我们自己的文件系统，整段路都在
/// 内存里走完，最后变成 embed 里的一个字符串。
///
class NoteImageRepositoryImpl implements NoteImageRepository {
  /// [picker] 可注入，测试用（生产永远走默认的 [ImagePicker]）。
  NoteImageRepositoryImpl({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Either<Failure, List<NoteImage>>> pickImages({
    required bool compress,
  }) async {
    try {
      // ⛔ 不传 `limit`：张数上限没稿，字节上限（`maxTotalBytes`）已经在下面兜住了。
      // `requestFullMetadata: false` → iOS 不再弹相册授权框（PHPicker 本来也不需要，
      // 但默认的 true 会多走一次 `PHPhotoLibrary` 授权）。
      final picked = await _picker.pickMultiImage(requestFullMetadata: false);
      if (picked.isEmpty) return const Right(<NoteImage>[]); // 用户取消

      // 先只看 size，超限就直接拒 —— **不先把字节读进来**。多选时每个文件都会
      // 被完整读进内存，先读再判会让「一次选了 50 张」变成一次 OOM。
      var total = 0;
      for (final file in picked) {
        final size = await file.length();
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
        images.add(await _encode(await file.readAsBytes(), _mimeOf(file), compress));
      }
      return Right(images);
    } on Object catch (e) {
      // 相册不可用 / 平台未实现 / 读取失败时插件会抛；压缩遇到解不了的格式也抛。
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

/// MIME：优先用插件给的（Android 来自 ContentResolver，最准），拿不到才退回按扩展名
/// 猜。两者都没有时一律当 JPEG —— 相册里挑的本来就是图，报错不如让用户看到图。
String _mimeOf(XFile file) {
  final given = file.mimeType;
  if (given != null && given.startsWith('image/')) return given;
  return switch (p.extension(file.path).toLowerCase()) {
    'png' => 'image/png',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    _ => 'image/jpeg',
  };
}