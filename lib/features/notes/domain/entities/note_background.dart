/// 笔记的纸张背景。
///
/// 落库的是稳定的 [id] 字符串（`notes.background` 列），`null` = 无背景。
/// 存 id 而非下标：背景资源的展示顺序将来变化时，老数据不会错位。
///
/// ⛔ 本枚举**不认识图片资源**（domain 不 import Flutter）：枚举 → 资源图的
/// 映射在 presentation 层（`presentation/widgets/note_background_image.dart`）。
enum NoteBackground {
  paper('paper'),
  mint('mint'),
  blush('blush');

  const NoteBackground(this.id);

  /// 持久化 id。与枚举名一致，但是**独立的事实** —— 改名不算改数据。
  final String id;

  /// 未知 id 与 null 一律降级为「无背景」（不在候选集里的脏数据不崩页面）。
  static NoteBackground? fromId(String? id) {
    for (final value in values) {
      if (value.id == id) {
        return value;
      }
    }
    return null;
  }
}
