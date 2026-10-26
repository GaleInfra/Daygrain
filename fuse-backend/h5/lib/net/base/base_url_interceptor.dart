import 'package:dio/dio.dart';
import 'package:untitled1/net/api_address.dart';

/// create: 2023/4/23
/// desc: 请求头配置拦截器
class BaseUrlInterceptor extends Interceptor {

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.startsWith("http")) {
      options.baseUrl = Uri.parse(options.path).origin;
    } else {
      options.baseUrl = ApiAddress.baseUrl;
    }
    return handler.next(options);
  }
}