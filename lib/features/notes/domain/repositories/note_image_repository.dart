import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';

/// 从系统里取图片进笔记。实现在 data 层（`NoteImageRepositoryImpl`）。
///
/// 单实现也保留接口：`presentation` ⛔ 不 import `data`，应用层拿不到实现类，
/// 这个抽象是把图片数据接进业务层的唯一入口。
abstract interface class NoteImageRepository {
  /// 唤系统文件选择器挑图片，返回可直接内嵌进正文的 [NoteImage]。
  ///
  /// [compress] = true 时每张图都压成 JPEG（`NoteImage.compressed*` 系列常量给
  /// 目标值），不看原始大小；false 时原图直返。
  ///
  /// 用户取消选择 → `Right([])`（不是 Failure，静默返回）。
  /// 读到 / 压缩失败 → `Left(ImageFailure)`。
  /// 超过 [NoteImage.maxSingleBytes] 或 [NoteImage.maxTotalBytes] →
  /// `Left(ImageFailure)`，message 要能直接进 Snackbar。
  Future<Either<Failure, List<NoteImage>>> pickImages({
    required bool compress,
  });
}
