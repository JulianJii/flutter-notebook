/// 圆角单一来源。取值来自 `UI-IMPLEMENTATION-SPEC.md` §2.4。
///
/// 圆角**不随主题变**，因此是 `static const` 而非 `ThemeExtension`。
abstract final class AppRadius {
  /// 所有卡片（笔记卡、待办卡、文件夹行、设置分组卡）。12dp。笔记列表稿/待办稿/文件夹管理稿/设置稿。
  static const double card = 12;

  /// 底部导航「笔记」图标黑底圆角方块。8dp `[推导]`。笔记列表稿。
  static const double navIcon = 8;

  /// 待办未勾选框（圆角方形）。6dp `[推导]`。待办稿。
  static const double checkbox = 6;
}
