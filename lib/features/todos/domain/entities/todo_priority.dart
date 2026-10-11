/// 待办优先级。**有序枚举，数值越大越靠前**。
///
/// ⛔ 只三档：待办是「今天做什么」的工具，四档的排序结果用户记不住，
/// 而三档（普通 / 重要 / 紧急）在任何列表里都一眼能分。
enum TodoPriority {
  normal(0, 'normal'),
  important(1, 'important'),
  urgent(2, 'urgent');

  const TodoPriority(this.level, this.id);

  /// 排序用的数值。存进 `todos.priority`。
  final int level;

  /// 落库的稳定 id。
  ///
  /// ⚠️ 库里存的是 **id** 而不是 [level]：`level` 一旦重排（比如把 urgent 提到
  /// important 前面），老数据就全错了。id 是稳定契约，level 是实现细节。
  final String id;

  static const TodoPriority defaultValue = TodoPriority.normal;

  static TodoPriority fromId(String? id) {
    if (id == null) return defaultValue;
    for (final value in TodoPriority.values) {
      if (value.id == id) return value;
    }
    // 未知 id 降级成「普通」：待办优先级错了顶多排错位置，而认不出的字符串
    // 让整个列表打不开是灾难。
    return defaultValue;
  }

  /// 从库里的 int 还原。
  static TodoPriority fromLevel(int? level) {
    if (level == null) return defaultValue;
    for (final value in TodoPriority.values) {
      if (value.level == level) return value;
    }
    return defaultValue;
  }
}