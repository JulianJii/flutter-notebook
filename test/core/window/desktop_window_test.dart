import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mynote/core/window/desktop_window.dart';
import 'package:window_manager/window_manager.dart';

const MethodChannel _channel = MethodChannel('window_manager');

/// 自绘标题栏的两个平台（Linux 没有桌面版，不在内）。
const TargetPlatformVariant _desktop = TargetPlatformVariant(<TargetPlatform>{
  TargetPlatform.windows,
  TargetPlatform.macOS,
});

void main() {
  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          calls.add(call);
          return call.method == 'isMaximized' ? false : true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('启动即摘掉系统标题栏，macOS 红绿灯一并隐藏', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await setUpDesktopWindow();

    final MethodCall style = calls.firstWhere(
      (MethodCall call) => call.method == 'setTitleBarStyle',
    );
    expect(style.arguments, <String, Object>{
      'titleBarStyle': 'hidden',
      'windowButtonVisibility': false,
    });
  });

  test('移动端不碰 window_manager', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await setUpDesktopWindow();

    expect(calls, isEmpty);
  });

  testWidgets(
    '标题栏占窗口顶部 32dp，内容接在它下方',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DesktopWindowFrame(child: const Text('内容'))),
      );

      final Rect caption = tester.getRect(find.byType(WindowCaption));
      expect(caption.height, kWindowCaptionHeight);
      expect(caption.top, 0);
      expect(
        tester.getRect(find.text('内容')).top,
        greaterThanOrEqualTo(caption.bottom),
      );
    },
    variant: _desktop,
  );

  testWidgets(
    '关闭按钮透传到 window_manager',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DesktopWindowFrame(child: const Text('内容'))),
      );

      // 自绘标题栏的三个按钮里最后一个是关闭
      await tester.tap(find.byType(WindowCaptionButton).last);
      await tester.pump();

      expect(calls.map((MethodCall call) => call.method), contains('close'));
    },
    variant: _desktop,
  );

  testWidgets(
    '移动端原样返回内容，不渲染标题栏',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DesktopWindowFrame(child: const Text('内容'))),
      );

      expect(find.byType(WindowCaption), findsNothing);
      expect(find.text('内容'), findsOneWidget);
    },
    variant: TargetPlatformVariant.mobile(),
  );
}
