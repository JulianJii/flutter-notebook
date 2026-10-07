import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/notes/domain/utils/word_counter.dart';

void main() {
  group('WordCounter.count', () {
    test('空串返回 0', () {
      expect(WordCounter.count(''), 0);
    });

    test('纯空白返回 0', () {
      expect(WordCounter.count('   \n\t 　'), 0);
    });

    test('纯中文按字计', () {
      expect(WordCounter.count('三花聚顶本是幻'), 7);
    });

    test('纯英文按字符计（口径若改按词则此条要改）', () {
      expect(WordCounter.count('hello'), 5);
    });

    test('中英混排 + 标点计入', () {
      expect(WordCounter.count('你好，world！'), 9);
    });

    test('笔记详情稿正文实测为 35 字（与设计稿元信息行一致）', () {
      const d3 = '三花聚顶本是幻\n\n脚下腾云亦非真\n\n人若不为形所累\n\n眼前便是大罗天\n\n一九玄关显秘论';
      expect(WordCounter.count(d3), 35);
    });

    test('换行与空格均不计入', () {
      expect(WordCounter.count('一 二\n三\t四'), 4);
    });

    test('非 BMP 字符按 1 个 code point 计数', () {
      expect(WordCounter.count('😀'), 1);
    });
  });
}
