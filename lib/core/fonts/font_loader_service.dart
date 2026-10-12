import 'app_font.dart';
import 'font_registrar.dart';

/// 字体加载器：一个 **id → 在途/已完成** 的 `Future` 表，同时承担三件事 ——
/// 已注册去重（同一字体不重复注册）、并发合并（同一字体同时被两处请求只下载一次）、
/// 结果缓存（成功后条目保留，等价于「已加载集合」）。
///
/// ⛔ **不缓存失败**：失败的条目会被移除，下次选中同一字体可以重试
/// （网络恢复后不必重启 App）。
class FontLoaderService {
  FontLoaderService(this._registrar);

  final FontRegistrar _registrar;

  final Map<String, Future<bool>> _pending = <String, Future<bool>>{};

  /// 确保 [font] 已注册。成功 → true；失败 → false（并允许下次重试）。
  Future<bool> ensureLoaded(AppFont font) {
    final pending = _pending[font.id];
    if (pending != null) return pending;

    final future = _registrar
        .register(fontFamily: font.fontFamily, url: font.downloadUrl)
        .then((ok) {
          // `.then` 总在微任务里跑，这里的 remove 一定晚于下面的赋值。
          if (!ok) _pending.remove(font.id);
          return ok;
        });
    _pending[font.id] = future;
    return future;
  }
}
