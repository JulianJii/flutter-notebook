/// 生物识别认证尝试的结果
enum BiometricResult {
  /// 认证成功
  success,

  /// 因凭据未被识别而认证失败
  failed,

  /// 认证被用户取消
  cancelled,

  /// 设备上未录入生物识别信息
  notEnrolled,

  /// 此设备不支持生物识别
  notAvailable,

  /// 因失败尝试次数过多，生物识别被锁定
  lockedOut,

  /// 因技术错误导致认证失败
  error,
}

/// 生物识别认证的类型
enum BiometricType {
  /// 指纹认证
  fingerprint,

  /// 人脸识别
  face,

  /// 虹膜扫描
  iris,

  /// 多种生物识别方式可用
  multiple,
}

/// 生物识别认证请求的原因
enum AuthReason {
  /// 应用访问的认证
  appAccess,

  /// 交易的认证
  transaction,

  /// 访问敏感数据的认证
  sensitiveData,
}

/// 生物识别认证服务接口
abstract class BiometricService {
  /// 检查设备是否支持生物识别认证
  Future<bool> isAvailable();

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics();

  /// 使用生物识别对用户进行认证
  Future<BiometricResult> authenticate({
    required String localizedReason,
    AuthReason reason = AuthReason.appAccess,
    bool sensitiveTransaction = false,
    String? dialogTitle,
    String? cancelButtonText,
  });
}
