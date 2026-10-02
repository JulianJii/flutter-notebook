import 'package:init/features/survey/data/models/survey_model.dart';
import 'package:init/core/error/exceptions.dart';

abstract class SurveyRemoteDataSource {
  Future<void> submitSurvey(SurveyModel survey);
  Future<bool> isUsernameAvailable(String username);
}

class SurveyRemoteDataSourceImpl implements SurveyRemoteDataSource {
  // 模拟已占用的用户名数据库
  final List<String> _takenUsernames = ['admin', 'root', 'superuser', 'test'];

  @override
  Future<void> submitSurvey(SurveyModel survey) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));

    // 模拟可能发生的失败
    if (survey.username == 'error_trigger') {
      throw ServerException(message: 'Simulated server error');
    }

    // 成功
    return;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    // 模拟异步校验时的网络延迟
    await Future.delayed(const Duration(milliseconds: 500));

    return !_takenUsernames.contains(username.toLowerCase());
  }
}
