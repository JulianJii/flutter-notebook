import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:window_manager/window_manager.dart';

/// 本平台是否用自绘标题栏（Windows / macOS 桌面版）。
///
/// 用 `defaultTargetPlatform` 而非 `dart:io` 的 `Platform`：前者能在测试里用
/// `debugDefaultTargetPlatformOverride` 覆盖，[setUpDesktopWindow] 与
/// [DesktopWindowFrame] 因此共用同一份判断，测得出也测得住。
bool get _usesCustomTitleBar =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// 启动时摘掉系统标题栏，交给 [DesktopWindowFrame] 自绘。
///
/// ⚠️ macOS 连红绿灯一并隐藏（`windowButtonVisibility: false`），两个平台外观一致
/// —— 窗口操作全靠自绘那条。移动端直接返回，不碰 `window_manager`。
Future<void> setUpDesktopWindow() async {
  if (!_usesCustomTitleBar) {
    return;
  }

  await windowManager.ensureInitialized();
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
}

/// 窗口外壳：顶部 32dp 自绘标题栏（拖动 / 双击最大化 / 最小化 / 最大化 / 关闭）
/// + 其余空间给应用内容。
///
/// 挂 `MaterialApp.router` 的 `builder`：所有页面（含二级页与弹窗）都落在标题栏
/// 下方，不必逐页避让。非 Windows / macOS 平台原样返回 [child]。
class DesktopWindowFrame extends StatelessWidget {
  const DesktopWindowFrame({required this.child, super.key});

  /// 应用内容（`MaterialApp.router` 的 `child`）。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!_usesCustomTitleBar) {
      return child;
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: kWindowCaptionHeight,
          child: WindowCaption(
            backgroundColor: context.colors.bg,
            brightness: Theme.of(context).brightness,
          ),
        ),
        // macOS 会把（透明的）标题栏高度报成顶部安全区。标题栏已由上面这条自己
        // 占掉，页面内再避让一次就会多出一条空隙。
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
