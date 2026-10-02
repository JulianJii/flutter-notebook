import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/survey/data/datasources/survey_remote_data_source.dart';
import 'package:init/features/survey/data/repositories/survey_repository_impl.dart';
import 'package:init/features/survey/domain/repositories/survey_repository.dart';
import 'package:init/features/survey/domain/usecases/check_username_use_case.dart';
import 'package:init/features/survey/domain/usecases/submit_survey_use_case.dart';

/// 数据层依赖注入 providers
/// 这些 providers 负责创建和管理数据层实例

// --- 数据源 ---
final surveyRemoteDataSourceProvider = Provider<SurveyRemoteDataSource>((ref) {
  return SurveyRemoteDataSourceImpl();
});

// --- 仓库 ---
final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepositoryImpl(ref.watch(surveyRemoteDataSourceProvider));
});

// --- 用例 ---
final submitSurveyUseCaseProvider = Provider<SubmitSurveyUseCase>((ref) {
  return SubmitSurveyUseCase(ref.watch(surveyRepositoryProvider));
});

final checkUsernameUseCaseProvider = Provider<CheckUsernameUseCase>((ref) {
  return CheckUsernameUseCase(ref.watch(surveyRepositoryProvider));
});
