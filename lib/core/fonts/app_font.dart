/// 可选字体目录。**纯 Dart**，不 import Flutter —— 字体 id 会作为 `String?`
/// 存进 domain 层（`AppSettings.uiFontId` / `Note.editorFontId`），
/// 所以 domain ⛔ 不 import 本文件，只认那个字符串。
///
/// ⛔ **目录里没有「系统默认」这一项**：`null` 即系统默认。这样 domain 层不必
/// 认识本目录，也不必为了表达「不加任何字体」而引入一个哨兵 id。
///
/// 字体文件**不打包进安装包**：全部由 `chinese_font_library` 的
/// `DynamicFont.url(...)` 在用户选中时下载并缓存到本地（见 [FontLoaderService]），
/// 之后再选不再联网。
class AppFont {
  const AppFont({
    required this.id,
    required this.label,
    required this.fontFamily,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  /// 持久化用的稳定 id（⛔ 不用 [fontFamily] 当 id：族名可能随字体版本变化）。
  final String id;

  /// 选择弹层里显示的名字。**只有一份、不进 ARB**：字体名是专有名词，
  /// 与 `localeDisplayName`（中文 / English）同一条约定 —— 给「得意黑」编一个
  /// 英文译名只会变味。
  final String label;

  /// 注册进 Flutter 引擎的**字体族名**，也是写进 `TextStyle.fontFamily` 的值。
  final String fontFamily;

  /// 字体文件下载地址。`overwrite: false` 时同一 URL 只下载一次。
  final String downloadUrl;

  /// 文件体积，用于在选择弹层里给用户一个下载耗时预期。
  final int sizeBytes;

  /// 体积的展示文案（MB，一位小数）。
  String get sizeLabel =>
      '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// 全部可选字体。**顺序即弹层里的展示顺序**（小体积在前，先选先得）。
///
/// ⚠️ 全部为可商用开源字体，来源为 Google Fonts 仓库与各字体的官方仓库。
/// ⛔ 改 `downloadUrl` 前先确认新地址可用：地址失效时用户已选的字体会静默回落
/// 系统默认（缓存过一次的仍能离线用）。
const List<AppFont> appFonts = <AppFont>[
  AppFont(
    id: 'zcoolKuaiLe',
    label: '站酷快乐体',
    fontFamily: 'ZCOOLKuaiLe',
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/zcoolkuaile/'
        'ZCOOLKuaiLe-Regular.ttf',
    sizeBytes: 1514968,
  ),
  AppFont(
    id: 'smileySans',
    label: '得意黑',
    fontFamily: 'SmileySans-Oblique',
    downloadUrl:
        'https://raw.githubusercontent.com/LastMonopoly/chinese_font_library/'
        'master/example/assets/SmileySans-Oblique.ttf',
    sizeBytes: 2123340,
  ),
  AppFont(
    id: 'jetBrainsMono',
    label: '等宽 JetBrains Mono',
    fontFamily: 'JetBrainsMono',
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/jetbrainsmono/'
        'JetBrainsMono%5Bwght%5D.ttf',
    sizeBytes: 187208,
  ),
  AppFont(
    id: 'notoSansSc',
    label: '思源黑体',
    fontFamily: 'NotoSansSC',
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/'
        'NotoSansSC%5Bwght%5D.ttf',
    sizeBytes: 17772300,
  ),
  AppFont(
    id: 'notoSerifSc',
    label: '思源宋体',
    fontFamily: 'NotoSerifSC',
    downloadUrl:
        'https://raw.githubusercontent.com/google/fonts/main/ofl/notoserifsc/'
        'NotoSerifSC%5Bwght%5D.ttf',
    sizeBytes: 25125512,
  ),
  AppFont(
    id: 'lxgwWenKai',
    label: '霞鹜文楷',
    fontFamily: 'LXGWWenKai',
    downloadUrl:
        'https://raw.githubusercontent.com/lxgw/LxgwWenKai/main/fonts/TTF/'
        'LXGWWenKai-Regular.ttf',
    sizeBytes: 25575676,
  ),
];

/// id → 字体。`null`（系统默认）与不认识的 id 都返回 `null` —— 后者让历史残留 /
/// 被下线字体的旧偏好自然回落系统默认，⛔ 不需要迁移代码。
AppFont? appFontById(String? id) {
  if (id == null) return null;
  for (final font in appFonts) {
    if (font.id == id) return font;
  }
  return null;
}
