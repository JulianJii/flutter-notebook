import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notifications/domain/entities/notification_item_entity.dart';
import 'package:init/features/notifications/domain/repositories/notification_repository.dart';

class UpsertNotificationUseCase {
  final NotificationRepository _repository;

  UpsertNotificationUseCase(this._repository);

  Future<Either<Failure, void>> call(NotificationItemEntity notification) {
    return _repository.upsertNotification(notification);
  }
}
