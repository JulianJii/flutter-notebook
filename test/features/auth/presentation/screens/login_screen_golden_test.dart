import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/auth/presentation/screens/login_screen.dart';
import 'package:zoloto/zoloto.dart';

const _phoneEnv = TestEnvironment(
  name: 'phone',
  size: Size(375, 667),
  platform: TargetPlatform.android,
);

const _iphone11Env = TestEnvironment(
  name: 'iphone11',
  size: Size(414, 896),
  safeArea: EdgeInsets.only(top: 44, bottom: 34),
  platform: TargetPlatform.iOS,
);

const _tabletEnv = TestEnvironment(
  name: 'tabletPortrait',
  size: Size(1024, 1366),
  platform: TargetPlatform.android,
);

void main() {
  testGoldenWidgets('LoginScreen golden test', (tester) async {
    await expectMatchTestEnvironments(
      'login_screen',
      tester: tester,
      widget: const ProviderScope(child: LoginScreen()),
      testEnvironments: [_phoneEnv, _iphone11Env, _tabletEnv],
    );
  });
}
