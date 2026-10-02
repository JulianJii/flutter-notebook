// 基础用例接口
// 定义应用中所有用例的契约

import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// 所有用例的基础接口
///
/// [Output] - 用例的返回类型
/// [Params] - 用例所需的参数
abstract class UseCase<Output, Params> {
  /// 使用给定的参数执行用例
  Future<Either<Failure, Output>> call(Params params);
}

/// 不需要任何参数的用例
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
