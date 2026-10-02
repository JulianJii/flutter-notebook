# 高级图像处理指南

Flutter Riverpod Clean Architecture 模板包含一个健壮的图像处理系统，用于优化图像的加载、缓存、处理和显示。本指南介绍如何使用各种图像组件和工具。

## 核心组件

### AdvancedImage Widget

`AdvancedImage` widget 提供了丰富的图像加载体验，功能包括：

- 自动缓存图像
- 加载过程中的占位符支持
- 模糊预览缩略图
- 淡入动画
- 可自定义错误 widget 的错误处理
- 可配置的图像质量和尺寸调整

```dart
AdvancedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 300,
  height: 200,
  fit: BoxFit.cover,
  placeholder: ShimmerPlaceholder(),
  errorWidget: Icon(Icons.broken_image),
  useThumbnailPreview: true,
  fadeInDuration: Duration(milliseconds: 300),
);
```

### Image Processor

`ImageProcessor` 接口提供了图像操作的方法：

- 调整图像大小
- 压缩图像
- 裁剪图像
- 应用模糊效果
- 转换为灰度图
- 获取图像尺寸
- 转换图像格式
- 生成缩略图

```dart
final processor = ref.watch(imageProcessorProvider);

// Resize an image
final resizedImage = await processor.resize(
  imageData: imageBytes,
  width: 800,
  height: 600,
  maintainAspectRatio: true,
);

// Generate a thumbnail
final thumbnail = await processor.generateThumbnail(
  imageData: imageBytes,
  maxDimension: 200,
  quality: 80,
);
```

### SVG Renderer

`SvgRenderer` 处理 SVG 渲染并支持缓存：

```dart
// Display an SVG image from assets
SvgImage.asset(
  'assets/images/icon.svg',
  width: 48,
  height: 48,
  color: Colors.blue,
);

// Display an SVG image from network
SvgImage.network(
  'https://example.com/icon.svg',
  width: 48,
  height: 48,
  color: Theme.of(context).primaryColor,
);
```

### Image Transformer

`ImageTransformer` 为图像应用视觉效果：

```dart
// Define an effect configuration
final grayscaleEffect = ImageEffectConfig(
  effectType: ImageEffectType.grayscale,
  intensity: 0.8,
);

// Apply the effect to an image
ImageTransformer(
  effect: grayscaleEffect,
  child: Image.asset('assets/images/photo.jpg'),
);

// Or use with a provider for dynamic effects
final effectProvider = Provider<ImageEffectConfig>((ref) {
  return ImageEffectConfig(
    effectType: ImageEffectType.sepia,
    intensity: 0.7,
  );
});

TransformedImage(
  child: Image.network('https://example.com/photo.jpg'),
  effectProvider: effectProvider,
);
```

### Shimmer Placeholders

带有闪烁效果的精美加载占位符：

```dart
// Simple shimmer placeholder
ShimmerPlaceholder(
  width: 200,
  height: 200,
  borderRadius: BorderRadius.circular(8),
);

// Image card skeleton with title and description
ImageCardSkeleton(
  width: 200,
  height: 300,
  showTitle: true,
  showDescription: true,
);

// Grid of placeholders for a gallery
ImagePlaceholderGrid(
  itemCount: 6,
  crossAxisCount: 2,
);
```

## 缓存系统

图像在两个层级进行缓存：

1. **内存缓存**：用于快速访问最近使用的图像
2. **磁盘缓存**：用于跨应用启动持久化存储图像

缓存配置可以自定义：

```dart
// Configure the image memory cache
final customImageCacheProvider = Provider<CacheManager<ui.Image>>((ref) {
  return CacheManager<ui.Image>(maxItems: 200);
});

// Use the custom cache
ref.read(advancedImageConfigProvider.notifier).update((state) => 
  state.copyWith(memoryCacheProvider: customImageCacheProvider)
);
```

## 最佳实践

### 图像优化

