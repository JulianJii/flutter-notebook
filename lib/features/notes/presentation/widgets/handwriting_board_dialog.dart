import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 打开手写板全屏对话框。
///
/// 返回手写内容的 PNG（含白底）包装成的 [NoteImage]；取消 / 空画布 / 导出失败
/// 一律返回 `null` —— 调用方据此不往正文插任何东西。
///
/// ⛔ 对话框而非路由页：手写是**编辑动作的临时态**（画完即变成正文里的一张图），
/// 没有可再次进入的地址，进路由栈只会多出一个返回键语义相同的条目。
Future<NoteImage?> showHandwritingBoardDialog(BuildContext context) =>
    showDialog<NoteImage>(
      context: context,
      builder: (_) => const _HandwritingBoardDialog(),
    );

/// 手写板。白纸 + 黑笔，一屏一页。
///
/// `Dialog.fullscreen` + `Scaffold`：后者是为了 SnackBar 有地方落 —— 不套
/// Scaffold 的话 `ScaffoldMessenger` 会把提示挂到**下面那个页面**的 Scaffold 上，
/// 被这个全屏对话框整个盖住（导出失败时用户什么都看不到）。
class _HandwritingBoardDialog extends StatefulWidget {
  const _HandwritingBoardDialog();

  @override
  State<_HandwritingBoardDialog> createState() =>
      _HandwritingBoardDialogState();
}

class _HandwritingBoardDialogState extends State<_HandwritingBoardDialog> {
  /// 画笔状态（颜色 / 粗细）与绘制历史都在 controller 上：切工具**不丢样式**
  /// （包在每次落笔时用当前全局样式覆盖工具的 paint）。
  late final DrawingController _controller = DrawingController(
    config: DrawConfig(
      contentType: SimpleLine,
      // ⚠️ 包默认色是**红**（`DrawConfig.color = Colors.red`），必须显式指定。
      color: _InkColor.black.value,
      strokeWidth: _kDefaultStrokeWidth,
    ),
  );

  _Tool _tool = _Tool.pen;
  _InkColor _ink = _InkColor.black;
  double _strokeWidth = _kDefaultStrokeWidth;

  /// 导出是异步的（离屏渲染整块画布）：置灰「完成」防双击重复导出。
  bool _exporting = false;

  @override
  void dispose() {
    // ⚠️ `DrawingBoard` 是 StatelessWidget，不会释放 controller（见包源码）：
    // 漏掉这一行，每开关一次手写板就漏一份绘制历史 + 画布缓存位图。
    _controller.dispose();
    super.dispose();
  }

  void _selectTool(_Tool tool) {
    setState(() => _tool = tool);
    _controller.setPaintContent(tool.content());
  }

  void _selectInk(_InkColor ink) {
    setState(() => _ink = ink);
    _controller.setStyle(color: ink.value);
  }

  void _setStrokeWidth(double value) {
    setState(() => _strokeWidth = value);
    _controller.setStyle(strokeWidth: value);
  }

