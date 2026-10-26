import 'dart:convert';

import 'package:dio/dio.dart';

import '../base/api_response.dart';
import 'http_transformer.dart';

/// @description: 返回体解析
/// 接口返回类型
///   {
///     "code": 0,
///     "data": {},
///     "msg": "success"
/// }
class DefaultHttpTransformer extends HttpTransformer {
  @override
  ApiResponse parse(Response response) {
    if (response.statusCode == 200) {
      //成功返回码为0
      if (response.data is Map) {
        if (response.data['code'] == 0) {
          return ApiResponse.success(response.data['data'],
              msg: response.data['msg']);
        } else {
          //处理接口自定义的异常
          return ApiResponse.failure(
              errorCode: response.data['code'], errorMsg: response.data['msg']);
        }
      } else {
        try {
          var json = jsonDecode(response.data);
          if (json['code'] == 0) {
            return ApiResponse.success(json['data'], msg: json['msg']);
          }
          return ApiResponse.failure(
              errorCode: json['code'], errorMsg: json['msg']);
        } catch (e) {
          return ApiResponse.failure(errorCode: -1, errorMsg: "error");
        }
      }
    } else {
      return ApiResponse.failure(errorCode: -1, errorMsg: "error");
    }
  }

  /// 单例对象
  static final DefaultHttpTransformer _instance =
      DefaultHttpTransformer._internal();

  /// 内部构造方法，可避免外部暴露构造函数，进行实例化
  DefaultHttpTransformer._internal();

  /// 工厂构造方法，这里使用命名构造函数方式进行声明
  factory DefaultHttpTransformer.getInstance() => _instance;
}
