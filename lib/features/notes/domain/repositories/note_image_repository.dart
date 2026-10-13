import 'package:fpdart/fpdart.dart';
import 'package:mynote/core/error/failures.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';

/// 从系统里取图片进笔记。实现在 data 层（`NoteImageRepositoryImpl`）。
///
/// 单实现也保留接口：`presentation` ⛔ 不 import `data`，应用层拿不到实现类，
/// 这个抽象是把图片数据接进业务层的唯一入口。
abstract interface class NoteImageRepository {
  /// 唤系统相册**多选**图片，返回可直接内嵌进正文的 [NoteImage]（按用户选择顺序）。
  ///
  /// [compress] = true 时每张图都压成 JPEG（`NoteImage.compressed*` 系列常量给
  /// 目标值），不看原始大小；false 时原图直返。
  ///
  /// 用户取消选择 → `Right([])`（不是 Failure，静默返回）。
  /// 读到 / 压缩失败 → `Left(ImageFailure)`。
  /// 超过 [NoteImage.maxSingleBytes] 或 [NoteImage.maxTotalBytes] →
  /// `Left(ImageFailure)`，message 要能直接进 Snackbar。
  Future<Either<Failure, List<NoteImage>>> pickImages({required bool compress});

  /// 把**已经在手上的文件路径**读成可内嵌的 [NoteImage]（桌面拖入图片走这条）。
  ///
  /// ⚠️ 参数是 `String` 而不是 `XFile`：domain 层禁止 Flutter / image_picker 依赖，
  /// 而拖入的文件本来就是文件系统上的真实路径，data 层自己包成 `XFile` 即可。
  ///
  /// 校验与压缩语义与 [pickImages] 逐字一致（共用同一段实现）：
  /// 空列表 → `Right([])`、超上限 / 读不出来 → `Left(ImageFailure)`。
  Future<Either<Failure, List<NoteImage>>> imagesFromPaths(
    List<String> paths, {
    required bool compress,
  });
}