1. **使用合适的图像尺寸**：避免加载超过需要的大尺寸图像
2. **启用自动调整大小**：在 `AdvancedImageConfig` 中设置 `enableAutoResize` 为 true
3. **使用缩略图**：为列表和网格生成并显示缩略图

### 性能

1. **启用缓存**：确保 `AdvancedImageConfig` 中的 `enableCaching` 为 true
2. **使用模糊预览**：启用 `useThumbnailPreview` 以获得更好的感知性能
3. **懒加载图像**：仅在图像可见时加载

### 无障碍

1. **提供语义标签**：为屏幕阅读器添加描述性文本
2. **优雅处理错误**：始终提供有意义的错误 widget
3. **显示加载指示器**：加载过程中使用闪烁占位符

## 示例

### 基本图像画廊

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
  ),
  itemCount: images.length,
  itemBuilder: (context, index) {
    return AdvancedImage(
      imageUrl: images[index].url,
      placeholder: ShimmerPlaceholder(),
      errorWidget: Icon(Icons.broken_image),
    );
  },
);
```

### 带有效果的头像

```dart
TransformedImage(
  effectProvider: userProfileEffectProvider,
  child: AdvancedImage(
    imageUrl: user.avatarUrl,
    width: 120,
    height: 120,
    fit: BoxFit.cover,
    placeholder: ShimmerPlaceholder(shape: BoxShape.circle),
  ),
);
```

### 带有 SVG 徽章的商品图片

```dart
Stack(
  children: [
    AdvancedImage(
      imageUrl: product.imageUrl,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
    ),
    if (product.isNew)
      Positioned(
        top: 8,
        right: 8,
        child: SvgImage.asset(
          'assets/images/new_badge.svg',
          width: 40,
          height: 40,
        ),
      ),
  ],
);
```

## 高级用例

### 自定义 Image Processor

你可以创建自己的 `ImageProcessor` 接口实现：

```dart
class FirebaseImageProcessor implements ImageProcessor {
  // Implementation using Firebase ML Kit or other libraries
  // ...
}

final customImageProcessorProvider = Provider<ImageProcessor>((ref) {
  return FirebaseImageProcessor();
});
```

### 自定义效果

通过扩展 `ImageEffectType` 枚举并更新 `ImageTransformer` widget 来创建自定义图像效果：

```dart
extension CustomImageEffects on ImageEffectType {
  static const duotone = ImageEffectType.duotone;
}

// Then in your ImageTransformer implementation:
case CustomImageEffects.duotone:
  return ColorFiltered(
    colorFilter: ColorFilter.matrix(_getDuotoneMatrix(
      effect.intensity,
      effect.overlayColor ?? Colors.blue,
    )),
    child: child,
  );
```

### 预加载图像

通过在需要之前预加载图像来改善用户体验：

```dart
Future<void> prefetchImagesForGallery(List<String> imageUrls) async {
  final processor = ref.read(imageProcessorProvider);
  final cache = ref.read(imageMemoryCacheProvider);
  
  for (final url in imageUrls) {
    // Check if already cached
    final key = ref.read(imageKeyProvider(url));
    if (!cache.containsKey(key)) {
      // Fetch and cache in background
      unawaited(_fetchAndCacheImage(url, processor, cache, key));
    }
  }
}
```

## 故障排除

### 常见问题

1. **图像无法加载**：检查网络连接并验证 URL
2. **性能不佳**：减小图像尺寸或启用自动调整大小
3. **内存使用过高**：减少内存缓存大小或启用积极缓存

### 测试图像加载

在各种网络条件下测试图像加载：

```dart
// Simulate slow network
Future<void> testSlowImageLoading() async {
  final tester = await WidgetTester.create();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        imageProcessorProvider.overrideWithValue(
          SlowNetworkImageProcessor(),
        ),
      ],
      child: MyApp(),
    ),
  );
  
  // Verify loading behavior
  expect(find.byType(ShimmerPlaceholder), findsWidgets);
  await tester.pump(Duration(seconds: 5));
  expect(find.byType(ShimmerPlaceholder), findsNothing);
}
```
