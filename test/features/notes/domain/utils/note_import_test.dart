import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' show Document;
import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/notes/domain/utils/note_delta.dart';
import 'package:mynote/features/notes/domain/utils/note_import.dart';

/// 把 Delta 落成 op 列表，省得每个用例都写一遍 encode + decode。
List<dynamic> _decodeOps(ParsedArticle article) =>
    jsonDecode(NoteDelta.encode(article.delta)) as List<dynamic>;

bool _hasAttr(List<dynamic> ops, String key, Object? value) => ops.any(
  (op) =>
      op is Map &&
      op['attributes'] is Map &&
      (op['attributes'] as Map)[key] == value,
);

bool _hasEmbed(List<dynamic> ops, String type) => ops.any(
  (op) =>
      op is Map && op['insert'] is Map && (op['insert'] as Map)[type] != null,
);

ParsedArticle _parse(String fileName, String content) =>
    NoteImport.parse(fileName: fileName, content: content)!;

void main() {
  group('NoteImport.parse 标题', () {
    test('HTML 优先取 <title>', () {
      final article = _parse(
        'x.html',
        '<html><head><title>文章名</title></head>'
            '<body><h1>正文标题</h1><p>内容</p></body></html>',
      );
      expect(article.title, '文章名');
    });

    test('没有 <title> 时取正文首个一级标题', () {
      expect(_parse('x.html', '<h1>正文标题</h1><p>内容</p>').title, '正文标题');
    });

    test('Markdown 的 # 标题等同首个一级标题', () {
      expect(_parse('a.md', '# 我的标题\n\n正文 **粗体**\n').title, '我的标题');
    });

    test('都取不到时回退文件名（去路径与扩展名）', () {
      expect(_parse(r'C:\a\b\我的笔记.md', '正文').title, '我的笔记');
      expect(_parse('dir/sub/note.HTML', '<p>正文</p>').title, 'note');
    });

    test('空标题只取文件名，不取空白', () {
      expect(_parse('a.html', '<h1>   </h1><p>x</p>').title, 'a');
    });
  });

  group('NoteImport.parse 正文', () {
    test('行内与块级格式落到 Delta attributes', () {
      final ops = _decodeOps(
        _parse('a.md', '# 题\n\n**粗** *斜* ~~删~~\n\n- 甲\n- 乙\n\n> 引用\n'),
      );
      expect(_hasAttr(ops, 'header', 1), isTrue);
      expect(_hasAttr(ops, 'bold', true), isTrue);
      expect(_hasAttr(ops, 'italic', true), isTrue);
      expect(_hasAttr(ops, 'strike', true), isTrue);
      expect(_hasAttr(ops, 'list', 'bullet'), isTrue);
      expect(_hasAttr(ops, 'blockquote', true), isTrue);
    });

    test('HTML 的行内样式与链接落到 Delta attributes', () {
      final ops = _decodeOps(
        _parse(
          'a.html',
          '<p><b>粗</b><i>斜</i><u>下</u><a href="https://a.com">链</a></p>',
        ),
      );
      expect(_hasAttr(ops, 'bold', true), isTrue);
      expect(_hasAttr(ops, 'italic', true), isTrue);
      expect(_hasAttr(ops, 'underline', true), isTrue);
      expect(_hasAttr(ops, 'link', 'https://a.com'), isTrue);
    });

    test('结尾必定是换行（否则 Quill 打不开这篇笔记）', () {
      for (final file in <String, String>{
        'a.md': '没有尾换行的正文',
        'a.html': '<strong>没有块级标签</strong>',
        'b.md': '结尾有换行的正文\n',
      }.entries) {
        final article = _parse(file.key, file.value);
        expect(
          NoteDelta.plainText(NoteDelta.encode(article.delta)),
          endsWith('\n'),
          reason: file.key,
        );
      }
    });

    test('表格降级成段落，不做成 embed', () {
      final article = _parse(
        'a.html',
        '<table><tr><td>单元格甲</td><td>单元格乙</td></tr></table>',
      );
      expect(
        _decodeOps(article).any((op) => op is Map && op['insert'] is Map),
        isFalse,
      );
      expect(
        NoteDelta.plainText(NoteDelta.encode(article.delta)),
        contains('单元格甲'),
      );
    });

    test('远程图片降级成带链接的文本，不让它变成「图片损坏」占位', () {
      final article = _parse(
        'a.html',
        '<p>看图 <img src="https://e.com/a.png" /></p>',
      );
      final ops = _decodeOps(article);
      expect(_hasEmbed(ops, 'image'), isFalse);
      expect(
        NoteDelta.plainText(NoteDelta.encode(article.delta)),
        contains('https://e.com/a.png'),
      );
    });

    test('多行代码块不粘成一行', () {
      final article = _parse('a.md', '```\nlet a = 1;\nlet b = 2;\n```\n');
      expect(
        NoteDelta.plainText(NoteDelta.encode(article.delta)),
        contains('let a = 1;\nlet b = 2;'),
      );
    });

    test('内嵌 base64 的图片保留成 embed', () {
      final ops = _decodeOps(
        _parse('a.html', '<img src="data:image/png;base64,AAAA" />'),
      );
      expect(_hasEmbed(ops, 'image'), isTrue);
    });

    test('空文章返回 null', () {
      expect(NoteImport.parse(fileName: 'a.md', content: '   \n\n'), isNull);
      expect(
        NoteImport.parse(fileName: 'a.html', content: '<p>  </p>'),
        isNull,
      );
    });
  });

  group('NoteImport 与 Quill 文档', () {
    test('产出的 Delta 能被 Document 加载 —— 带样式的 HTML 也不抛', () {
      const html = '''
<html><head><title>样式</title><style>p{color:red}</style></head><body>
<h1 style="text-align:center">标题</h1>
<p style="line-height:2.0;font-size:18px;color:#ff0000;text-align:justify">
段落 <b>粗</b> <i>斜</i> <u>下</u> <s>删</s> <code>码</code>
<a href="https://a.com">链</a></p>
<ul><li>甲</li><li>乙<ul><li>嵌套</li></ul></li></ul>
<ol><li>一</li></ol>
<blockquote>引用</blockquote>
<pre><code>final x = 1;</code></pre>
<hr />
<table><tr><td>单元格</td></tr></table>
<img src="https://e.com/b.png" />
</body></html>''';
      final article = _parse('样式.html', html);
      expect(() => Document.fromJson(_decodeOps(article)), returnsNormally);
    });

    test('产出的 Delta 能被 Document 加载 —— Markdown 各方言语法也不抛', () {
      const markdown = '''
# 标题

正文 **粗** *斜* ~~删~~ `码` [链](https://a.com)

- [x] 勾选
- [ ] 未勾选

| 甲 | 乙 |
|---|---|
| 1 | 2 |

> 引用

```dart
final x = 1;
```
''';
      final article = _parse('a.md', markdown);
      expect(() => Document.fromJson(_decodeOps(article)), returnsNormally);
    });
  });

  group('NoteImport.isSupported', () {
    test('认这四种扩展名，且大小写不敏感', () {
      for (final name in <String>[
        'a.md',
        'a.markdown',
        'a.html',
        'a.htm',
        r'C:\a\b\A.MD',
        'A.Html',
      ]) {
        expect(NoteImport.isSupported(name), isTrue, reason: name);
      }
    });

    test('别的扩展名与没扩展名都不认', () {
      for (final name in <String>['a.txt', 'a', 'a.json', 'noext']) {
        expect(NoteImport.isSupported(name), isFalse, reason: name);
      }
    });
  });
}
