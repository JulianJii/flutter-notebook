import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:init/core/router/app_routes.dart';
import 'package:init/core/theme/app_theme.dart';
import 'package:init/core/ui/ui.dart';
import 'package:init/features/settings/presentation/screens/legal_screens.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 两页轻量 smoke：⛔ 不做 golden（纯静态文档，锁几何没有价值；正文文案在 l10n
/// 里，golden 会随文案改动整片飘红）。
void main() {
  Widget app(GoRouter router) => MaterialApp.router(
    theme: AppTheme.lightTheme,
    routerConfig: router,
    localizationsDelegates: <LocalizationsDelegate<dynamic>>[
      ...AppLocalizations.localizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
  );

  testWidgets('隐私政策：顶栏标题 + 全部章节标题渲染，可返回', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.privacyPolicy,
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('设置')),
        ),
        GoRoute(
          path: AppRoutes.privacyPolicy,
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('数据收集与存储'), findsOneWidget);
    expect(find.byType(AppTopBar), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();
    expect(
      find.byType(PrivacyPolicyScreen),
      findsNothing,
      reason: '返回键 pop 回上一页',
    );
  });

  testWidgets('用户协议：顶栏标题 + 章节标题渲染', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.userAgreement,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.userAgreement,
          builder: (context, state) => const UserAgreementScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(app(router));
    await tester.pumpAndSettle();

    expect(find.text('用户协议'), findsOneWidget);
    expect(find.text('内容归属'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}