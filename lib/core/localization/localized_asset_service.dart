import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/providers/localization_providers.dart';

/// 处理应用中语言特定资源的服务
class LocalizedAssetService {
  /// 获取当前语言环境的图像路径
  /// 如果语言特定的资源不存在，则回退到英文
  static String getLocalizedImagePath(BuildContext context, String imageName) {
    final locale = Localizations.localeOf(context);
    return 'assets/images/${locale.languageCode}/$imageName';
  }

  /// 获取特定语言的图像路径
  /// 如果该语言的资源不存在，则回退到英文
  static String getImagePathForLanguage(String languageCode, String imageName) {
    return 'assets/images/$languageCode/$imageName';
  }

  /// 获取回退图像路径（通常是英文）
  static String getFallbackImagePath(String imageName) {
    return 'assets/images/en/$imageName';
  }

  /// 获取通用图像路径（不区分语言）
  static String getCommonImagePath(String imageName) {
    return 'assets/images/$imageName';
  }
}

/// 显示本地化图像的 widget
/// 如果本地化版本不存在，则回退到默认语言
class LocalizedImage extends ConsumerWidget {
  final String imageName;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;
  final bool useCommonPath;

  const LocalizedImage({
    super.key,
    required this.imageName,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.useCommonPath = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(persistentLocaleProvider);

    return Image.asset(
      useCommonPath
          ? LocalizedAssetService.getCommonImagePath(imageName)
          : LocalizedAssetService.getImagePathForLanguage(
              locale.languageCode,
              imageName,
            ),
      width: width,
      height: height,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // 如果本地化图像加载失败，尝试回退图像
        return Image.asset(
          LocalizedAssetService.getFallbackImagePath(imageName),
          width: width,
          height: height,
          fit: fit,
          color: color,
          errorBuilder: (context, error, stackTrace) {
            // 如果回退图像也失败，则使用占位符
            return Container(
              width: width,
              height: height,
              color: Colors.grey.withValues(alpha: 0.3),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      },
    );
  }
}
