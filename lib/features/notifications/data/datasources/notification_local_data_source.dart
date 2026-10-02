import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/core/constants/app_constants.dart';
import 'package:init/core/error/exceptions.dart';
import 'package:init/core/providers/storage_providers.dart';
import 'package:init/core/storage/local_storage_service.dart';
import 'package:init/features/notifications/data/models/notification_item_model.dart';

/// 通过 [LocalStorageService] 将应用内通知列表以 JSON 编码格式持久化存储。
abstract class NotificationLocalDataSource {
  Future<List<NotificationItemModel>> getNotifications();
  Future<void> saveNotifications(List<NotificationItemModel> notifications);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final LocalStorageService _localStorageService;

  NotificationLocalDataSourceImpl(this._localStorageService);

  @override
  Future<List<NotificationItemModel>> getNotifications() async {
    try {
      final data = _localStorageService.getObject(
        AppConstants.notificationsStorageKey,
      );
      if (data == null) return [];
      return (data as List)
          .map((e) => NotificationItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException(message: 'Failed to parse stored notifications: $e');
    }
  }

  @override
  Future<void> saveNotifications(
    List<NotificationItemModel> notifications,
  ) async {
    await _localStorageService.setObject(
      AppConstants.notificationsStorageKey,
      notifications.map((n) => n.toJson()).toList(),
    );
  }
}

final notificationLocalDataSourceProvider =
    Provider<NotificationLocalDataSource>((ref) {
      return NotificationLocalDataSourceImpl(
        ref.watch(localStorageServiceProvider),
      );
    });
