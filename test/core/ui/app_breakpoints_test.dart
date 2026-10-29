import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/ui/app_breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// 断点是三档布局的唯一开关：`usesNavRail` 错一帧就是「侧栏 + 底栏同时出现」，
/// `isTwoPane` 错一帧就是「右栏在窄窗口里挤掉列表」。故把边界值逐个钉死。
void main() {
  /// 在给定逻辑宽度下读一次两个断点。
  Future<(bool, bool)> readAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late (bool, bool) flags;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            flags = (context.usesNavRail, context.isTwoPane);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return flags;
  }

  group('usesNavRail（600 断点）', () {
    testWidgets('599 仍是底部导航', (tester) async {
      final (rail, _) = await readAt(tester, 599);
      expect(rail, isFalse);
    });

    testWidgets('600 切到左侧导航栏', (tester) async {
      final (rail, _) = await readAt(tester, 600);
      expect(rail, isTrue);
    });
  });

  group('isTwoPane（1024 断点）', () {
    testWidgets('1023 仍是单栏', (tester) async {
      final (_, twoPane) = await readAt(tester, 1023);
      expect(twoPane, isFalse);
    });

    testWidgets('1024 启用双栏', (tester) async {
      final (_, twoPane) = await readAt(tester, 1024);
      expect(twoPane, isTrue);
    });
  });

  testWidgets('两个断点不互相包含：800dp 有侧栏但没有双栏', (tester) async {
    final (rail, twoPane) = await readAt(tester, 800);
    expect(rail, isTrue);
    expect(twoPane, isFalse);
  });

  testWidgets('currentWindowWidth 读到的是逻辑宽度（不受 DPR 影响）', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(currentWindowWidth(), 1280);
  });
}
