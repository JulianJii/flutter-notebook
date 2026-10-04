/// 笔记正文的「字数」统计。**不落库**（`ARCHITECTURE-DESIGN.md` §5.2
/// 「不存储的派生字段」）—— 派生值落库 = 同步 bug 来源。
///
/// 口径由 D3 反推：正文「三花聚顶本是幻 / 脚下腾云亦非真 / 人若不为形所累 /
/// 眼前便是大罗天 / 一九玄关显秘论」共 5 段 × 7 字 = **35** 个非空白字符，
/// 而 D3 元信息行显示「35字」。故规则是：**剔除所有空白字符后按 code point 计数**
/// （标点计入）。
///
/// ⛔ **不建 UseCase**（`DEVELOPMENT-GUIDELINES.md` §5）：纯函数不过 Repository。
/// ⛔ 不做记忆化 / 缓存：单次 O(n)，正文规模下耗时不可测，而缓存要引入失效逻辑。
/// ⛔ 不加 `countWords` / `countCharacters` 等备用 API：第二个调用点出现前不加。
// TODO(Q23): 「35字」的统计规则无稿。当前口径由 D3 反推：剔除所有空白后按
// code point 计数，标点计入。不选「英文按词」是因为那需要引入分词规则而设计稿
// 无法验证；不选「剔除标点」是因为 D3 正文恰好无标点、同样无法验证，而少算
// 用户明确写下的字符是更糟的默认。Q23 答了之后只改这一个方法 + 对应单测。
abstract final class WordCounter {
  const WordCounter._();

  static final RegExp _whitespace = RegExp(r'\s');

  /// 非空白字符的 code point 数。用 `runes` 而非 `length`：`length` 是
  /// UTF-16 code unit 数，emoji / 生僻字会算成 2。
  static int count(String content) {
    return content.replaceAll(_whitespace, '').runes.length;
  }
}
