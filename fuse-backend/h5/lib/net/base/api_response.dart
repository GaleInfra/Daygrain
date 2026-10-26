
import 'network_exception.dart';

/// @author: zx
/// @description: 请求返回体封装
class ApiResponse {
  late bool ok;
  dynamic data;
  String? msg; // 此字段用于接口成功时，显示tip

  ///当 [statusCode] != 200 && [code] != 1，全部封装成异常返回
  NetworkException? error;

  ApiResponse.success(this.data, {this.msg}) {
    ok = true;
  }

  ///自定义异常返回
  ApiResponse.failure({String? errorMsg, int? errorCode}) {
    ok = false;
    error = NetworkException(errorCode, errorMsg);
  }

  ///通过异常创建返回
  ApiResponse.failureFromError(this.error) {
    ok = false;
  }

  @override
  String toString() {
    return "ok: $ok, "
        "data: $data, "
        "error: ${error.toString()}";
  }
}