import 'package:mynote/core/fonts/font_registrar.dart';

/// 测试替身：`DynamicFont.url(...).load()` 是静态调用，真跑会联网下载字体文件。
///
/// 单测与 widget 测试里，凡是可能触发字体加载的路径都注入它
/// （`fontLoaderServiceProvider.overrideWithValue(FontLoaderService(...))`）。
class FakeFontRegistrar implements FontRegistrar {
  FakeFontRegistrar({this.succeeds = true});

  /// 下一次（以及后续）注册的成功与否。测试可在中途翻转它验证重试。
  bool succeeds;

  /// 收到过的族名，按调用顺序。用来断言「只注册一次」。
  final List<String> registered = <String>[];

  @override
  Future<bool> register({
    required String fontFamily,
    required String url,
  }) async {
    registered.add(fontFamily);
    return succeeds;
  }
}
