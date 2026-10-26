
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled1/net/api_address.dart';

import '../../utils/common_util.dart';

final _noLogApi = [
  ApiAddress.userGetOnlineStatus,
  ApiAddress.userGetMoreOnline,
  ApiAddress.userActiveing,
  ApiAddress.userModeSwitch,
];

/// @author: zx
/// @description: 打印拦截器
class MyLoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && !_noLogApi.contains(options.path)) {
      logger.d("********** Request **********\n"
          "method: ${options.method} url: ${options.uri}\n"
          "header: ${options.headers}\n"
          "param: ${prettyJson(options.queryParameters)}\n"
          "data: ${prettyJson(options.data)}\n");
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode && !_noLogApi.contains(response.requestOptions.path)) {
      logger.d("********** Response **********\n"
          "url: ${response.requestOptions.uri}\n"
          "statusMessage: ${response.statusMessage}\n"
          "statusCode: ${response.statusCode}\n"
          "data: ${response.data}");
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      logger.e("********** error **********\n"
          "url: ${err.requestOptions.uri}\n"
          "type: ${err.type}\n"
          "error: ${err.error}");
    }
    super.onError(err, handler);
  }
}
