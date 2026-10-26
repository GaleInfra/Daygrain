import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html_unescape/html_unescape.dart';

import '../common_logic/banner_strong_guide_logic.dart';
import '../utils/common_util.dart';
import '../utils/sp_util.dart';

class BHLanguageMar {
  static final BHLanguageMar _instance = BHLanguageMar._internal();
  factory BHLanguageMar() => _instance;
  BHLanguageMar._internal();

  static const Map<String, String> fullNameLang = {
    'tr': 'Türkçe',
    'hi': 'हिन्दी',
    'ar': 'العربية',
    'de': 'Deutsch',
    'th': 'ไทย',
    'ja': '日本語',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'fr': 'Français',
    'ko': '한국어',
    'zh-tw': '繁體中文',
    'en': 'English',
    'vi': 'Việt',
    'ru': 'Русский',
  };

  static const Map<String, String> _languageEnglishName = {
    'th': 'Thai',
    'ko': 'Korean',
    'ar': 'Arabic',
    'fr': 'French',
    'pt': 'Portuguese',
    'es': 'Spanish',
    'it': 'Italian',
    'ja': 'Japanese',
    'en': 'English',
    'de': 'German',
    'zh-tw': 'Traditional Chinese',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'vi': 'Vietnamese',
    'ru': 'Russian',
  };

  static const List<String> supportLangList = ['en', 'ar', 'es', 'tr', 'ko', 'de', 'ja', 'it', 'hi', 'zh-tw', 'th', 'fr', 'pt', 'ru', 'vi'];

  String getLanguageName(String code) {
    return _languageEnglishName[code] ?? _languageEnglishName[defLang]!;
  }

  String get currentLangName {
    return fullNameLang[currentLang] ?? fullNameLang[defLang]!;
  }

  static const String defLang = 'en';

  String get currentLangCode {
    return currentLang.split('-').first;
  }

  String? selectLangCode;
  String get currentLang {
    if (selectLangCode?.isNotEmpty ?? false) {
      return selectLangCode!;
    }
    if (sysLangCode?.isNotEmpty ?? false) {
      return sysLangCode!;
    }
    return defLang;
  }

  String get currentLangFromApp {
    String langCode = currentLang;
    if (!supportLangList.contains(langCode)) {
      langCode = defLang;
    }
    return langCode;
  }

  String? sysLangCode;

  Future<void> init() async {
    selectLangCode = SPUtil.getString('bh_select_language_code');
    sysLangCode = WidgetsBinding.instance.window.locale.languageCode;
    if ('zh' == sysLangCode) {
      sysLangCode = 'zh-tw';
    }

    reLoadLang();
  }

  void setLang(String language) {
    if (language == selectLangCode) {
      return;
    }
    selectLangCode = language;
    SPUtil.setString('bh_select_language_code', language);
    if (Get.isRegistered<BannerStrongGuideLogic>()) {
      Get.find<BannerStrongGuideLogic>().onClearTranslate();
    }
  }

  final langMap = <String, String>{}.obs;

  void reLoadLang() async {
    try {
      String lang = currentLang;
      if (!supportLangList.contains(lang)) {
        lang = defLang;
      }
      String filePath = 'assets/translates/$lang.json';
      var jsonStr = await rootBundle.loadString(filePath);
      langMap.value = Map<String, String>.from(json.decode(jsonStr));
      isRightToLeft.value = ['ar'].contains(lang);
    } catch (e) {
      logger.d('reLoadLanguage error:$e');
    }
  }

  final isRightToLeft = false.obs;
  String get(String key) {
    if (langMap.isEmpty) {
      return key;
    }
    return langMap[key] ?? key;
  }
}

extension ImageExtension on Image {
  //图片方向判断
  Widget get bh {
    return BHLanguageMar().isRightToLeft.value
        ? Transform(
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            alignment: Alignment.center,
            child: this,
          )
        : this;
  }
}

extension StringExtension on String {
  String get bhTR {
    //fix:翻译出现 &符号变成  &amp; amp; 的bug
    return HtmlUnescape().convert(BHLanguageMar().get(this).replaceAll("&amp; amp;", "&"));
  }

  ///Base64图片转Size
  Size getImageSizeFromBase64() {
    Uint8List bytes = base64Decode(this);
    Image image = Image.memory(bytes);

    return Size(image.width ?? 0, image.height ?? 0);
  }

  Size getImageSize() {
    if (startsWith('data:image/png;base64,')) {
      final data = substring(22 + 20, 22 + 32);

      final nums = List<int>.from(data.codeUnits);
      final bytes = <int>[];

      for (var i = 0; i < nums.length; i += 4) {
        bytes.add((nums[i] << 2) + (nums[i + 1] >> 4));
        bytes.add(((nums[i + 1] & 15) << 4) + (nums[i + 2] >> 2));
        bytes.add(((nums[i + 2] & 3) << 6) + nums[i + 3]);
      }

      final width = (bytes[1] << 24) + (bytes[2] << 16) + (bytes[3] << 8) + bytes[4];
      final height = (bytes[5] << 24) + (bytes[6] << 16) + (bytes[7] << 8) + bytes[8];

      return Size(width.toDouble(), height.toDouble());
    } else {
      return const Size(0, 0);
    }
  }
}
