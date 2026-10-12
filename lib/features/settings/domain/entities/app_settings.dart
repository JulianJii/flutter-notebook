import 'package:equatable/equatable.dart';
import 'package:mynote/core/theme/app_color_scheme.dart';

/// UI 文字字体。4 档，默认 `system`。
///
/// 取值是**系统字体族名**（`AppTextStyles.withFontFamily` 是唯一落点）：不打包字体
/// 文件、不引 `google_fonts`，族名交给平台解析。非 Android 平台上 `serif` /
/// `sans-serif` / `monospace` 多半解析不到，会静默回落到系统默认字体
/// —— 见 `docs/FEATURES.md`「已知限制」。
///
/// ⛔ **只管 UI 文字**：笔记标题与正文（编辑器内部）不走这一项，它们的字体由
/// 编辑器工具栏的「字体」按钮按选中范围决定（`AppTextStyles.editor`）。
enum AppFontFamily { system, serif, sansSerif, monospace }

/// 设置「选择排序方式」。默认 `editedDesc`（按编辑日期）。
///
/// ⚠️ **不是 `NoteSort`**：`NoteSort` 住在 `features/notes/`，而 features 之间
/// 零互相 import（`FEATURE-DEPENDENCIES.md` R2）。两侧 4 个值同名同序，
/// 由 presentation 层（笔记列表，`TASK-047`）显式映射 —— 重复 4 个枚举值比让
/// `settings` 反向依赖 `notes` 便宜，和 `NoteDaoOrder` 是同一个理由。
enum AppNoteSort { editedDesc, editedAsc, createdDesc, titleAsc }

/// 设置「笔记列表布局」。默认 `grid`（宫格模式）。
enum NoteLayout { grid, list }

/// 主题模式。默认 `system`。
///
/// ⚠️ **不是 Flutter 的 `ThemeMode`**：domain 是纯 Dart 层，⛔ 不 import Flutter。
/// 映射成 `ThemeMode` 在 `main.dart` 的 `MyApp` 里（3↔3 一一对应）。
enum AppThemeMode { system, light, dark }

/// 用户偏好。6 个标量、**永远一行**，⛔ **不做成 drift 表**（ADR-14）：
/// 需在 `main()` 之前读到，`SharedPreferences` 的同步 API 更简单，
/// drift 反而要多一个 DAO 和一张表。
///
/// ⛔ **不预留字段**：字段集与设置页的行逐项对齐，⛔ **不落派生值**
/// （字体族的解析由 `AppTextStyles.withFontFamily` 现算）。
class AppSettings extends Equatable {
  const AppSettings({
    this.fontFamily = AppFontFamily.system,
    this.noteSort = AppNoteSort.editedDesc,
    this.noteLayout = NoteLayout.grid,
    this.themeMode = AppThemeMode.system,
    this.colorScheme = AppColorScheme.amber,
    this.compressImages = true,
  });

  /// 默认值入口。设置稿上显示的正是这几个值。
  const AppSettings.defaults()
    : fontFamily = AppFontFamily.system,
      noteSort = AppNoteSort.editedDesc,
      noteLayout = NoteLayout.grid,
      themeMode = AppThemeMode.system,
      colorScheme = AppColorScheme.amber,
      compressImages = true;

  /// UI 文字字体。⛔ 编辑器文字（笔记标题 + 正文）不吃它，见 [AppFontFamily]。
  final AppFontFamily fontFamily;

  final AppNoteSort noteSort;

  final NoteLayout noteLayout;

  /// ⛔ **这里没有 `locale` 字段**：语言的真源是 `core` 的
  /// `persistentLocaleProvider`（`selected_language_code`），它自己写盘。
  /// 在这里再存一份就成了双真相源，且表达不出「跟随系统」这一档
  /// （见 `docs/LOCALIZATION_GUIDE.md`）。
  ///
  /// 明暗。设置「跟随系统 / 浅色 / 深色」三档（主题页）。
  final AppThemeMode themeMode;

  /// 配色方案。与 [themeMode] **正交**：明暗管亮度，这里管强调色与派生色板。
  /// 默认 `amber` = 设计稿 `#F0A020`。
  final AppColorScheme colorScheme;

  /// 插入图片前是否压缩。
  ///
  /// true（默认）→ 每张图都压成 JPEG 再内嵌；false → 原图直嵌，画质无损但
  /// 正文字节数会大得多。压缩目标与大小上限都住在 `NoteImage`，本类不带业务常量。
  final bool compressImages;

  AppSettings copyWith({
    AppFontFamily? fontFamily,
    AppNoteSort? noteSort,
    NoteLayout? noteLayout,
    AppThemeMode? themeMode,
    AppColorScheme? colorScheme,
    bool? compressImages,
  }) {
    return AppSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      noteSort: noteSort ?? this.noteSort,
      noteLayout: noteLayout ?? this.noteLayout,
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
      compressImages: compressImages ?? this.compressImages,
    );
  }

  @override
  List<Object?> get props => [
    fontFamily,
    noteSort,
    noteLayout,
    themeMode,
    colorScheme,
    compressImages,
  ];
}
