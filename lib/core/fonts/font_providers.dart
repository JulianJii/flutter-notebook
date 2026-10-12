import 'package:mynote/core/error/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_font.dart';
import 'font_loader_service.dart';
import 'font_registrar.dart';

part 'font_providers.g.dart';

/// 字体加载器。`keepAlive`：字体注册进引擎后在整个进程生命周期内有效，
/// 丢掉这个 service 等于丢掉「哪些字体已加载」的记忆，会重复下载。
@Riverpod(keepAlive: true)
FontLoaderService fontLoaderService(Ref ref) =>
    FontLoaderService(const DynamicFontRegistrar());

/// 字体 id → **可直接喂给 `TextStyle.fontFamily` 的族名**。
///
/// 这是两条消费链（`main.dart` 的 UI 字体 / 笔记详情页的编辑器字体）的**唯一读入口**：
/// - [fontId] 为 `null` 或不认识的 id → 返回 `null`（= 平台默认），**不触发任何下载**；
/// - 已知 id → 先 `ensureLoaded`（首次联网下载，之后读本地缓存），成功返回族名。
///
/// ⚠️ **失败抛 [FontFailure]**：调用方取 `value`，于是加载期间与加载失败
/// 都自然回落系统默认字体，⛔ 不阻塞启动、不阻塞打开笔记。
/// 用户需要知道失败的只有「刚点下选择」那一次 —— 那条路径在弹层里直接
/// `await ensureLoaded`（见 `AppFontPickerSheet`），不走本 provider。
///
/// ⚠️ 失败后 **Riverpod 会按退避自动重试**，因此「网络恢复」不需要用户再选一次；
/// 重试期间 `value` 仍是 null（继续用系统默认字体）。这条是刻意保留的默认行为，
/// 不是漏配。
@Riverpod(keepAlive: true)
Future<String?> fontFamilyOf(Ref ref, String? fontId) async {
  final font = appFontById(fontId);
  if (font == null) return null;

  final loaded = await ref.watch(fontLoaderServiceProvider).ensureLoaded(font);
  if (!loaded) {
    throw FontFailure(message: 'Font load failed: ${font.id}');
  }
  return font.fontFamily;
}
