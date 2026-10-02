import 'package:fpdart/fpdart.dart';
import 'package:init/core/error/failures.dart';
import 'package:init/features/notifications/domain/repositories/notification_repository.dart';

class ClearNotificationsUseCase {
  final NotificationRepository _repository;

  ClearNotificationsUseCase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.clearAll();
  }
}