  /// 清空整块画布。**先确认**：包里的 `clear()` 会连历史一起清掉，撤销救不回来，
  /// 而用户可能刚画了满满一屏。
  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.noteHandwritingClearConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(dialogContext).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.noteHandwritingClear),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _controller.clear();
  }

  /// 「完成」：把画布导出成 PNG 交回调用方。
  Future<void> _done() async {
    if (_exporting) return;
    final l10n = AppLocalizations.of(context);

    // 空画布：直接关，不往笔记里插一张纯白图。
    if (!_controller.canClear()) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _exporting = true);
    try {
      // ⚠️ 用 `getImageData` 而不是 `getSurfaceImageData`：前者把**白色背景**
      // 一起渲染进去，且物理像素 = 画布逻辑尺寸 × devicePixelRatio（高 DPI 屏
      // 插进正文依然锐利）；后者只有笔迹层、且是逻辑像素。
      final data = await _controller.getImageData();
      if (!mounted) return;

      final bytes = data?.buffer.asUint8List();
      if (bytes == null) {
        _fail(l10n.noteHandwritingExportFailed);
        return;
      }
      // 与插入图片同一个上限（`NoteImage.maxSingleBytes`，base64 会再膨胀 1/3）：
      // 手写图通常只有几百 KB，但超大画布 + 离屏像素比下仍有必要兜一次。
      if (bytes.length > NoteImage.maxSingleBytes) {
        _fail(l10n.noteHandwritingTooLarge);
        return;
      }
      Navigator.of(context).pop(NoteImage(bytes: bytes, mime: 'image/png'));
    } on Object {
      // 离屏渲染可能抛（画布尚未挂载 / 渲染后端异常）。**不关对话框**：
      // 画好的内容还在，用户能重试或取消。
      if (!mounted) return;
      _fail(l10n.noteHandwritingExportFailed);
    }
  }

  /// 导出失败：提示 + 解除「导出中」，对话框保持打开。
  void _fail(String message) {
    AppUtils.showSnackBar(context, message: message);
    setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: context.colors.bg,
        body: Column(
          children: <Widget>[
            AppTopBar(
              leading: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              centerTitle: Text(
                l10n.noteHandwriting,
                style: context.textStyles.topBarTitle,
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.accent,
                  ),
                  // 导出中置灰（`onPressed: null` 即禁用态）。
                  onPressed: _exporting ? null : () => _done(),
                  child: Text(l10n.noteHandwritingDone),
                ),
              ],
            ),
            Expanded(
              child: DrawingBoard(
                controller: _controller,
                // 纸：恒白，**不跟主题** —— 深色主题下给黑底配黑笔等于看不见。
                //
                // ⚠️ `SizedBox.expand` 不能省，而且**不是**样式问题：包用
                // `GetSize` 量背景的**实测尺寸**当画布尺寸（绘制层再照它定尺寸），
                // 而纸张外面是 `Center → Stack(fit: loose)`，约束从 0 起 ——
                // 一个裸 `ColoredBox` 会塌成 0×0，画布与绘制层跟着为 0，
                // 手势根本落不到画布上（表现为「怎么画都没反应」）。
                background: const SizedBox.expand(
                  child: ColoredBox(color: Colors.white),
                ),
                // ⚠️ 也不能省：包默认 `false`，会把 child 放进**无界**约束，
                // 上面那个 `SizedBox.expand` 会一路撑到 infinity 直接报错。
                boardConstrained: true,
                // 一屏一页的纸张心智：禁掉画布平移 / 缩放，免得一笔画到一半
                // 整块纸跟着手指跑。
                boardPanEnabled: false,
                boardScaleEnabled: false,
                // 手写场景防手掌误触（包内按触点尺寸判定）。
                enablePalmRejection: true,
              ),
            ),
            _bottomBar(context, l10n),
          ],
        ),
      ),
    );
  }

  /// 底部两行：工具 / 动作，色板 + 粗细。
  Widget _bottomBar(BuildContext context, AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.bg,
        border: Border(
          top: BorderSide(
            color: context.colors.divider,
            width: AppStroke.divider,
          ),
        ),
      ),
      // 背景色延伸到屏幕底边（含手势条），只让内容避让。
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_toolRow(context, l10n), _inkRow(context, l10n)],
        ),
      ),
    );
  }

  Widget _toolRow(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      // ⚠️ 双层 Row 都要 `min`：横向滚动里宽度无界，`max` 会直接溢出报错。
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final tool in _Tool.values)
            AppIconButton(
              icon: tool.icon,
              tooltip: tool.label(l10n),
              // 选中态：强调色点亮；未选中回落 `AppIconButton` 默认描边灰。
              color: tool == _tool ? colors.accent : null,
              onPressed: () => _selectTool(tool),
            ),
          _actionDivider(colors),
          // 撤销 / 重做 / 清空的可用态跟着绘制历史变（`DrawingController` 是
          // `ChangeNotifier`，落笔 / 撤销后都会通知）。
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIconButton(
                  icon: Icons.undo,
                  tooltip: l10n.noteHandwritingUndo,
                  onPressed: _controller.canUndo() ? _controller.undo : null,
                ),
                AppIconButton(
                  icon: Icons.redo,
                  tooltip: l10n.noteHandwritingRedo,
                  onPressed: _controller.canRedo() ? _controller.redo : null,
                ),
                AppIconButton(
                  icon: AppIcons.trash,
                  tooltip: l10n.noteHandwritingClear,
                  onPressed: _controller.canClear()
                      ? () => _confirmClear()
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 工具组与动作组之间的竖分隔线。
  Widget _actionDivider(AppColors colors) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    child: SizedBox(
      width: AppStroke.divider,
      height: AppIcon.defaultSize + AppSpacing.sm,
      child: ColoredBox(color: colors.divider),
    ),
  );

  Widget _inkRow(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          for (final ink in _InkColor.values) _swatch(context, l10n, ink),
          Expanded(
            child: Semantics(
              label: l10n.noteHandwritingStrokeWidth,
              child: Slider(
                value: _strokeWidth,
                min: _kMinStrokeWidth,
                max: _kMaxStrokeWidth,
                onChanged: _setStrokeWidth,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 一个色块。选中态是**外圈强调色环**（不是把色点改色 —— 色点本身就是信息）。
  Widget _swatch(BuildContext context, AppLocalizations l10n, _InkColor ink) {
    final selected = ink == _ink;
    return Tooltip(
      message: ink.label(l10n),
      child: InkResponse(
        onTap: () => _selectInk(ink),
        radius: AppIconButton.minTapSize / 2,
        child: SizedBox(
          width: AppIconButton.minTapSize,
          height: AppIconButton.minTapSize,
          child: Center(
            child: Container(
              width: _kSwatchSize,
              height: _kSwatchSize,
              padding: const EdgeInsets.all(_kSwatchRingGap),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? context.colors.accent : Colors.transparent,
                  width: AppStroke.icon,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ink.value,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 画笔粗细默认值。4dp：落在纸上约等于日常中性笔。
const double _kDefaultStrokeWidth = 4;

/// 粗细可调范围（dp）。上限 16 是「能写粗标题 / 画框」的量级，再粗就盖住半屏。
const double _kMinStrokeWidth = 1;
const double _kMaxStrokeWidth = 16;

/// 色块直径（视觉）与选中环之间的留白。
const double _kSwatchSize = 32;
const double _kSwatchRingGap = 3;

/// 手写板的绘制工具。
///
/// ⛔ **不使用包内置的 `DrawingBar` / `DefaultToolItem`**：它取 controller 走
/// 自己的 InheritedWidget，且图标 / 选中色 / 触控区都是包的一套，跟本页 token
/// 与 48dp 触控区对不上。这里只当它是一组 `PaintContent` 类型。
///
/// 图标不在设计稿语义表里（稿无手写板），取 Material 惯例字形，等设计补稿后
/// 只改这一个 enum。
enum _Tool {
  pen(Icons.gesture),
  line(Icons.horizontal_rule),
  rectangle(Icons.crop_square),
  circle(Icons.circle_outlined),
  // ⚠️ Material Icons 里没有「橡皮块」字形（`ink_eraser` 是 Material Symbols
  // 才有的），取最接近的刷子。
  eraser(Icons.cleaning_services_outlined);

  const _Tool(this.icon);

  final IconData icon;

  /// 交给包的工具实例。
  ///
  /// ⚠️ 必须经 `DrawingController.setPaintContent` 注入 —— 包会用**当前全局样式**
  /// （色板选的颜色、粗细）覆盖它的 paint；自己 new 一个直接塞进去，样式会跟
  /// 色板脱节。
  PaintContent content() => switch (this) {
    _Tool.pen => SimpleLine(),
    _Tool.line => StraightLine(),
    _Tool.rectangle => Rectangle(),
    _Tool.circle => Circle(),
    _Tool.eraser => Eraser(),
  };

  String label(AppLocalizations l10n) => switch (this) {
    _Tool.pen => l10n.noteHandwritingPen,
    _Tool.line => l10n.noteHandwritingLine,
    _Tool.rectangle => l10n.noteHandwritingRectangle,
    _Tool.circle => l10n.noteHandwritingCircle,
    _Tool.eraser => l10n.noteHandwritingEraser,
  };
}

/// 笔迹色板。
///
/// ⚠️ **固定色，不跟主题**：笔迹落在恒白的画布上，取主题前景色会在深色主题下
/// 变成「浅笔画白纸」等于隐形。色值取设计规范的功能色。
enum _InkColor {
  black(Color(0xFF1A1A1A)),
  red(Color(0xFFF44336)),
  blue(Color(0xFF2196F3)),
  green(Color(0xFF4CAF50)),
  orange(Color(0xFFFF9800));

  const _InkColor(this.value);

  final Color value;

  String label(AppLocalizations l10n) => switch (this) {
    _InkColor.black => l10n.noteHandwritingColorBlack,
    _InkColor.red => l10n.noteHandwritingColorRed,
    _InkColor.blue => l10n.noteHandwritingColorBlue,
    _InkColor.green => l10n.noteHandwritingColorGreen,
    _InkColor.orange => l10n.noteHandwritingColorOrange,
  };
}
