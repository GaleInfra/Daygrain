import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class BHPlatform {
  //Get方法
  static bool get isIOS {
    return kIsWeb ? false : Platform.isIOS;
  }

  static bool get isAndroid {
    return kIsWeb ? false : Platform.isAndroid;
  }

  static bool get isWindows {
    return kIsWeb ? false : Platform.isWindows;
  }

  static bool get isMacOS {
    return kIsWeb ? false : Platform.isMacOS;
  }

  static bool get isFuchsia {
    return kIsWeb ? false : Platform.isFuchsia;
  }

  static bool get isWeb {
    return kIsWeb;
  }
}
