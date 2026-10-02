import 'package:init/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';
import 'package:init/features/survey/domain/entities/survey_entity.dart';

abstract class SurveyRepository {
  Future<Either<Failure, void>> submitSurvey(SurveyEntity survey);
  Future<Either<Failure, bool>> isUsernameAvailable(String username);
}
