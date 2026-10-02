import 'dart:async';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/images/debug_image_processor.dart';
import 'package:init/core/images/image_processor.dart';
import 'package:init/core/storage/cache_manager.dart';

/// 图像处理器 Provider
final imageProcessorProvider = Provider<ImageProcessor>((ref) {
  return DebugImageProcessor();
});

/// 高级图像处理配置
class AdvancedImageConfig {
  /// 是否在本地缓存图像
  final bool enableCaching;

  /// 是否启用自动图像缩放
  final bool enableAutoResize;

  /// 自动缩放图像的最大宽度
  final int? maxWidth;

  /// 自动缩放图像的最大高度
  final int? maxHeight;

  /// JPEG 或 WebP 压缩的默认质量（0-100）
  final int defaultQuality;

  /// 是否启用模糊预览缩略图
  final bool enableBlurUpPreview;

  /// 模糊预览缩略图的尺寸
  final int blurUpPreviewSize;

  /// 默认图像格式
  final ImageFormat defaultFormat;

  const AdvancedImageConfig({
    this.enableCaching = true,
    this.enableAutoResize = true,
    this.maxWidth,
    this.maxHeight,
    this.defaultQuality = 85,
    this.enableBlurUpPreview = true,
    this.blurUpPreviewSize = 20,
    this.defaultFormat = ImageFormat.jpeg,
  });
}

/// 高级图像配置 Provider
final advancedImageConfigProvider = Provider<AdvancedImageConfig>((ref) {
  return const AdvancedImageConfig();
});

/// 已解码图像的内存缓存
final imageMemoryCacheProvider = Provider<CacheManager<ui.Image>>((ref) {
  return CacheManager<ui.Image>(maxItems: 100);
});

/// 图像缓存键 Provider
final imageKeyProvider = Provider.family<String, String>((ref, imageUrl) {
  final config = ref.watch(advancedImageConfigProvider);

  // 创建包含相关尺寸参数的缓存键
  String key = imageUrl;
  if (config.enableAutoResize &&
      (config.maxWidth != null || config.maxHeight != null)) {
    key += "_w${config.maxWidth ?? 'auto'}_h${config.maxHeight ?? 'auto'}";
  }

  return key;
});

/// 支持缓存、处理和占位符的高级图像 widget
class AdvancedImage extends ConsumerStatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useThumbnailPreview;
  final Duration fadeInDuration;
  final Color? placeholderColor;

  const AdvancedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useThumbnailPreview = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholderColor,
  });

  @override
  ConsumerState<AdvancedImage> createState() => _AdvancedImageState();
}

class _AdvancedImageState extends ConsumerState<AdvancedImage> {
  bool _loading = true;
  bool _error = false;
  ImageProvider? _imageProvider;
  ImageProvider? _thumbnailProvider;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(AdvancedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      // 在真实实现中，这里会处理网络图像、缩放等
      // 目前，我们仅使用一个简单的 NetworkImage
      final imageProvider = NetworkImage(widget.imageUrl);

      // 模拟加载缩略图
      if (widget.useThumbnailPreview) {
        _thumbnailProvider = NetworkImage(
          widget.imageUrl,
        ); // 在真实应用中，这里会是一个小尺寸版本
        setState(() {}); // 刷新以显示缩略图
      }

      // 模拟图像加载延迟
      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _imageProvider = imageProvider;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load image: $e');
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error && widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    if (_loading && _thumbnailProvider == null) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: widget.placeholderColor ?? Colors.grey.shade200,
          );
    }

    if (_loading && _thumbnailProvider != null) {
      return Stack(
        children: [
          Image(
            image: _thumbnailProvider!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      );
    }

    return FadeInImage(
      placeholder: _thumbnailProvider ?? MemoryImage(Uint8List.fromList([])),
      image: _imageProvider!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: widget.fadeInDuration,
      imageErrorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.red.withValues(alpha: 0.1),
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.red),
              ),
            );
      },
    );
  }
}
