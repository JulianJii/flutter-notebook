/// 配色方案。**纯 Dart**：零 import（⛔ 不 import Flutter / flex_color_scheme），
/// 让 `features/settings/domain` 能安全持有它而不破「domain 不碰 Flutter」。
///
/// 方案主色见 [AppColorSchemeSeed.seed]；整套色板由 `AppTheme` 交给
/// flex_color_scheme 从主色派生（明暗两态各一套）。
///
/// 共 4 套（琥珀 / 蓝 / 绿 / 紫）；要增删只改这个枚举与 [AppColorSchemeSeed.seed]。
enum AppColorScheme { amber, blue, green, violet }

/// 方案主色的 ARGB 值。
///
/// ⚠️ **是 `int` 而不是 `Color`**：本文件要保持零 import，`Color` 住在 `dart:ui`。
/// 由 `AppTheme` 转成 `Color`。
///
/// `amber` 是 `UI-IMPLEMENTATION-SPEC.md` §2.1 的设计稿强调色 `#F0A020`，
/// 也是默认值 —— 换方案只改强调色与派生色板，中性色不动。
extension AppColorSchemeSeed on AppColorScheme {
  int get seed => switch (this) {
    AppColorScheme.amber => 0xFFF0A020,
    AppColorScheme.blue => 0xFF3B82F6,
    AppColorScheme.green => 0xFF22A06B,
    AppColorScheme.violet => 0xFF8B5CF6,
  };
}
