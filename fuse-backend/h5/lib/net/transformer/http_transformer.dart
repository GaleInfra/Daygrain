import 'package:dio/dio.dart';

import '../base/api_response.dart';

/// @author: zx
/// @description: Response 解析，解析不同返回格式
abstract class HttpTransformer {
  ApiResponse parse(Response response);
}