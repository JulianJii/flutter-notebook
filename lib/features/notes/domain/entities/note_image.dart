import 'dart:convert';
import 'dart:typed_data';

/// 一张待插进笔记正文的图片。纯 Dart —— **不 import Flutter**，渲染交给
/// presentation 层的 `NoteImageEmbedBuilder`。
///
/// 图片**不落文件系统**，而是 base64 进 Quill 的 image embed（见 [embedData]）：
/// 走浏览笔记那种「所有数据都在一个 `TextColumn` 里」的老路，`notes.content`
/// 因此是笔记的唯一真相源，不存在「笔记还在、图片被删了」的悬挂引用。
///
/// 代价写在 `docs/FEATURES.md` 的「已知限制」：正文会膨胀约 1/3。
class NoteImage {
  const NoteImage({required this.bytes, required this.mime});

  final Uint8List bytes;

  /// MIME 类型，形如 `image/jpeg`。压缩过的图一律变成 `image/jpeg`。
  final String mime;

  /// Quill image embed 的 payload：`data:image/jpeg;base64,<b64>`。
  ///
  /// 带 `data:` 前缀而不是裸 base64 —— 自带头信息，渲染侧不必猜图片格式，
  /// 将来导出 Markdown / HTML 也能直接当 URL 用（`FEATURE-DEPENDENCIES.md`）。
  ///
  /// ⚠️ 每次 getter 都会重新编码一遍（O(n)）。只在**插入那一刻**调一次，
  /// 之后进 `Document` 的就是这个字符串；别放在 widget 的 build 里。
  String get embedData => 'data:$mime;base64,${base64Encode(bytes)}';

  /// embed payload → [NoteImage]。不是 data URI、mime 不是图片、base64 坏了
  /// 都返回 `null`（渲染侧显示「图片损坏」占位，而不是抛崩笔记详情页）。
  static NoteImage? tryFromEmbedData(Object? data) {
    if (data is! String) return null;
    const prefix = 'data:image/';
    if (!data.startsWith(prefix)) return null;
    final comma = data.indexOf(',');
    if (comma < 0 || !data.substring(0, comma).endsWith(';base64')) return null;
    try {
      final header = data.substring(0, comma); // data:image/png;base64
      return NoteImage(
        bytes: base64Decode(data.substring(comma + 1)),
        mime: header.substring('data:'.length, header.length - ';base64'.length),
      );
    } on FormatException {
      return null;
    }
  }

  /// 超过这个字节数会被压成 JPEG（设置项「压缩插入的图片」为 true 时）。
  ///
  /// 按**字节**而不是像素判断：取固有尺寸得先把可能 4000px 的原图解一遍，
  /// 峰值内存几十 MB；而 `compressWithList` 本来就按目标边长降采样，不需要
  /// 我们预先知道尺寸。
  static const int compressByteThreshold = 2 * 1024 * 1024;

  /// 单张上限。base64 会再膨胀约 1/3，不设限等于允许用户把上百 MB 塞进
  /// `notes.content` 这一个 `TextColumn` 里。超过 → 整次插入拒绝并提示。
  static const int maxSingleBytes = 10 * 1024 * 1024;

  /// 一次多选的总量上限，理由同 [maxSingleBytes]。
  static const int maxTotalBytes = 20 * 1024 * 1024;

  /// 压缩目标：最长边 1600px、JPEG quality 85。
  static const int compressedMaxDimension = 1600;
  static const int compressedQuality = 85;
}
