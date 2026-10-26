
// import 'package:advertising_id/advertising_id.dart';
// import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_keychain/flutter_keychain.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/utils/business_device_id.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../res/my_keys.dart';
import '../js/rc_manager_js.dart';
import 'bh_platform.dart';
import 'package_info_util.dart';

/// create: 2023/4/23
/// desc: 获取设备信息工具
class DeviceUtil {
  DeviceUtil._internal();

  static final DeviceUtil _instance = DeviceUtil._internal();
  factory DeviceUtil() => _instance;

  /// 安卓设备信息
  late AndroidDeviceInfo androidDeviceInfo;

  /// ios设备信息
  late IosDeviceInfo iosDeviceInfo;
  String deviceId = "";

  //Web设备信息
  late WebBrowserInfo webBrowserInfo;

  /// 每次APP启动后生成一个新的UUID
  String? lanId;

  /// 设备时区
  String? timeZone;
  //广告标识
  String advertisingId = "00000000-0000-0000-0000-00000000000";

  String get model {
    if (BHPlatform.isAndroid) {
      return androidDeviceInfo.model;
    } else if (BHPlatform.isIOS) {
      return iosDeviceInfo.utsname.machine ?? "";
    } else if (BHPlatform.isWeb) {
      return "web";
    }
    return "";
  }

  getInfo() async {
    /// 获取设备信息
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        webBrowserInfo = await deviceInfo.webBrowserInfo;
        //Web
        // 获取顶部安全区距离

        // 获取js deviceId
        deviceId = narrowBusinessDeviceId(BaseManager.instance.appInfo.deviceId);

        if (deviceId.isEmpty) {
          deviceId = narrowBusinessDeviceId(SPUtil.getString(MyKeys.webViewDeviceId, defaultValue: deviceId));
          if (deviceId.isEmpty) {
            deviceId = narrowBusinessDeviceId(const Uuid().v4());
            SPUtil.setString(MyKeys.webViewDeviceId, deviceId);
          }
        }
      } else if (BHPlatform.isAndroid) {
        androidDeviceInfo = await deviceInfo.androidInfo;
        // const androidIdPlugin = AndroidId();
        // deviceId = await androidIdPlugin.getId() ?? "";
      } else if (BHPlatform.isIOS) {
        iosDeviceInfo = await deviceInfo.iosInfo;
        deviceId = narrowBusinessDeviceId(BaseManager.instance.appInfo.deviceId);
        if (deviceId.isEmpty) {
          /// 以包名_deviceId为规则写入key
          String key = "${packageInfoUtil.packageInfo.appName}_deviceId";
          // String? id = await FlutterKeychain.get(key: key);
          // if (id == null) {
          //   // 本地无该包的设备ID时，写入id
          //   deviceId = const Uuid().v4();
          //   await FlutterKeychain.put(key: key, value: deviceId);
          // } else {
          //   // 本地有该包的设备id时，直接读取
          //   deviceId = id;
          // }
        }
      }
    } catch (e) {
      logger.e("获取设备信息错误: $e");
    }
    lanId = const Uuid().v4();
    try {
      //获取时区
      timeZone = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      logger.e("获取设备时区错误: $e");
    }

    //判断是否Android
    if (BHPlatform.isAndroid) {
      try {
        // advertisingId = (await AdvertisingId.id(true)) ?? "00000000-0000-0000-0000-00000000000";
      } on PlatformException {
        advertisingId = "00000000-0000-0000-0000-00000000000";
      }
    }
  }

  String get platformVer {
    if (BHPlatform.isAndroid) {
      return androidDeviceInfo.version.release;
    } else if (BHPlatform.isIOS) {
      return iosDeviceInfo.systemVersion ?? "";
    } else if (BHPlatform.isWeb) {}
    return "1.0.0";
  }

  double? get toolbarHeight {
    if (BHPlatform.isWeb) {
      return kToolbarHeight + (statusBarHeight ?? 0);
    }
    return kToolbarHeight;
  }

  double? _statusBarHeight;

  double? get statusBarHeight {
    // if (BHPlatform.isWeb) {
    //   return 18.w;
    // }
    if (_statusBarHeight == null) {
      double px = double.tryParse(JSRongCloudManager.viewSafeTop?.replaceAll('px', '') ?? '0.0') ?? 0.0;
      if (px == 0.0) {
        px = double.tryParse(JSRongCloudManager.sat.replaceAll('px', '')) ?? 0.0;
      }
      _statusBarHeight = px;
    }
    return _statusBarHeight;
  }

  double? _bottomSafeHeight;
  //底部安全距离
  double get bottomSafe {
    if (_bottomSafeHeight == null) {
      double px = double.tryParse(JSRongCloudManager.viewSafeBottom?.replaceAll('px', '') ?? '0.0') ?? 0.0;
      if (px == 0.0) {
        px = double.tryParse(JSRongCloudManager.sab.replaceAll('px', '')) ?? 0.0;
      }
      _bottomSafeHeight = px;
    }
    return _bottomSafeHeight!;
  }
}
