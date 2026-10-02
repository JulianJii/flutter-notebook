import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notifications/domain/entities/notification_item_entity.dart';
import 'package:init/features/notifications/domain/repositories/notification_repository.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Future<Either<Failure, List<NotificationItemEntity>>> call() {
    return _repository.getNotifications();
  }
}
