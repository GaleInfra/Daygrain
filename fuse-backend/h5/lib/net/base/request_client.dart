import 'package:dio/dio.dart';

import 'app_dio.dart';
import 'network_exception.dart';
import 'response_parse.dart';

/// @author: zx
/// @description: 请求调用工具
class RequestClient {
  late AppDio _dio;
  static RequestClient? _instance;

  static RequestClient getInstance() {
    _instance ??= RequestClient();
    return _instance!;
  }

  ///初始化dio
  void init() {
    _dio = AppDio();
  }

  Future request(
    String url, {
    Method method = Method.get,
    Options? options,
    data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    required Success onSuccess,
    Fail? onFail,
    MessageBack? onMessageBack,
  }) async {
    var retried = false;
    while (true) {
      try {
        Response response = await _dio.request<String>(
          url,
          options: _checkOptions(method, options),
          data: data,
          queryParameters: queryParameters,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
        final shouldRetry = await onRequestSuccess(
            response, onSuccess, onFail, onMessageBack);
        if (shouldRetry && !retried) {
          retried = true;
          continue;
        }
        return;
      } on DioException catch (e) {
        final NetworkException netError = parseException(e);
        onError(netError.code, netError.message, onFail);
        return;
      } catch (e) {
        onError(HttpExceptionCode.unknownError, e.toString(), onFail);
        return;
      }
    }
  }

  Options _checkOptions(Method method, Options? options) {
    options ??= Options();
    options.method = _methodValues[method];
    return options;
  }
}

///请求类型枚举
enum Method { get, post, delete, put, patch, head }

///请求类型值
const _methodValues = {
  Method.get: "get",
  Method.post: "post",
  Method.delete: "delete",
  Method.put: "put",
  Method.patch: "patch",
  Method.head: "head",
};
