import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/net/base/safety_utils.dart';
import 'package:untitled1/res/api_header.dart';
import 'package:untitled1/utils/bh_platform.dart';

import '../../base_manager.dart';
import '../api_address.dart';

/// create: 2023/4/23
/// desc: 请求头配置拦截器
class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    //判断当前是否是post请求
    if (options.method == "POST" &&
            options.baseUrl.contains(Uri.parse(ApiAddress.baseUrl).host) ||
        options.baseUrl.contains(Uri.parse(ApiAddress.logUrl).host)) {
      //header 设置 json
      options.contentType = Headers.jsonContentType;
      //判断当前请求是否为getAppConfig请求
      if (options.path == ApiAddress.appConfig) {
        //提取当前body
        Map<String, dynamic> body = {};
        if (options.data is FormData) {
          final fields = (options.data as FormData).fields;
          for (var element in fields) {
            body[element.key] = element.value;
          }
        } else if (options.data is Map) {
          body.addAll(options.data as Map<String, dynamic>);
        }
        body["http_headers"] = json.encode(getHeader());
        //AES加密当前对象
        final encryptStr = SafetyUtils.encrypt(
            json.encode(body), SafetyUtils.getAppEncryKey());
        options.data = encryptStr;
      } else {
        //提取当前body
        Map<String, dynamic> body = {};
        if (options.data is FormData) {
          final fields = (options.data as FormData).fields;
          for (var element in fields) {
            body[element.key] = element.value;
          }
        } else if (options.data is Map<String, dynamic>) {
          final m = options.data as Map<String, dynamic>;
          if (m.isNotEmpty) {
            body.addAll(m);
          }
        } else if (options.data is List) {
          final js = json.encode(options.data);

          body.addAll({"list": json.decode(js)});
        } else if (options.data != null) {
          //未知数据类型
          print("未知数据类型");
        }

        body["http_headers"] = json.encode(getHeader());
        //AES加密当前对象
        final encryptStr = SafetyUtils.encrypt(
            json.encode(body), getAppConfigManager()?.getEncryptKey() ?? "");
        options.data = encryptStr;
      }
    } else {
      options.headers.addAll(getHeader());
      if (BHPlatform.isWeb) {
        options.headers["Access-Control-Allow-Origin"] = "*";
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    //判断是否AppConfig接口
    if (response.data is String) {
      try {
        if (response.requestOptions.path.contains(ApiAddress.appConfig)) {
          var encryptStr = response.data as String;

          final decryptStr = SafetyUtils.decrypt(
              encryptStr, SafetyUtils.getAppEncryKey());
          //解析为字典
          final map = json.decode(decryptStr);
          if (map["data"] != null && map["data"] is Map) {
            final key2 =
                BaseManager.instance.appInfo.appInfoKeyModel?.key2 ?? "Booster";
            final key3 = BaseManager.instance.appInfo.appInfoKeyModel?.key3 ??
                "Fastclean";
            final key4 =
                BaseManager.instance.appInfo.appInfoKeyModel?.key4 ?? "Smartclean";

            final dataMap = map["data"] as Map<String, dynamic>;
            final key = utf8.decode(base64.decode(dataMap[key2] as String)) +
                utf8.decode(base64.decode(dataMap[key3] as String));
            final dataEncryptStr =
                utf8.decode(base64.decode(dataMap[key4] as String));
            //解密
            final dataecryptStr =
                SafetyUtils.decrypt(dataEncryptStr, key);
            //解析为对象
            map["data"] = json.decode(dataecryptStr);
            response.data = json.encode(map);
            //打印map
            print("解密成功：$map");
          }

          try {
            if (response.requestOptions.data is String) {
              final data = response.requestOptions.data as String;
              //解密
              String jsonData =
                  SafetyUtils.decrypt(data, SafetyUtils.getAppEncryKey());
              response.requestOptions.headers
                  .addAll(jsonDecode(jsonDecode(jsonData)["http_headers"]));
            }
          } catch (e) {
            print("请求头还原失败");
            print(e.toString());
          }
        } else {
          var encryptStr = response.data as String;

          final decryptStr = SafetyUtils.decrypt(
              encryptStr, getAppConfigManager()?.getEncryptKey() ?? "");
          //解析为字典
          final map = json.decode(decryptStr);

          response.data = decryptStr;

          try {
            if (response.requestOptions.data is String) {
              final data = response.requestOptions.data as String;
              //解密
              String jsonData = SafetyUtils.decrypt(
                  data, getAppConfigManager()?.getEncryptKey() ?? "");
              response.requestOptions.headers
                  .addAll(jsonDecode(jsonDecode(jsonData)["http_headers"]));
            }
          } catch (e) {
            print("请求头还原失败");
            print(e.toString());
          }
        }
      } catch (e) {
        print(e);
      }
    }
    return handler.next(response);
  }
}
