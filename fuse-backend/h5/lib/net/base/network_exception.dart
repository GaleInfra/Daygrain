import 'dart:io';
import 'package:dio/dio.dart';

/// 异常封装
class NetworkException implements Exception {
  final String? _message;

  String get message => _message ?? runtimeType.toString();

  final int? _code;

  int get code => _code ?? -1;

  NetworkException(this._code, this._message);

  @override
  String toString() {
    return "code:[$code], message=[$message]";
  }
}

/// 状态码
class HttpExceptionCode {
  static const int success = 1;
  static const int successNotContent = 204;
  static const int notFound = 404;

  static const netError = 1000;
  static const int parseError = 1001;
  static const int socketError = 1002;
  static const int httpError = 1003;
  static const int timeoutError = 1004;
  static const int cancelError = 1005;
  static const int unknownError = 9999;
}

/// @author: zx
/// @description: 异常解析
NetworkException parseException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return NetworkException(HttpExceptionCode.timeoutError, "time out");
    case DioExceptionType.cancel:
      return NetworkException(HttpExceptionCode.cancelError, "cancel request");
    case DioExceptionType.badResponse:
      try {
        int errCode = (error.response?.statusCode)!;
        switch (errCode) {
          case 400:
            return NetworkException(errCode, error.response?.statusMessage);
          case 401:
            return NetworkException(
                401,
                error.response?.statusMessage == "Unauthorized"
                    ? error.response?.data['msg']
                    : error.response?.statusMessage);
          // case 403:
          //   return NetworkException(403, "服务器拒绝执行");
          // case 404:
          //   return NetworkException(errCode, "无法连接服务器");
          // case 405:
          //   return NetworkException(errCode, "无法连接服务器");
          // case 500:
          //   return NetworkException(errCode, error.response?.data['message']);
          // case 502:
          //   return NetworkException(errCode, "无效的请求");
          // case 503:
          //   return NetworkException(errCode, "服务器挂了");
          // case 505:
          //   return NetworkException(errCode, "不支持HTTP协议请求");
          default:
            return NetworkException(errCode, error.message);
        }
      } on Exception catch (_) {
        return NetworkException(-1, error.message);
      }
    case DioExceptionType.unknown:
      if (error.error is SocketException) {
        return NetworkException(1002, "Network anomalies"); // 网络异常
      } else {
        /// 未知异常
        return NetworkException(HttpExceptionCode.unknownError, error.message);
      }
    default:
      return NetworkException(HttpExceptionCode.unknownError, error.message);
  }
}
