import 'package:dio/dio.dart';
import 'package:untitled1/net/base/base_url_interceptor.dart';
import 'package:untitled1/net/base/header_interceptor.dart';


/// 连接超时时间
const int _connectTimeout = 20000;

/// 接收超时时间
const int _receiveTimeout = 20000;

/// 发送超时时间
const int _sendTimeout = 20000;

/// @author: zx
/// @description: dio配置
class AppDio with DioMixin implements Dio {
  AppDio() {
    BaseOptions options = BaseOptions(
        connectTimeout: const Duration(milliseconds: _connectTimeout),
        receiveTimeout: const Duration(milliseconds: _receiveTimeout),
        sendTimeout: const Duration(milliseconds: _sendTimeout),
        validateStatus: (status) {
          /// 不使用http状态码判断状态，使用AdapterInterceptor来处理（适用于标准REST风格）
          return true;
        });
    this.options = options;
    interceptors.add(BaseUrlInterceptor());
    interceptors.add(HeaderInterceptor());
    // interceptors.add(MyLoggerInterceptor());
    httpClientAdapter = HttpClientAdapter();
  }
}
