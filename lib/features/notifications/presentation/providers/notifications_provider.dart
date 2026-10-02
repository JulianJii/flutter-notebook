import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/notifications/notification_providers.dart';
import 'package:init/core/notifications/notification_service.dart';
import 'package:init/features/notifications/domain/entities/notification_item_entity.dart';
import 'package:init/features/notifications/providers/notification_feature_providers.dart';

/// 表现层状态管理
/// 本文件仅包含与 UI 相关的状态提供者

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState {
  final NotificationsStatus status;
  final List<NotificationItemEntity> items;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationItemEntity>? items,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    // 将设备级通知（见 core/notifications）桥接到持久化的应用内通知列表中。
    final service = ref.watch(notificationServiceProvider);
    final subscription = service.notificationStream.listen(_handleIncoming);
    ref.onDispose(subscription.cancel);

    return const NotificationsState();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(
      status: NotificationsStatus.loading,
      errorMessage: null,
    );

    final result = await ref.read(getNotificationsUseCaseProvider).call();

    result.fold(
      (failure) => state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: failure.message,
      ),
      (items) => state = state.copyWith(
        status: NotificationsStatus.loaded,
        items: items,
      ),
    );
  }

  Future<void> markAsRead(String id) async {
    final previous = state.items;
    state = state.copyWith(
      items: [
        for (final n in previous)
          if (n.id == id) n.copyWith(isRead: true) else n,
      ],
    );

    final result = await ref.read(markNotificationReadUseCaseProvider).call(id);
    result.fold(
      (failure) => state = state.copyWith(
        items: previous,
        errorMessage: failure.message,
      ),
      (_) {},
    );
  }

  Future<void> markAllAsRead() async {
    final previous = state.items;
    state = state.copyWith(
      items: [for (final n in previous) n.copyWith(isRead: true)],
    );

    final result = await ref
        .read(markAllNotificationsReadUseCaseProvider)
        .call();
    result.fold(
      (failure) => state = state.copyWith(
        items: previous,
        errorMessage: failure.message,
      ),
      (_) {},
    );
  }

  Future<void> clearAll() async {
    final previous = state.items;
    state = state.copyWith(items: const []);

    final result = await ref.read(clearNotificationsUseCaseProvider).call();
    result.fold(
      (failure) => state = state.copyWith(
        items: previous,
        errorMessage: failure.message,
      ),
      (_) {},
    );
  }

  Future<void> _handleIncoming(NotificationMessage message) async {
    final item = NotificationItemEntity(
      id: message.id,
      title: message.title ?? 'Notification',
      body: message.body ?? '',
      receivedAt: DateTime.now(),
      channel: message.channel,
      action: message.action,
    );

    await ref.read(upsertNotificationUseCaseProvider).call(item);
    await loadNotifications();
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );
