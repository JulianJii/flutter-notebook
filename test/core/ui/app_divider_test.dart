import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_elevation.dart';
import 'package:mynote/core/ui/app_divider.dart';
import 'package:material_ui/material_ui.dart';

/// 只测「`AppDivider` 的默认值**来自 token 而非硬编码**」。缩进/厚度传进去再断言
/// 原样出来是 Flutter `Divider` 的行为，测它等于测框架 —— 不写。
void main() {
  testWidgets('默认 thickness 与色都取自 token，不缩进', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppDivider())),
    );

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.thickness, AppStroke.divider);
    expect(divider.color, const AppColors.light().divider);
    expect(divider.indent, 0);
    expect(divider.endIndent, 0);
  });
}
