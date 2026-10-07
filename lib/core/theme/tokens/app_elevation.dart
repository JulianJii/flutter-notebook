import 'package:material_ui/material_ui.dart';

/// 阴影单一来源。取值来自 `UI-IMPLEMENTATION-SPEC.md` §2.4。
///
/// 阴影**不随主题变**，因此是 `static const` 而非 `ThemeExtension`。
abstract final class AppElevation {
  /// 卡片。**0** —— 卡片纯白靠底色差分层，无阴影。笔记列表稿–设置稿。
  static const double card = 0;

  /// 底部导航。0，其分隔线用 [AppStroke.divider]。
  static const double nav = 0;

  /// FAB：柔和外阴影（向下扩散，偏移 ≈4dp，模糊 ≈12dp，透明度 ≈20%）`[推导]`。
  /// FAB 是画面中唯一带阴影的元素。笔记列表稿/待办稿。
  ///
  /// ⚠️ 三参数（偏移 + 模糊 + 透明度）用 `double` 表达不了，故用
  /// [List<BoxShadow>]，可直接喂给 `BoxDecoration(boxShadow: ...)`。
  static const List<BoxShadow> fab = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 4), blurRadius: 12),
  ];
}

/// 描边宽度。与阴影同源（`UI-IMPLEMENTATION-SPEC.md` §2.4 同一张表，
/// 语义都是「线与面的厚度」），故同文件。
abstract final class AppStroke {
  /// 顶部栏图标、勾选、circle-plus。2dp，圆角端点。笔记详情稿/文件夹管理稿。
  static const double icon = 2;

  /// 设置行分割线。1dp。设置稿。
  static const double divider = 1;
}
