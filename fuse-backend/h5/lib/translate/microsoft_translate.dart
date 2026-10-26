import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/net/base/my_logger_interceptor.dart';

import '../language/bh_language_manager.dart';

MicrosoftTranslate microsoftTranslate = MicrosoftTranslate();

/// create: 2023/5/17
/// desc: 微软翻译
class MicrosoftTranslate {
  MicrosoftTranslate._internal();

  static final MicrosoftTranslate _instance = MicrosoftTranslate._internal();

  factory MicrosoftTranslate() => _instance;

  static const String _baseUrl =
      "https://api.cognitive.microsofttranslator.com";

  Dio? dio;

  final appConfig = Get.find<AppConfigManager>();

  void init() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        "Ocp-Apim-Subscription-Key":
            appConfig.getAppConfigByKey("microsoft_translation_key"),
        "Content-type": "application/json",
      },
    ))
      ..interceptors.add(MyLoggerInterceptor());
  }

  /// 翻译
  Future trans({
    required String content,
    required Function(String result) onSuccess,
    required Function(String msg) onFail,
  }) async {
    if (dio == null) {
      init();
    }
    try {
      var result = await dio?.post<List<dynamic>>(
        "/translate",
        queryParameters: {
          "api-version": "3.0",
          "to": BHLanguageMar().currentLang, // 系统语言
        },
        data: "[{\"Text\":\"$content\"}]",
      );
      if (result?.statusCode == 200) {
        Map<String, dynamic> map = {};
        result?.data?.forEach((element) {
          map.addAll(element);
        });
        onSuccess.call(map['translations'][0]['text']);
      } else {
        onFail.call(result?.statusMessage ?? "");
      }
    } catch (e) {
      onFail.call(e.toString());
    }
  }
}
