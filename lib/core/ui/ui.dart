// core/ui 公共出口。调用方一律 `import 'package:init/core/ui/ui.dart';`。
//
// ⚠️ 本文件只导出 core/ui 下的 T1 组件。不要把 lib/core/generators/ 下的
//    同名 0 字节模板文件导进来（app_card.dart 等在两处同名）。
//
// ⚠️ export 数 = 13 而非 `ARCHITECTURE-DESIGN.md` §3.1 写的 12：差额是
//    `app_bottom_nav.dart`。该文件在 TASK-013 之前已由 TASK-008 落地，
//    §3.1 的「12」只是没把它算进去。TASK-013 spec 里的「不导出
//    app_bottom_nav（此刻文件不存在）」这一前提已失效，漏导出会让
//    TASK-034+ 的 `import 'core/ui/ui.dart'` 拿不到 `AppBottomNav`。
export 'app_bottom_nav.dart';
export 'app_card.dart';
export 'app_checkbox.dart';
export 'app_divider.dart';
export 'app_fab.dart';
export 'app_filter_chip.dart';
export 'app_icon.dart';
export 'app_icon_button.dart';
export 'app_large_title.dart';
export 'app_list_tile.dart';
export 'app_section_header.dart';
export 'app_switch_row.dart';
export 'app_top_bar.dart';
