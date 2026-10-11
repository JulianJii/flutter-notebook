import 'package:dart_quill_delta/dart_quill_delta.dart';

import 'note_delta.dart';

/// Quill Delta → Markdown（**单向**）。
///
/// 为什么是单向：Markdown 没有等价于 Delta 的结构（嵌套列表、代码块内的换行、
/// 行内样式叠加都无法无损表达），硬做双向转换只会得到一个既不准又难维护的子集。
/// 导出场景只需要「把内容拿出来给人看 / 给别的工具用」，所以这里只保证
/// **可读 + 不丢主要内容**，不保证往返。
///
/// 覆盖的块级：段落、标题 1~3、无序 / 有序 / 勾选列表、引用、代码块、分隔线。
/// 覆盖的行内：粗体、斜体、下划线、删除线、行内代码、链接。
/// 未覆盖的（图片 / 表格 / 公式等 embed）：渲染成一行占位说明，**不静默丢弃** ——
/// 用户导出后发现东西没了，比看到一个 `[图片]` 更难排查。
///
/// ⛔ 不 import Flutter：纯 Dart 计算，domain 层可直接用（`NoteDelta` 的同一层）。
abstract final class NoteMarkdown {
  const NoteMarkdown._();

  /// 落库字符串 → Markdown。
  ///
  /// [title] 非空时作为一级标题输出在正文之前（导出单个笔记时由调用方给）。
  /// 复用 [NoteDelta.decode] 的容错：老笔记的纯文本内容照样出得来。
  static String convert(String rawDelta, {String? title}) {
    final body = _blocks(NoteDelta.decode(rawDelta));
    if (title != null && title.trim().isNotEmpty) {
      return '# ${title.trim()}\n\n$body';
    }
    return body;
  }

  /// 把 Delta 按**块**拆开。Delta 是扁平的 op 序列，块边界只能靠「`data` 里有
  /// `\n`」来切 —— 这也是 Quill 的实际约定。
  ///
  /// ⚠️ **块属性与行内属性要分开处理**，这是这个转换器里唯一真正有难度的部分：
  /// Quill 会把 `\n` 放进一个**不带 attributes** 的独立 op 里（Quill 的硬约定），
  /// 而紧挨着它的内容 op 才带着 `bold` / `list` / `line` 这些属性。所以按 op
  /// 逐个写的话，写到换行 op 时必须**用当前行的属性收尾**，而不是用换行 op 的
  /// 空属性覆盖它 —— 否则每个列表项 / 引用 / 标题都会丢掉自己的格式。
  ///
  /// 行内样式按**段**（run）渲染而非按行：一行里可能有「粗体 + 普通 + 斜体」三段
  /// 不同属性，整行套一套属性会把后两段吃掉。
  static String _blocks(Delta delta) {
    final out = <String>[];
    var runs = <({String text, Map<String, dynamic> attrs})>[];

    void flush() {
      if (runs.isEmpty) return;
      out.add(_renderLine(runs));
      runs = <({String text, Map<String, dynamic> attrs})>[];
    }

    for (final op in delta.toList()) {
      final data = op.data;
      if (data is! String) {
        // embed（图片等）：Quill 把它当成一个独占的块级对象。
        flush();
        out.add(_renderEmbed(op));
        continue;
      }
      final opAttrs = Map<String, dynamic>.from(op.attributes ?? const {});
      final parts = data.split('\n');
      for (var i = 0; i < parts.length; i++) {
        if (i > 0) flush();
        if (parts[i].isNotEmpty) {
          runs.add((text: parts[i], attrs: opAttrs));
        }
      }
    }
    flush();

    // 每块一行。段落之间**不**插空行 —— 那会把紧凑列表变成 loose list（渲染成
    // 带段间距的列表），而这批内容里列表远比普通段落多。
    return out.join('\n').trim();
  }

  /// 一个块（一行）→ Markdown 一行。
  static String _renderLine(List<({String text, Map<String, dynamic> attrs})> runs) {
    // 块级属性取**第一段**的：Quill 里同一行的块属性（list / line）是统一的，
    // 行内属性才是逐段不同的。
    final block = runs.first.attrs;
    final line = block['line'];

    if (line == 'code-block') {
      // 代码块**原样**输出全部文本：代码里不该套任何 Markdown 定界符。
      return '```\n${runs.map((r) => r.text).join()}\n```';
    }

    var body = runs.map(_renderRun).join();

    final list = block['list'];
    if (list != null) {
      body =
          '${switch (list) {
            'checked' => '- [${block['checked'] == true ? 'x' : ' '}] ',
            'unchecked' => '- [ ] ',
            'bullet' => '- ',
            _ => '$list. ',
          }}$body';
    } else if (line == 'blockquote') {
      body = '> $body';
    }

    if (line is String && line.length == 2 && line.startsWith('h')) {
      body = '${'#' * (int.parse(line.substring(1)))} $body';
    }
    return body;
  }

  /// 一**段**行内内容 → Markdown。顺序固定：链接最后包（它在最外层，
  /// `[**粗**](url)` 是链接语法要求的形状），其余由内到外依次是行内代码 →
  /// 粗 / 斜 / 删除。
  static String _renderRun(({String text, Map<String, dynamic> attrs}) run) {
    final attrs = run.attrs;
    var body = run.text;
    if (attrs['code'] == true) {
      body = '`$body`';
    }
    if (attrs['strike'] == true) body = '~~$body~~';
    if (attrs['underline'] == true) body = '<u>$body</u>';
    if (attrs['italic'] == true) body = '*$body*';
    if (attrs['bold'] == true) body = '**$body**';
    final link = attrs['link'];
    if (link is String && link.isNotEmpty) {
      body = '[$body]($link)';
    }
    return body;
  }

  /// embed → 一行占位说明。
  ///
  /// embed 的 `data` 是一个**单键的 Map**（`{"image": "..."}`），键名才是类型名，
  /// 值是内容 —— 直接把整个 data 当字符串用会把 Map 的 toString 导进去。
  ///
  /// ⚠️ 图片的 data 是 base64 data-URI（`NoteImage.embedData`），**故意不导出**：
  /// 一张 200KB 的图会让导出的 .md 变成几 MB，且几乎所有 Markdown 渲染器都
  /// 拒绝内联 base64。要带图就导 JSON 快照（图片完整保留）。
  static String _renderEmbed(Operation op) {
    final data = op.data;
    final String type = switch (data) {
      Map<dynamic, dynamic>() when data.isNotEmpty => data.keys.first.toString(),
      String() => data,
      _ => 'embed',
    };
    return '> [${_embedLabel(type)}]';
  }

  static String _embedLabel(String embedType) => switch (embedType) {
    'image' => '图片',
    'video' => '视频',
    'formula' => '公式',
    _ => embedType.isEmpty ? '嵌入内容' : embedType,
  };
}