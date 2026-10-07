import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_radius.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/features/notes/domain/entities/note_image.dart';
import 'package:material_ui/material_ui.dart';

/// 正文里图片的渲染器：**只认自己写的那种 embed**（标准 `image` 类型 + data URI）。
///
/// 注册进 `QuillEditorConfig.embedBuilders` 后接管所有 `image` embed。本项目
/// 的图片只有「内嵌 base64」这一种来源，`NoteImage.tryFromEmbedData` 解不出来的
/// 一律显示损坏占位，而不是崩掉整个笔记详情页。
class NoteImageEmbedBuilder extends EmbedBuilder {
  const NoteImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => true;

  @override
  String toPlainText(Embed node) => '';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    return _NoteImageView(
      // ⚠️ key 不能省：`EmbedBuilder.build` 每次父级 rebuild 都会新建 widget，
      // 没有 key 的话 State 跟着重建 → base64 每帧重解一遍、滚动时疯狂掉帧。
      // 文档的 embed unchanged 时这里拿到的是同一个 String 实例，`==` 直接走
      // 身份比较，代价可以忽略。
      key: ValueKey<Object?>(data),
      data: data,
    );
  }
}

/// 把 base64 payload 解成字节并画出来。
///
/// 解码放在 [initState] 而不是 build：字节一旦持有就不变，`Image.memory` 也能
/// 命中 Flutter 的 imageCache（每帧新建 `Uint8List` 会让缓存键失效）。
class _NoteImageView extends StatefulWidget {
  const _NoteImageView({super.key, required this.data});

  /// Quill embed 的 payload（`String`，但旧 / 脏文档里也可能是别的类型）。
  final Object? data;

  @override
  State<_NoteImageView> createState() => _NoteImageViewState();
}

class _NoteImageViewState extends State<_NoteImageView> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(_NoteImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _decode();
  }

  void _decode() {
    _bytes = NoteImage.tryFromEmbedData(widget.data)?.bytes;
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return const _BrokenImage();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Image.memory(
              bytes,
              width: constraints.maxWidth,
              fit: BoxFit.fitWidth,
              // 按屏幕密度限制解码分辨率：一张 4000px 的原图解码出来是几十 MB
              // 的 RGBA，滚动时足以让编辑区掉帧。
              // ⚠️ 宽度无限时不能传（0/unbounded 会让 decoder 直接报错）。
              cacheWidth: constraints.hasBoundedWidth
                  ? (constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                  : null,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const _BrokenImage(),
            );
          },
        ),
      ),
    );
  }
}

/// 图片读不出来时的占位。
class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      // 只有一个调用点，不进 `AppSpacing`（见该文件顶部「只有一个调用点的值
      // 不是 token」的约定）。
      height: 72,
      color: context.colors.divider.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: context.colors.textPlaceholder,
        ),
      ),
    );
  }
}
