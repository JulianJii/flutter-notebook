import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notifications/domain/entities/notification_item_entity.dart';

/// 读取和修改应用内通知列表的契约接口。
abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationItemEntity>>> getNotifications();

  /// 追加通知（如果 id 已存在则更新）。
  Future<Either<Failure, void>> upsertNotification(
    NotificationItemEntity notification,
  );

  Future<Either<Failure, void>> markAsRead(String id);

  Future<Either<Failure, void>> markAllAsRead();

  Future<Either<Failure, void>> clearAll();
}
