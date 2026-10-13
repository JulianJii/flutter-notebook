import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:markdown/markdown.dart' as md;

import 'note_delta.dart';

/// 一篇待导入文章解析后的结果。`delta` 已保证以 `\n` 结尾，可直接
/// [NoteDelta.encode] 落库。
typedef ParsedArticle = ({String title, Delta delta});

/// 文章文件（Markdown / HTML）→ 笔记正文（Quill Delta）。
///
/// [NoteMarkdown] 的**反向对偶**。那边是 Delta → Markdown 的单向导出，类注释
/// 明确写了「故意不做双向」，所以这里另立一个文件，不去扩写它。
///
/// 两种格式只走一条转换链路：Markdown 先用官方 `markdown` 包转成 HTML，再和
/// `.html` 文件一起交给 `flutter_quill_delta_from_html`。少维护一套语法解析，
/// 以后要加 `.htm` 之外的扩展名也是零成本。
///
/// ⛔ 不 import Flutter：与 [NoteDelta] / [NoteMarkdown] 同层，纯字符串处理。
abstract final class NoteImport {
  const NoteImport._();

  /// 支持的文章扩展名（小写，`.` 之后那一段）。文件选择器与
  /// [isSupported] 都用它，两处不会漂。
  static const List<String> extensions = <String>[
    'md',
    'markdown',
    'html',
    'htm',
  ];

  /// 扩展名是不是能认。文件选择器已经滤过一遍，这里是兜底 —— 调用方要能对
  /// 「格式不支持」给出可读的失败原因，而不是静默按 HTML 硬解析。
  static bool isSupported(String fileName) =>
      extensions.contains(_extensionOf(fileName));

  /// 解析。**空文章返回 `null`**：正文只有空白的话落库只会得到一条空笔记，
  /// 调用方据此记为该文件的失败原因「内容为空」。
  ///
  /// 标题四级回退：HTML 的 `<title>` → 正文首个一级标题 → 文件名（去扩展名）。
  /// 「Markdown 的第一个 `# `」已在第二条里 —— Markdown 先转成了 HTML，
  /// `# ` 落地就是 `<h1>`。
  static ParsedArticle? parse({
    required String fileName,
    required String content,
  }) {
    final extension = _extensionOf(fileName);
    final html = _isMarkdown(extension)
        ? md.markdownToHtml(
            content,
            extensionSet: md.ExtensionSet.gitHubFlavored,
          )
        : content;

    // `transformTableAsEmbed: false`：表格降级成普通段落。编辑器没注册表格
    // 渲染器，做成 embed 只会变成一个用户读不懂的占位块。
    final delta = _downgradeEmbeds(
      HtmlToDelta().convert(
        _keepCodeBlockLineBreaks(html),
        transformTableAsEmbed: false,
      ),
    );
    // 空文章：既没有可见文字、也没有任何 embed。落库只会得到一条空笔记。
    if (_isBlank(delta)) return null;

    // Quill 硬要求文档以换行结尾（`Document.loadDocument` 对没尾换行的 Delta 抛
    // ArgumentError）—— 这是唯一「导入完打不开」的硬失败点。
    if (delta.isEmpty || delta.last.data != '\n') delta.insert('\n');

    return (title: _titleOf(fileName, html, delta), delta: delta);
  }

  /// 标题四级回退。
  static String _titleOf(String fileName, String html, Delta delta) =>
      _htmlTitle(html) ?? _firstHeading(delta) ?? _fileStem(fileName);

  /// `<title>` 的文本。用 `html` 包解而不是正则：实体（`&amp;` 之类）由它负责。
  ///
  /// ⚠️ 传进来的是 Markdown **转出来的** HTML，那里面没有 `<head>`，自然会走到
  /// 下一级回退。
  static String? _htmlTitle(String html) {
    final title = html_parser
        .parse(html)
        .head
        ?.querySelector('title')
        ?.text
        .trim();
    return (title == null || title.isEmpty) ? null : title;
  }

