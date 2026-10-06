import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';

/// 笔记正文的编解码：**库里存 Quill Delta JSON**（`flutter_quill` 的唯一真相源，
/// 见 `Note.content`），而字数统计与列表摘要要的是纯文本，两者在此互转。
///
/// ⛔ 不建 UseCase：纯函数不过 Repository（`DEVELOPMENT-GUIDELINES.md` §5）。
/// ⚠️ **解码必须容错**：接富文本之前库里存的是纯文本，`Delta.fromJson` 对它会抛。
/// 解析失败一律当纯文本处理 —— 老笔记打不开就是数据丢失，用户无从补救。
abstract final class NoteDelta {
  const NoteDelta._();

  /// Delta → 落库字符串。
  static String encode(Delta delta) => jsonEncode(delta.toJson());

  /// 落库字符串 → Delta。旧数据（纯文本）与非法内容退化为单段纯文本。
  static Delta decode(String raw) {
    if (raw.isEmpty) return _empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.isEmpty) return _plain(raw);
      return Delta.fromJson(decoded);
    } on Object {
      return _plain(raw);
    }
  }

  /// 落库字符串 → 纯文本。embed（图片等）的 data 不是 String，直接跳过。
  ///
  /// **带memo**：列表每次重建都对每张可见卡片调一次（父级 rebuild → 卡片
  /// rebuild → 摘要重算），一次完整 `jsonDecode` + `Delta` 组装在长笔记上要毫秒级。
  /// key 用 raw 本身（`String.hashCode` 比解析整份 Delta 便宜两个数量级）。
  static String plainText(String raw) {
    final cached = _plainTextCache[raw];
    if (cached != null) return cached;
    final text = decode(raw)
        .toList()
        .where((op) => op.data is String)
        .map((op) => op.data as String)
        .join();
    // ponytail: 到上限就整块清空（不是 LRU）—— 换来的最坏情况只是退化成
    // 无缓存的正确结果。真的需要精确 LRU 时再换实现，别提前优化。
    if (_plainTextCache.length >= _plainTextCacheLimit) _plainTextCache.clear();
    _plainTextCache[raw] = text;
    return text;
  }

  static final Map<String, String> _plainTextCache = {};

  /// 上限按「可见卡片数×2」取，再多也换不来什么。
  static const int _plainTextCacheLimit = 64;

  /// 空正文的规范 Delta。`Document` 不接受空 Delta（`loadDocument` 抛
  /// ArgumentError），故这里补一个换行 insert。
  static Delta get _empty => _plain('');

  /// 纯文本 → 单段 Delta。尾部补 `\n`：Quill 要求文档以换行结尾，否则最后一行
  /// 无法回车。已带换行的原样保留，避免补出空行。
  static Delta _plain(String text) {
    final body = text.isEmpty
        ? '\n'
        : text.endsWith('\n')
            ? text
            : '$text\n';
    return Delta()..insert(body);
  }
}
