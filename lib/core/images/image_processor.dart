import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// 图像处理与操作接口
abstract class ImageProcessor {
  /// 将图像缩放到给定尺寸
  Future<Uint8List> resize({
    required Uint8List imageData,
    required int width,
    required int height,
    bool maintainAspectRatio = true,
  });

  /// 压缩图像以减小文件体积
  Future<Uint8List> compress({
    required Uint8List imageData,
    required int quality,
  });

  /// 将图像裁剪到给定矩形区域
  Future<Uint8List> crop({
    required Uint8List imageData,
    required Rect cropRect,
  });

  /// 对图像应用模糊效果
  Future<Uint8List> applyBlur({
    required Uint8List imageData,
    required double sigma,
  });

  /// 将图像转换为灰度
  Future<Uint8List> toGrayscale({required Uint8List imageData});

  /// 获取图像的尺寸
  Future<Size> getImageDimensions(Uint8List imageData);

  /// 将图像转换为特定格式
  Future<Uint8List> convertFormat({
    required Uint8List imageData,
    required ImageFormat format,
    int quality = 95,
  });

  /// 为图像生成缩略图
  Future<Uint8List> generateThumbnail({
    required Uint8List imageData,
    required int maxDimension,
    int quality = 80,
  });
}

/// 图像文件格式
enum ImageFormat { jpeg, png, webp }

/// 用于处理图像尺寸的辅助类
class Size {
  final int width;
  final int height;

  const Size(this.width, this.height);

  @override
  String toString() => 'Size($width x $height)';
}

/// 用于定义裁剪矩形的辅助类
class Rect {
  final int x;
  final int y;
  final int width;
  final int height;

  const Rect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'Rect(x: $x, y: $y, width: $width, height: $height)';
}
