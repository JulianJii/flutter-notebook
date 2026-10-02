import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

/// 用于图像占位符的显示微光效果（shimmer）的 widget
class ShimmerPlaceholder extends StatelessWidget {
  /// 占位符的宽度
  final double? width;

  /// 占位符的高度
  final double? height;

  /// 占位符的形状
  final BoxShape shape;

  /// 当形状为 BoxShape.rectangle 时的圆角半径
  final BorderRadius? borderRadius;

  /// 微光效果的基础颜色
  final Color baseColor;

  /// 微光效果的高亮颜色
  final Color highlightColor;

  /// 一次微光动画循环的时长
  final Duration duration;

  /// 为图像创建带动画加载效果的微光占位符
  const ShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: duration,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: shape,
          color: baseColor,
          borderRadius:
              shape == BoxShape.rectangle
                  ? borderRadius ?? BorderRadius.zero
                  : null,
        ),
      ),
    );
  }
}

/// 图像卡片的骨架占位符
class ImageCardSkeleton extends StatelessWidget {
  /// 卡片的宽度
  final double? width;

  /// 卡片的高度
  final double? height;

  /// 卡片的圆角半径
  final BorderRadius borderRadius;

  /// 是否显示标题骨架
  final bool showTitle;

  /// 是否显示描述骨架
  final bool showDescription;

  /// 是否显示页脚骨架
  final bool showFooter;

  /// 为图像卡片创建骨架占位符
  const ImageCardSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showTitle = true,
    this.showDescription = false,
    this.showFooter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ShimmerPlaceholder(
              width: double.infinity,
              borderRadius: BorderRadius.only(
                topLeft: borderRadius.topLeft,
                topRight: borderRadius.topRight,
              ),
            ),
          ),
          if (showTitle || showDescription || showFooter)
            Expanded(
              flex: showDescription ? 2 : 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTitle) ...[
                      const SizedBox(height: 4),
                      ShimmerPlaceholder(
                        width: width != null ? width! * 0.7 : 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    if (showDescription) ...[
                      const SizedBox(height: 8),
                      ShimmerPlaceholder(
                        width: double.infinity,
                        height: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      ShimmerPlaceholder(
                        width: width != null ? width! * 0.9 : 160,
                        height: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    if (showFooter) ...[
                      const Spacer(),
                      ShimmerPlaceholder(
                        width: width != null ? width! * 0.4 : 80,
                        height: 10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 在卡片和圆形头像之间交替显示的占位符 widget
class ImagePlaceholderGrid extends StatelessWidget {
  /// 网格中占位符的数量
  final int itemCount;

  /// 网格中的列数
  final int crossAxisCount;

  /// 网格单元格的宽高比
  final double childAspectRatio;

  /// 项目之间的水平间距
  final double mainAxisSpacing;

  /// 项目之间的垂直间距
  final double crossAxisSpacing;

  /// 创建微光占位符网格
  const ImagePlaceholderGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
    this.mainAxisSpacing = 16.0,
    this.crossAxisSpacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // 在不同的占位符类型之间交替
        if (index % 3 == 0) {
          return const ShimmerPlaceholder(shape: BoxShape.circle);
        }
        return ImageCardSkeleton(
          showTitle: true,
          showDescription: index % 2 == 0,
          showFooter: index % 4 == 0,
        );
      },
    );
  }
}
