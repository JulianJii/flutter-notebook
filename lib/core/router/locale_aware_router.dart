import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 处理语言环境变化的路由观察者
class LocalizationRouterObserver extends NavigatorObserver {
  LocalizationRouterObserver(this.ref);
  final WidgetRef ref;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _refreshRouteWithCurrentLocale(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _refreshRouteWithCurrentLocale(newRoute);
    }
  }

  /// 使用当前语言环境刷新路由的辅助方法
  void _refreshRouteWithCurrentLocale(Route<dynamic> route) {
    // 该方法可用于更新路由特定的语言环境数据
    // 例如基于语言环境的路由参数或查询参数
  }

  /// 语言环境变化时要调用的方法
  void onLocaleChanged(Locale locale) {
    // 如有需要，可使用新的语言环境刷新当前路由
    // 对于更复杂的情况，你可能需要刷新某些路由
  }
}

/// LocalizationRouterObserver 的 Provider
final localizationRouterObserverProvider = Provider<NavigatorObserver>((ref) {
  return _LocalizationRouterObserverWithRef(ref);
});

/// 为 LocalizationRouterObserver 提供 ref 的内部实现
class _LocalizationRouterObserverWithRef extends NavigatorObserver {
  _LocalizationRouterObserverWithRef(this.ref);
  final Ref ref;


}

/// 支持语言环境感知导航的扩展
extension LocaleAwareNavigation on BuildContext {
  /// 导航到路由，保留当前语言环境
  void goWithLocale(String location) {
    GoRouter.of(this).go(location);
  }

  /// 导航到命名路由，保留当前语言环境
  void goNamedWithLocale(
    String name, {
    Map<String, String> pathParameters = const {},
  }) {
    GoRouter.of(this).goNamed(name, pathParameters: pathParameters);
  }
}
