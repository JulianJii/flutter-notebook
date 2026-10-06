import 'package:equatable/equatable.dart';
import 'package:init/core/theme/app_color_scheme.dart';

/// 文字大小。`ARCHITECTURE-DESIGN.md` §2.13 的 4 值枚举，默认 `normal`。
///
/// ⛔ 不给字阶方法设默认系数：所有调用点必须显式表态（`PROJECT-STATUS.md` §6 的 A7）。
enum TextScaleLevel { small, normal, large, xLarge }

/// P5「选择排序方式」。默认 `editedDesc`（按编辑日期）。
///
/// ⚠️ **不是 `NoteSort`**：`NoteSort` 住在 `features/notes/`，而 features 之间
/// 零互相 import（`FEATURE-DEPENDENCIES.md` R2）。两侧 4 个值同名同序，
/// 由 presentation 层（P1，`TASK-047`）显式映射 —— 重复 4 个枚举值比让
/// `settings` 反向依赖 `notes` 便宜，和 `NoteDaoOrder` 是同一个理由。
enum AppNoteSort { editedDesc, editedAsc, createdDesc, titleAsc }

/// P5「笔记列表布局」。默认 `grid`（宫格模式）。
enum NoteLayout { grid, list }

/// 主题模式。默认 `system`。
///
/// ⚠️ **不是 Flutter 的 `ThemeMode`**：domain 是纯 Dart 层，⛔ 不 import Flutter。
/// 映射成 `ThemeMode` 在 `main.dart` 的 `MyApp` 里（3↔3 一一对应）。
enum AppThemeMode { system, light, dark }

/// 用户偏好。7 个标量、**永远一行**，⛔ **不做成 drift 表**（ADR-14）：
/// 6 个标量、需在 `main()` 之前读到，`SharedPreferences` 的同步 API 更简单，
/// drift 反而要多一个 DAO 和一张表。
///
/// ⛔ **不预留字段**：字段集与 `ARCHITECTURE-DESIGN.md` §2.13 的 P5 五行逐项对齐。
/// ⛔ **不落派生值**：文字大小的实际系数由 `AppTextStyles` 现算。
class AppSettings extends Equatable {
  const AppSettings({
    this.textScale = TextScaleLevel.normal,
    this.noteSort = AppNoteSort.editedDesc,
    this.noteLayout = NoteLayout.grid,
    this.strongReminder = false,
    this.locale,
    this.themeMode = AppThemeMode.system,
    this.colorScheme = AppColorScheme.amber,
  });

  /// 默认值入口。D5 稿上显示的正是这几个值。
  const AppSettings.defaults()
    : textScale = TextScaleLevel.normal,
      noteSort = AppNoteSort.editedDesc,
      noteLayout = NoteLayout.grid,
      strongReminder = false,
      locale = null,
      themeMode = AppThemeMode.system,
      colorScheme = AppColorScheme.amber;

  final TextScaleLevel textScale;

  final AppNoteSort noteSort;

  final NoteLayout noteLayout;

  /// 本期**只存值不执行**：D2 待办没有日期 / 优先级字段，「持续响铃」没有对象。
  /// 但 P5 必须显示该开关的当前值，所以值必须先落地。
  final bool strongReminder;

  /// 语言，BCP-47 主语言码（`'zh'` / `'en'`）。null = 跟系统。
  ///
  /// ⚠️ **存 `String?` 而不是 Flutter 的 `Locale?`**：domain 是纯 Dart 层，
  /// `Locale` 住在 `dart:ui`，import 它就破了「domain ⛔ 不 import Flutter」。
  /// 映射成 `Locale` 在 presentation 层（`TASK-045`）。
  final String? locale;

  /// 明暗。P5「跟随系统 / 浅色 / 深色」三档（主题页）。
  final AppThemeMode themeMode;

  /// 配色方案。与 [themeMode] **正交**：明暗管亮度，这里管强调色与派生色板。
  /// 默认 `amber` = 设计稿 `#F0A020`。
  final AppColorScheme colorScheme;

  AppSettings copyWith({
    TextScaleLevel? textScale,
    AppNoteSort? noteSort,
    NoteLayout? noteLayout,
    bool? strongReminder,
    Object? locale = _unset,
    AppThemeMode? themeMode,
    AppColorScheme? colorScheme,
  }) {
    return AppSettings(
      textScale: textScale ?? this.textScale,
      noteSort: noteSort ?? this.noteSort,
      noteLayout: noteLayout ?? this.noteLayout,
      strongReminder: strongReminder ?? this.strongReminder,
      locale: identical(locale, _unset) ? this.locale : locale as String?,
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }

  @override
  List<Object?> get props => [
    textScale,
    noteSort,
    noteLayout,
    strongReminder,
    locale,
    themeMode,
    colorScheme,
  ];
}

/// [copyWith] 的哨兵：`copyWith(locale: null)` 必须**真的**把语言切回「跟系统」。
const Object _unset = Object();
