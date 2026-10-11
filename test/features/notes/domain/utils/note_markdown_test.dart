import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/notes/domain/utils/note_markdown.dart';

/// 把 Delta JSON 变成落库字符串（走真实的序列化路径，不手拼）。
String _encode(List<Map<String, Object?>> ops) =>
    jsonEncode(<Map<String, Object?>>[...ops]);

Map<String, Object?> _text(String data, [Map<String, Object?>? attrs]) =>
    <String, Object?>{
      'insert': data,
      'attributes': ?attrs,
    };

void main() {
  group('NoteMarkdown.convert', () {
    test('空正文', () {
      expect(NoteMarkdown.convert(''), '');
    });

    test('纯文本与 title 一级标题', () {
      expect(NoteMarkdown.convert(_encode([_text('你好\n')])), '你好');
      expect(
        NoteMarkdown.convert(_encode([_text('正文\n')]), title: '标题'),
        '# 标题\n\n正文',
      );
      expect(
        NoteMarkdown.convert(_encode([_text('正文\n')]), title: '   '),
        '正文',
        reason: '空白 title 当没给',
      );
    });

    test('行内样式', () {
      expect(
        NoteMarkdown.convert(
          _encode([
            _text('粗', <String, Object?>{'bold': true}),
            _text('斜', <String, Object?>{'italic': true}),
            _text('删', <String, Object?>{'strike': true}),
            _text('码', <String, Object?>{'code': true}),
            _text('\n'),
          ]),
        ),
        '**粗***斜*~~删~~`码`',
      );
    });

    test('链接包在最外层', () {
      expect(
        NoteMarkdown.convert(
          _encode([
            _text('点我', <String, Object?>{'link': 'https://a.com', 'bold': true}),
            _text('\n'),
          ]),
        ),
        '[**点我**](https://a.com)',
      );
    });

    test('标题 1~3', () {
      for (final level in <int>[1, 2, 3]) {
        expect(
          NoteMarkdown.convert(
            _encode([
              _text('题', <String, Object?>{
                'header': level,
                'line': 'h$level',
              }),
              _text('\n'),
            ]),
          ),
          '${'#' * level} 题',
        );
      }
    });

    test('列表：项目符号 / 有序 / 勾选', () {
      expect(
        NoteMarkdown.convert(
          _encode([
            _text('甲', <String, Object?>{'list': 'bullet'}),
            _text('\n'),
            _text('乙', <String, Object?>{'list': '1'}),
            _text('\n'),
            _text('丙', <String, Object?>{'list': 'checked', 'checked': true}),
            _text('\n'),
            _text('丁', <String, Object?>{'list': 'unchecked'}),
            _text('\n'),
          ]),
        ),
        '- 甲\n1. 乙\n- [x] 丙\n- [ ] 丁',
      );
    });

    test('引用与代码块', () {
      expect(
        NoteMarkdown.convert(
          _encode([
            _text('引用', <String, Object?>{'line': 'blockquote'}),
            _text('\n'),
            _text('code', <String, Object?>{'line': 'code-block'}),
            _text('\n'),
          ]),
        ),
        '> 引用\n```\ncode\n```',
      );
    });

    test('代码块里不套行内样式', () {
      expect(
        NoteMarkdown.convert(
          _encode([
            _text('a*b', <String, Object?>{
              'line': 'code-block',
              'bold': true,
            }),
            _text('\n'),
          ]),
        ),
        '```\na*b\n```',
      );
    });

    test('一条 op 里的多个换行会切成多行', () {
      expect(
        NoteMarkdown.convert(_encode([_text('一\n二\n三\n')])),
        '一\n二\n三',
      );
    });

    test('embed 渲染成占位而不是被丢掉', () {
      expect(
        NoteMarkdown.convert(
          _encode([
            _text('前\n'),
            <String, Object?>{
              'insert': <String, Object?>{'image': 'data:image/png;base64,AAAA'},
            },
            _text('\n'),
          ]),
        ),
        contains('[图片]'),
      );
    });

    test('老笔记的纯文本内容照样导得出来', () {
      expect(NoteMarkdown.convert('就是纯文本'), '就是纯文本');
    });

    test('损坏的 Delta 退化成纯文本而不是抛', () {
      expect(NoteMarkdown.convert('{不是合法 json'), contains('不是合法'));
    });
  });
}