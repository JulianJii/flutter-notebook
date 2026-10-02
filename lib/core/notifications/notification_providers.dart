import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/analytics/analytics_providers.dart';
import 'package:init/core/notifications/debug_notification_service.dart';
import 'package:init/core/notifications/notification_service.dart';

/// 通知服务的 Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  // 在真实应用中，你会使用真实的通知服务实现
  // 例如 FirebaseNotificationService
  final service = DebugNotificationService();

  // 将通知事件记录到 analytics
  final analytics = ref.watch(analyticsProvider);

  // 处理通知接收事件
  service.notificationStream.listen((notification) {
    analytics.logUserAction(
      action: 'notification_received',
      category: 'notification',
      label: notification.channel ?? 'default',
      parameters: {
        'notification_id': notification.id,
        'title': notification.title,
        'foreground': notification.foreground,
      },
    );
  });

  // 处理通知点击事件
  service.notificationTapStream.listen((notification) {
    analytics.logUserAction(
      action: 'notification_tapped',
      category: 'notification',
      label: notification.channel ?? 'default',
      parameters: {
        'notification_id': notification.id,
        'action': notification.action,
      },
    );
  });

  // 初始化服务
  service.init();

  // 当 provider 被销毁时释放服务
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// 通知是否启用的 Provider
final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  final status = await service.getPermissionStatus();
  return status == NotificationPermissionStatus.authorized ||
      status == NotificationPermissionStatus.provisional;
});

/// 处理来自通知的深层链接的控制器
/// 处理来自通知的深层链接的控制器
class NotificationDeepLinkHandler extends Notifier<String?> {
  @override
  String? build() {
    final service = ref.watch(notificationServiceProvider);

    // 监听 stream，但需注意不要在 build 中产生副作用
    // 通常在 Notifier 中，我们在 build 中建立订阅，或使用 StreamProvider。
    // 这里我们将订阅并更新状态。
    final sub = service.notificationTapStream.listen(_handleNotificationTap);

    ref.onDispose(sub.cancel);

    return null;
  }

  /// 获取待处理的深层链接（如果有）
  String? get pendingDeepLink => state;

  /// 清除待处理的深层链接
  void clearPendingDeepLink() {
    state = null;
  }

  void _handleNotificationTap(NotificationMessage notification) {
    if (notification.action != null) {
      state = notification.action;
    }
  }
}

/// 通知深层链接处理器的 Provider
final notificationDeepLinkHandlerProvider =
    NotifierProvider<NotificationDeepLinkHandler, String?>(
      NotificationDeepLinkHandler.new,
    );