  /// 正文首个一级标题。
  ///
  /// ⚠️ Quill 把块属性放在**收尾的 `\n` op 上**（`headerToOp` 的实现），内容 op
  /// 自己不带 `header` —— 所以只能按「一行一行累积、碰到带 `header: 1` 的换行就
  /// 结算」的走法取，不能只看单个 op 的 data。与 [NoteMarkdown] 拆块是同一个坑。
  static String? _firstHeading(Delta delta) {
    final line = StringBuffer();
    for (final op in delta.toList()) {
      final data = op.data;
      if (data is! String) continue;
      final isHeadingOne = op.attributes?['header'] == 1;
      final segments = data.split('\n');
      for (var i = 0; i < segments.length; i++) {
        if (i > 0) {
          if (isHeadingOne) {
            final text = line.toString().trim();
            if (text.isNotEmpty) return text;
          }
          line.clear();
        }
        line.write(segments[i]);
      }
    }
    return null;
  }

  /// 编辑器只注册了「内嵌 base64」的图片渲染器（`NoteImageEmbedBuilder`），
  /// 其余 embed 要么画成「图片损坏」占位、要么走 Quill 的未知 embed 占位 ——
  /// 两种情况用户都看不到原文里的 URL，等于内容静默消失。
  ///
  /// 所以除了本来就是 `data:` 的图片，其余 embed 一律降级成一行带原链接的文本，
  /// 与 [NoteMarkdown] 导出时「不静默丢弃」是同一条原则。
  static Delta _downgradeEmbeds(Delta source) {
    final out = Delta();
    for (final op in source.toList()) {
      final data = op.data;
      if (data is! Map || data.isEmpty) {
        out.insert(data, op.attributes);
        continue;
      }
      final type = data.keys.first.toString();
      final value = data.values.first?.toString() ?? '';
      out.insert(
        _isInlineImage(value)
            ? data
            : (value.isEmpty ? '[$type]' : '[$type: $value]'),
        op.attributes,
      );
    }
    return out;
  }

  /// `HtmlToDelta.convert` 在解析前会把输入里所有换行**连同每行的首尾空白**一起
  /// 抹掉（源码里就是那句 `split('\n').map(trim).join()`），而围栏代码块靠换行
  /// 分行 —— 不先换成 `<br>` 的话，多行代码会被**粘成一行**（`a` 与 `b` 直接连成
  /// `ab`）。那是内容层面的损坏，不是排版问题。`<br>` 在它内部映射成 `\n` 的 insert。
  ///
  /// ⚠️ 剩下的天花板（记在 `docs/FEATURES.md`「已知限制」）：缩进已被上面那一步
  /// 裁掉，且 Quill 的 `code-block` 属性只落在整块的收尾换行上，所以多行代码块里
  /// 只有最后一行带代码块样式。要做到逐行都对，只能换掉这个转换器。
  static String _keepCodeBlockLineBreaks(String html) => html.replaceAllMapped(
    RegExp(r'<pre[\s>][\s\S]*?</pre>', caseSensitive: false),
    (match) => match[0]!.replaceAll('\n', '<br>'),
  );

  static bool _isInlineImage(String value) => value.startsWith('data:image/');

  /// 一点可见文字都没有、也没有 embed。只有图片的文章**不算**空 —— 它有一个
  /// embed，落库之后是能看的。
  static bool _isBlank(Delta delta) => !delta.toList().any(
    (op) => op.data is! String || (op.data! as String).trim().isNotEmpty,
  );

  static bool _isMarkdown(String extension) =>
      extension != 'html' && extension != 'htm';

  /// 小写扩展名，没有扩展名时返回空串。
  static String _extensionOf(String fileName) {
    final base = _baseName(fileName);
    final dot = base.lastIndexOf('.');
    return dot <= 0 ? '' : base.substring(dot + 1).toLowerCase();
  }

  /// 文件名去掉扩展名，作为标题的最后一级回退。
  static String _fileStem(String fileName) {
    final base = _baseName(fileName);
    final dot = base.lastIndexOf('.');
    return (dot <= 0 ? base : base.substring(0, dot)).trim();
  }

  /// `FilePicker` 给的是完整路径，取路径分隔符之后那一段。
  static String _baseName(String fileName) =>
      fileName.split(RegExp(r'[\\/]')).last;
}
