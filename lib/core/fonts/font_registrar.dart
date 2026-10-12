import 'package:chinese_font_library/chinese_font_library.dart';

/// 「把字体文件下载（或读本地缓存）并注册进引擎」这一动作的抽象。
///
/// ⚠️ **存在的唯一理由是可测**：`DynamicFont.url(...).load()` 是静态调用，
/// 单测里无法替换，而字体加载是本功能里唯一有分支与失败路径的逻辑。
/// 不为「以后换字体源」预留任何东西 —— 真换源时改的就是这一个实现类。
abstract interface class FontRegistrar {
  /// 成功返回 true。失败（网络不通 / 超时 / 文件损坏）返回 false，
  /// ⛔ 不抛异常：调用方只需要一个「能不能用」的答案。
  Future<bool> register({required String fontFamily, required String url});
}

/// 生产实现。`DynamicFont.url` 自带落盘缓存（`getApplicationSupportDirectory()`），
/// 同一 URL 第二次调用只读盘、不再联网。
class DynamicFontRegistrar implements FontRegistrar {
  const DynamicFontRegistrar();

  @override
  Future<bool> register({
    required String fontFamily,
    required String url,
  }) async {
    // `load()` 声明为裸 `Future`（实际给的是 bool），显式比一次更稳。
    final loaded = await DynamicFont.url(
      fontFamily: fontFamily,
      url: url,
    ).load();
    return loaded == true;
  }
}
