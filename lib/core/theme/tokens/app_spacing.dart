/// 间距单一来源。取值来自 `UI-IMPLEMENTATION-SPEC.md` §2.3。
///
/// 间距**不随主题变**，因此是 `static const` 而非 `ThemeExtension`。
abstract final class AppSpacing {
  /// 通用小间距 8dp。卡片内段间距、标题区与元信息行的间距（D1/D3 实测）。
  ///
  /// ⚠️ `UI-IMPLEMENTATION-SPEC.md` §2.3 的表里没有这一行（那里只有
  /// `chipGap` = 8dp）。D1 的「标题↔摘要 / 摘要↔日期」与 D3 的「标题区↔元信息行」
  /// 都是 8dp 且是**跨页复用**的值，故补一条通用名而不是各页面写裸数字。
  static const double sm = 8;

  /// 通用大间距 16dp。大标题上边距、D3 正文区上边距（D1/D3 实测）。
  static const double lg = 16;

  /// 页面左右外边距（= 卡片左右边距）。12dp。
  static const double pageH = 12;

  /// 瀑布流列间距。12dp。
  static const double gridGutter = 12;

  /// 卡片行间距（D1）。12dp。
  ///
  /// ⚠️ 文件夹行间距实测 ≈8dp，属 D4 局部值，写在 D4 的实现里
  /// （`features/notes/presentation/screens/`，TASK-050），不进全局 token ——
  /// 只有一个调用点的值不是 token。
  static const double gridRow = 12;

  /// 笔记卡片内边距。12dp。
  static const double cardPad = 12;

  /// 待办卡 / 文件夹行 / 设置行 左右内边距。16dp `[推导]`。
  ///
  /// ⚠️ 与 [pageH] 的 12dp 不一致，`UI-IMPLEMENTATION-SPEC.md` §9 列为重点复核项。
  static const double rowPadH = 16;

  /// 设置分组标题左缩进。28dp `[推导]`。
  static const double sectionHeaderIndent = 28;

  /// 大标题上边距（顶部栏底部 → 大标题）。16dp `[推导]`。
  static const double topBar = 16;

  /// chip 之间的间距。8dp `[推导]`。
  static const double chipGap = 8;

  /// 列表内容底部预留（底部导航 + FAB 不遮挡内容）。≥34dp。
  ///
  /// `UI-IMPLEMENTATION-SPEC.md` §2.3 实测 D1 卡片被直接裁切 → **无** 内边距，需补。
  static const double bottomSafe = 34;

  /// 行内leading 对齐槽位宽（D4）。32dp。
  ///
  /// 选中态的行在leading 画 20dp 琥珀勾、未选中行该位留空 → 名称左边界
  /// 比选中行左移 24dp，**互不对齐**（稿如此，非 bug，待设计确认 **Q25b**）。
  /// 本槽位宽只保证 leading 与文字的间距稳定，不试图抹平这个错位。
  ///
  /// ⚠️ 刻意**不叫** `folderLeadingWidth`：`core/theme/` 内不出现业务字样
  /// （R7），与 [pageH] / [rowPadH] 同属「行级绝对尺寸」。
  static const double rowLeadingSlot = 32;

  /// 纵向排列行动作行内，图标与文案的间距（D4）。6dp。
  static const double actionRowIconGap = 6;

  /// 行内图标尺寸（D4 的选中勾与 ⊕）。20dp。
  ///
  /// `AppIcon.defaultSize` 的 24dp 是**顶栏**尺寸（`UI-IMPLEMENTATION-SPEC.md`
  /// §2.5「顶部栏图标视觉尺寸 24dp」），行内的 20dp 是另一个值，故另立。
  static const double rowIconSize = 20;
}
