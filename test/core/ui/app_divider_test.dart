import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/ui/app_divider.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('默认 thickness 1dp、色为 colors.divider', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppDivider())),
    );

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.thickness, AppStroke.divider);
    expect(divider.thickness, 1);
    expect(divider.color, const AppColors.light().divider);
  });

  testWidgets('P5 的缩进 28dp / 右缩进 16dp 生效', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppDivider(
            indent: AppSpacing.sectionHeaderIndent, // 28
            endIndent: AppSpacing.rowPadH, // 16
          ),
        ),
      ),
    );

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.indent, 28);
    expect(divider.endIndent, 16);
  });

  testWidgets('默认缩进为 0（不是 28）', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppDivider())),
    );

    expect(tester.widget<Divider>(find.byType(Divider)).indent, 0);
  });
}
