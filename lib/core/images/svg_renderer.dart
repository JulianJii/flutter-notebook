import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/storage/cache_manager.dart';

/// SVG 缓存 Provider
final svgCacheProvider = Provider<CacheManager<ui.Image>>((ref) {
  return CacheManager<ui.Image>(maxItems: 50);
});

/// 处理 SVG 渲染的服务
class SvgRenderer {
  final CacheManager<ui.Image> _cache;

  /// 使用给定缓存创建新的 SVG 渲染器
  SvgRenderer(this._cache);

  /// 将资源中的 SVG 文件渲染为 Flutter 图像
  Future<ui.Image> renderSvgAsset(
    String assetName, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    BlendMode colorBlendMode = BlendMode.srcIn,
    String? semanticsLabel,
  }) async {
    // 根据参数创建缓存键
    final cacheKey =
        '${assetName}_${width}_${height}_${color?.hashCode}_${colorBlendMode.index}';

    // 检查 SVG 是否已被缓存
    final cachedImage = _cache.getItem(cacheKey);
    if (cachedImage != null) {
      return cachedImage;
    }

    // 对于真实实现，我们会使用 flutter_svg 或类似的包
    // 这是加载 PNG 占位符的调试实现

    debugPrint('🖼️ Rendering SVG asset: $assetName');

    // 模拟 SVG 渲染时间
    await Future.delayed(const Duration(milliseconds: 300));

    // 创建一个简单的彩色方块作为 SVG 的占位符
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color ?? Colors.blue
      ..style = PaintingStyle.fill;

    // 确定尺寸
    final size = Size(width ?? 100, height ?? 100);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 绘制文本以表明这是调试渲染器
    if (kDebugMode) {
      const textStyle = TextStyle(color: Colors.white, fontSize: 14);
      final textSpan = TextSpan(text: 'SVG\nPlaceholder', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    // 缓存渲染后的 SVG
    _cache.setItem(cacheKey, image);

    return image;
  }

  /// 将网络中的 SVG 文件渲染为 Flutter 图像
  Future<ui.Image> renderSvgNetwork(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
    BlendMode colorBlendMode = BlendMode.srcIn,
    Map<String, String>? headers,
    String? semanticsLabel,
  }) async {
    // 根据参数创建缓存键
    final cacheKey =
        '${url}_${width}_${height}_${color?.hashCode}_${colorBlendMode.index}';

    // 检查 SVG 是否已被缓存
    final cachedImage = _cache.getItem(cacheKey);
    if (cachedImage != null) {
      return cachedImage;
    }

    // 对于真实实现，我们会使用 flutter_svg 或类似的包
    // 这是创建占位符的调试实现

    debugPrint('🖼️ Rendering SVG from network: $url');

    // 模拟网络加载和 SVG 渲染时间
    await Future.delayed(const Duration(milliseconds: 600));

    // 创建一个简单的彩色方块作为 SVG 的占位符
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = color ?? Colors.green
      ..style = PaintingStyle.fill;

    // 确定尺寸
    final size = Size(width ?? 100, height ?? 100);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 绘制文本以表明这是网络 SVG 占位符
    if (kDebugMode) {
      const textStyle = TextStyle(color: Colors.white, fontSize: 14);
      final textSpan = TextSpan(
        text: 'Network SVG\nPlaceholder',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(
        canvas,
        Offset(
          size.width / 2 - textPainter.width / 2,
          size.height / 2 - textPainter.height / 2,
        ),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    // 缓存渲染后的 SVG
    _cache.setItem(cacheKey, image);

    return image;
  }
}

/// SVG 渲染器 Provider
final svgRendererProvider = Provider<SvgRenderer>((ref) {
  final cache = ref.watch(svgCacheProvider);
  return SvgRenderer(cache);
});

/// 渲染 SVG 文件的 widget
class SvgImage extends ConsumerWidget {
  final String source;
  final bool isAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final BlendMode colorBlendMode;
  final String? semanticsLabel;
  final Map<String, String>? headers;
  final Widget? placeholder;
  final Widget? errorWidget;

  /// 创建显示 SVG 图像的 widget
  const SvgImage({
    super.key,
    required this.source,
    this.isAsset = false,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.semanticsLabel,
    this.headers,
    this.placeholder,
    this.errorWidget,
  });

  /// 创建显示来自网络 URL 的 SVG 图像的 widget
  const SvgImage.network(
    String url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.semanticsLabel,
    this.headers,
    this.placeholder,
    this.errorWidget,
  }) : source = url,
       isAsset = false;

  /// 创建显示来自资源包中的 SVG 图像的 widget
  const SvgImage.asset(
    String assetName, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.semanticsLabel,
    this.placeholder,
    this.errorWidget,
  }) : source = assetName,
       isAsset = true,
       headers = null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renderer = ref.watch(svgRendererProvider);

    return FutureBuilder<ui.Image>(
      future: isAsset
          ? renderer.renderSvgAsset(
              source,
              width: width,
              height: height,
              fit: fit,
              color: color,
              colorBlendMode: colorBlendMode,
              semanticsLabel: semanticsLabel,
            )
          : renderer.renderSvgNetwork(
              source,
              width: width,
              height: height,
              fit: fit,
              color: color,
              colorBlendMode: colorBlendMode,
              headers: headers,
              semanticsLabel: semanticsLabel,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ??
              SizedBox(
                width: width,
                height: height,
                child: const Center(child: CircularProgressIndicator()),
              );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return errorWidget ??
              SizedBox(
                width: width,
                height: height,
                child: const Icon(Icons.error_outline, color: Colors.red),
              );
        }

        return RawImage(
          image: snapshot.data,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }
}
