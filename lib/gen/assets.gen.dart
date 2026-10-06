// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsFontsGen {
  const $AssetsFontsGen();

  /// File path: assets/fonts/.gitkeep
  String get aGitkeep => 'assets/fonts/.gitkeep';

  /// List of all assets
  List<String> get values => [aGitkeep];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// Directory path: assets/images/backgrounds
  $AssetsImagesBackgroundsGen get backgrounds =>
      const $AssetsImagesBackgroundsGen();

  /// Directory path: assets/images/en
  $AssetsImagesEnGen get en => const $AssetsImagesEnGen();

  /// Directory path: assets/images/zh
  $AssetsImagesZhGen get zh => const $AssetsImagesZhGen();
}

class $AssetsImagesBackgroundsGen {
  const $AssetsImagesBackgroundsGen();

  /// File path: assets/images/backgrounds/note_bg_blush.png
  AssetGenImage get noteBgBlush =>
      const AssetGenImage('assets/images/backgrounds/note_bg_blush.png');

  /// File path: assets/images/backgrounds/note_bg_mint.png
  AssetGenImage get noteBgMint =>
      const AssetGenImage('assets/images/backgrounds/note_bg_mint.png');

  /// File path: assets/images/backgrounds/note_bg_paper.png
  AssetGenImage get noteBgPaper =>
      const AssetGenImage('assets/images/backgrounds/note_bg_paper.png');

  /// List of all assets
  List<AssetGenImage> get values => [noteBgBlush, noteBgMint, noteBgPaper];
}

class $AssetsImagesEnGen {
  const $AssetsImagesEnGen();

  /// File path: assets/images/en/.gitkeep
  String get aGitkeep => 'assets/images/en/.gitkeep';

  /// List of all assets
  List<String> get values => [aGitkeep];
}

class $AssetsImagesZhGen {
  const $AssetsImagesZhGen();

  /// File path: assets/images/zh/.gitkeep
  String get aGitkeep => 'assets/images/zh/.gitkeep';

  /// List of all assets
  List<String> get values => [aGitkeep];
}

abstract final class Assets {
  static const $AssetsFontsGen fonts = $AssetsFontsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
