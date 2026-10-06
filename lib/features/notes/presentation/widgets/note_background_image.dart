import 'package:init/features/notes/domain/entities/note_background.dart';
import 'package:init/gen/assets.gen.dart';

/// 背景图的不透明度。详情页与列表卡片**共用一个值** —— 两处各调一个数字，
/// 迟早会看到同一个背景在两个页面上深浅不一。
const double kNoteBackgroundOpacity = 0.6;

/// 枚举 → 资源图。⛔ 新增 [NoteBackground] 值时这个 `switch` 会编译失败，
/// 补一行即修好 —— 这就是 domain 枚举不带资源路径的代价与收益。
AssetGenImage noteBackgroundImageOf(NoteBackground background) {
  return switch (background) {
    NoteBackground.paper => Assets.images.backgrounds.noteBgPaper,
    NoteBackground.mint => Assets.images.backgrounds.noteBgMint,
    NoteBackground.blush => Assets.images.backgrounds.noteBgBlush,
  };
}

/// 候选列表（展示顺序 = [NoteBackground.values] 顺序）。弹层用
/// 「0 = 无背景，1..n = 本列表」的下标语义，调用方据此在枚举与下标间互转。
final List<AssetGenImage> noteBackgroundImages = NoteBackground.values
    .map(noteBackgroundImageOf)
    .toList(growable: false);

/// 渲染入口：null（无背景）返回 null，调用方据此不画背景层。
AssetGenImage? noteBackgroundImageOrNull(NoteBackground? background) =>
    background == null ? null : noteBackgroundImageOf(background);
