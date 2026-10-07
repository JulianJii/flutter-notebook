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
    // ponytail: 超预算就整块清空（不是 LRU）—— 换来的最坏情况只是退化成
    // 无缓存的正确结果。真的需要精确 LRU 时再换实现，别提前优化。
    //
    // ⚠️ 预算按**累计字符数**而不是条目数：正文里可以嵌 base64 图片，一条 raw
    // 就能到几 MB，按条目数限 64 条等于把几百 MB 强引用钉死在内存里。
    if (_plainTextCacheChars + raw.length > _plainTextCacheCharLimit) {
      _plainTextCache.clear();
      _plainTextCacheChars = 0;
    }
    _plainTextCache[raw] = text;
    _plainTextCacheChars += raw.length;
    return text;
  }

  static final Map<String, String> _plainTextCache = {};

  /// 已存 key 的累计字符数。[_plainTextCache] 本身无长度信息，自己记一笔。
  static int _plainTextCacheChars = 0;

  /// 缓存预算（约 256K 字符 ≈ 数十条长笔记的摘要）。
  static const int _plainTextCacheCharLimit = 256 * 1024;

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
