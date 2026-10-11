/// 待办的重复规则。**有序枚举**：顺序即 UI 里的排列顺序（少 → 多）。
///
/// ⛔ **不引 RRULE**：只支持这三种，就为它们写一个解析器 + 校验 + 「不支持的
/// RRULE」分支，全是为了一个我们自己不会生成的输入。真要支持任意 RRULE，
/// 换掉 [id] 的取值与 [TodoRecurrence.fromId] 即可（迁移只影响
/// `todos.recurrence` 一列）。
///
/// ⛔ **不做「每月最后一天」「每月第 2 个周三」**：那是 RRULE 的活。
enum TodoRecurrence {
  /// 不重复（绝大多数待办）。库里存 null，不是这个值。
  none('none'),

  daily('daily'),
  weekly('weekly'),
  monthly('monthly');

  const TodoRecurrence(this.id);

  /// 落库的稳定 id。**不是下标** —— 枚举增删会让老数据错位。
  final String id;

  static TodoRecurrence? fromId(String? id) {
    if (id == null) return null;
    for (final value in TodoRecurrence.values) {
      if (value.id == id) return value;
    }
    // 未知 id（老版本写的新值）降级成「不重复」：宁可少提醒一次，
    // 也不要因为一个认不出的字符串而让整个待办列表打不开。
    return null;
  }

  /// 下一次提醒时刻 = [from] 之后最近的一个重复点（**严格大于**）。
  ///
  /// 返回 `from` 本身当 [from] 之前没有任何可用的前进方向 —— 那只会发生在
  /// `monthly` 且 [from] 是 1 月 31 号向前回退的场景，见下面 `monthly` 的说明。
  ///
  /// ## 边界
  ///
  /// - **跨月溢出**：`monthly` 从 1 月 31 号前进时，2 月没有 31 号 → 落到
  ///   **当月最后一天**（2 月 28/29 号）。这是日历界的通行做法（`cron` 的
  ///   `day 31` 在 2 月同样落到月末），比「跳过这个月」友好。
  /// - **夏令时**：本 App 不做时区转换（见 `AGENTS.md` 的时钟约定），时刻是
  ///   墙上的本地时刻；跨 DST 那天「每天同一钟点」会差 1 小时。这是已知取舍，
  ///   换成 UTC 递推会让「每天早上 9 点」在夏令时切换后变成 8 点或 10 点。
  DateTime nextAfter(DateTime from) {
    switch (this) {
      case TodoRecurrence.none:
        return from;
      case TodoRecurrence.daily:
        return from.add(const Duration(days: 1));
      case TodoRecurrence.weekly:
        return from.add(const Duration(days: 7));
      case TodoRecurrence.monthly:
        return _addMonthClamped(from);
    }
  }

  /// 加一个月，**日号溢出时夹到当月最后一天**。
  ///
  /// ⛔ 不能用 `DateTime(from.year, from.month + 1, from.day)`：那在
  /// 1 月 31 号会抛 `ArgumentError`（2 月没有 31 号），而且 Dart 会把
  /// 2026-02-31 **静默卷成 3 月 3 号** —— 「每月 31 号」变成「每月 3 号」，
  /// 用户只会觉得提醒莫名其妙提前了。
  static DateTime _addMonthClamped(DateTime from) {
    final year = from.year;
    final month = from.month + 1;
    final rolledYear = month > 12 ? year + 1 : year;
    final rolledMonth = month > 12 ? 1 : month;
    final lastDay = DateTime(rolledYear, rolledMonth + 1, 0).day;
    return DateTime(
      rolledYear,
      rolledMonth,
      from.day <= lastDay ? from.day : lastDay,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
    );
  }
}