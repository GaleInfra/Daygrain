import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart' as prefix;
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/translate/microsoft_translate.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/sp_util.dart';

import 'lru_map.dart';

/// create: 2023/5/17
/// desc: 翻译管理工具
class TranslateManager {
  final appConfig = prefix.Get.find<AppConfigManager>();

  /// 使用的翻译类型
  int _type = 1;

  /// 以LRU算法存储的翻译缓存，限制500条
  late LRUMap cache;

  GoogleTranslationUtils? _translation;

  TranslateManager() {
    // 获取翻译类型
    int? type = appConfig.getAppConfigByKey("translate_type");
    if (type != null) {
      _type = type;
    }
    String? googleKey = appConfig.getAppConfigByKey("translate_v2");
    if (googleKey == null || googleKey.isEmpty) {
      googleKey = appConfig.getAppConfigByKey("glt");
    }

    if (googleKey != null && googleKey.isNotEmpty) {
      _translation = GoogleTranslationUtils.initialize(apiKey: googleKey);
    }

    cache = LRUMap<String, dynamic>(capacity: 500, onNewSave: _onNewSave);

    /// 获取本地翻译缓存
    String jsonStr = SPUtil.getString(MyKeys.translateJson);
    if (jsonStr.isNotEmpty) {
      cache.fromJson(jsonDecode(jsonStr));
    }
  }

  /// 翻译
  /// [saveCache] 保存缓存
  Future trans({
    required String content,
    required Function(String result) onSuccess,
    required Function(String msg) onFail,
    bool saveCache = true,
  }) async {
    if (_type == 1) {
      // 微软翻译
      await microsoftTranslate.trans(
        content: content,
        onSuccess: (data) {
          // 翻译成功，保存缓存
          if (saveCache) {
            // md5算法后保存
            cache.put(MD5("${content}_${BHLanguageMar().currentLang}"), data);
          }
          onSuccess.call(data);
        },
        onFail: onFail,
      );
    } else {
      // 谷歌翻译
      try {
        if (_translation == null) {
          throw Exception("not initialized");
        }
        String? model = await _translation!
            .translate(text: content, target: BHLanguageMar().currentLang);
        if (model == null) {
          throw Exception("translate failed");
        }
        // 翻译成功，保存缓存
        if (saveCache) {
          // md5算法后保存
          cache.put(MD5("${content}_${BHLanguageMar().currentLang}"), model);
        }
        onSuccess.call(model);
      } catch (e) {
        onFail.call(e.toString());
      }
    }
  }

  ///获取翻译缓存
  String? getCache(String content) {
    return cache.get(MD5("${content}_${BHLanguageMar().currentLang}"));
  }

  /// 目前仅做了新词入库保存，没有做多使用词顺序刷新保存
  /// 新保存回调
  void _onNewSave(dynamic key, dynamic value) {
    SPUtil.setString(MyKeys.translateJson, jsonEncode(cache.data));
  }
}

class GoogleTranslationUtils {
  static GoogleTranslationUtils? singleton;

  // Initialize GoogleTranslateController singleton
  static GoogleTranslationUtils initialize({
    required String apiKey,
  }) {
    return singleton = GoogleTranslationUtils(
        apiKey: apiKey, cacheDuration: const Duration(days: 7));
  }

  //key
  final String apiKey;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: "https://translation.googleapis.com/",
  ));
  final completer = Completer();

  GoogleTranslationUtils({
    required this.apiKey,
    required Duration cacheDuration,
  }) {
    // getTemporaryDirectory().then((cache) {
    //   _dio.interceptors.add(
    //     DioCacheInterceptor(
    //       options: CacheOptions(
    //         store: HiveCacheStore(
    //           cache.path,
    //           hiveBoxName: "google_translate_cache",
    //         ),
    //         maxStale: cacheDuration,
    //         policy: CachePolicy.forceCache,
    //         priority: CachePriority.high,
    //         hitCacheOnErrorExcept: [401, 404],
    //         allowPostMethod: false,
    //       ),
    //     ),
    //   );

    // });
    completer.complete();
  }

  Future<String?> translate({
    required String text,
    String? source,
    required String target,
  }) async {
    await completer.future;
    var queryParameters = {
      "q": text,
      "source": source,
      "target": target,
      "format": "text",
    };
    var url = "language/translate/v2";
    if (apiKey.startsWith("http")) {
      url = apiKey;
    } else {
      queryParameters["key"] = apiKey;
    }

    try {
      Response response = await _dio.get(
        url,
        queryParameters: queryParameters,
      );

      if ((response.statusCode == 200 || response.statusCode == 304) &&
          response.data?["data"]?["translations"] != null &&
          response.data["data"]?["translations"]?.length > 0) {
        return response.data["data"]?["translations"].first["translatedText"];
      }
    } catch (e) {
      // debugPrint(e.toString());
    }
    return null;
  }
}
