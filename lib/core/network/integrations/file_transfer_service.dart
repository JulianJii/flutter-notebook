import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_transfer_service.g.dart';

/// 基于 Dio 构建的分片上传和带进度的下载功能。
///
/// 两个操作都通过 [onProgress] 报告 0.0-1.0 范围的进度；
/// 当服务器提供 `Content-Length`/响应大小时，Dio 会据此计算进度
///（某些服务器会省略此值，这种情况下进度在完成前不会达到 1.0——
/// 应在 UI 中处理此情况，而不是假设进度总是平滑递增）。
class FileTransferService {
  FileTransferService(this._dio);

  final Dio _dio;

  /// 将 [filePath] 以 `multipart/form-data` 形式上传到 [url]，
  /// 使用表单字段 [fieldName]，并附带额外的 [fields]。
  Future<Response<dynamic>> upload({
    required String url,
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? fields,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final formData = FormData.fromMap({
      ...?fields,
      fieldName: await MultipartFile.fromFile(filePath),
    });

    return _dio.post<dynamic>(
      url,
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
  }

  /// 将 [url] 下载到 [savePath]，在字节到达时报告进度。
  Future<Response<dynamic>> download({
    required String url,
    required String savePath,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );
  }
}

@riverpod
FileTransferService fileTransferService(Ref ref) => FileTransferService(Dio());
