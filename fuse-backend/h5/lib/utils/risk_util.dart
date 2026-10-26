import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:get/get.dart';
// import 'package:mobile_number/mobile_number.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/res/api_header.dart';
import 'package:untitled1/utils/common_util.dart';

import 'bh_platform.dart';
import 'device_util.dart';
import 'package_info_util.dart';
import 'risk_channel.dart';

/// create: 2024/3/26
/// desc: 风控工具
class RiskUtil {
  static final RiskUtil _instance = RiskUtil._initial();
  static RiskUtil get instance => _instance;

  RiskUtil._initial() {
    if (!kDebugMode) {
      // MobileNumber.listenPhonePermission((isPermissionGranted) {
      //   _simPermissionGranted = isPermissionGranted;
      //   getSIMInfo();
      // });
    }
  }

  // SIM卡信息是否有权限
  bool? _simPermissionGranted;

  // SIM卡国家
  String _simCountry = "";

  // SIM卡获取是否完成
  Completer? simCompleter;

  // 是否开VPN
  Future<bool> _openVpn() async {
    bool openVpn = false;
    List<NetworkInterface> list = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any);
    if (list.isNotEmpty) {
      openVpn = list.any((element) => element.name.contains("tun") || element.name.contains("ppp") || element.name.contains("pptp"));
    }
    return openVpn;
  }

  // 是否是模拟器
  bool _isSimulator() {
    if (BHPlatform.isIOS) {
      return !DeviceUtil().iosDeviceInfo.isPhysicalDevice;
    } else if (BHPlatform.isAndroid) {
      return !DeviceUtil().androidDeviceInfo.isPhysicalDevice;
    }
    return true;
  }

  // 开启代理
  Future<bool> _openProxy() async {
    // 因测试反馈说开了代理但识别为0，所以直接走原生
    if (BHPlatform.isAndroid) {
      return await RiskChannel.instance.getProxy();
    } else {
      ConnectivityResult connectivityResult = await (Connectivity().checkConnectivity());
      return connectivityResult == ConnectivityResult.vpn;
    }
  }

  // 是否越狱/root
  Future<bool> _openJailbreakOrRoot() async {
    if (BHPlatform.isIOS) {
      // return await FlutterJailbreakDetection.jailbroken;
    } else {
      if (BHPlatform.isAndroid) {
        return await RiskChannel.instance.getRoot();
      }
    }
    return false;
  }

  // 获取SIM卡信息
  Future<void> getSIMInfo() async {
    if (BHPlatform.isAndroid) {
      simCompleter ??= Completer();
      try {
        if (false == _simPermissionGranted) {
          _simCountry = "";
          simCompleter?.complete("");
          simCompleter = null;
          return;
        }
        // if (!(await MobileNumber.hasPhonePermission)) {
        //   await MobileNumber.requestPhonePermission;
        // } else {
        //   //有权限
        //   final List<SimCard>? simCards = await MobileNumber.getSimCards;
        //   if (simCards?.isNotEmpty ?? false) {
        //     _simCountry = simCards!.first.countryIso ?? '';
        //   } else {
        //     _simCountry = "";
        //   }
        //   simCompleter?.complete("");
        //   simCompleter = null;
        // }
      } catch (e) {
        logger.e("获取SIM卡信息错误: $e");
        simCompleter?.complete("");
        simCompleter = null;
      }
    }
  }

  // 安全信息
  // [onlyBase] 是否只需要基础数据
  Future<Map<String, dynamic>> _safeInfo(bool onlyBase) async {
    if (kIsWeb) {
      final ver = reportedAppVersion();
      final map = <String, dynamic>{
        "platform": "iOS",
        "pkg": BaseManager.instance.appInfo.packageName,
        "ver": ver,
        "platform_ver": ver,
        "model": DeviceUtil().model,
        "device_id": DeviceUtil().deviceId,
        "is_enable_vpn": 0,
        "is_enable_proxy": 0,
        "system_language": '${WidgetsBinding.instance.window.locale.languageCode}'
            '-${WidgetsBinding.instance.window.locale.countryCode?.toUpperCase()}',
        "time_zone": DeviceUtil().timeZone ?? "",
      };
      if (Get.isRegistered<AppConfigManager>()) {
        map['user_id'] = Get.find<AppConfigManager>().userInfo.userId;
      }
      if (!onlyBase) {
        map["is_emulator"] = 0;
      }
      return map;
    }
    Map<String, dynamic> map = {
      "platform": BHPlatform.isIOS ? "iOS" : "Android",
      "pkg": BaseManager.instance.appInfo.packageName,
      "ver": reportedAppVersion(),
      "platform_ver": BHPlatform.isAndroid ? DeviceUtil().androidDeviceInfo.version.sdkInt : DeviceUtil().iosDeviceInfo.systemVersion,
      "model": BHPlatform.isAndroid ? DeviceUtil().androidDeviceInfo.model : DeviceUtil().iosDeviceInfo.utsname.machine,
      "device_id": DeviceUtil().deviceId,
      "is_enable_vpn": await _openVpn() ? 1 : 0,
      "is_enable_proxy": await _openProxy() ? 1 : 0,
      "system_language": '${WidgetsBinding.instance.window.locale.languageCode}'
          '-${WidgetsBinding.instance.window.locale.countryCode?.toUpperCase()}',
      "time_zone": DeviceUtil().timeZone ?? "",
    };
    if (Get.isRegistered<AppConfigManager>()) {
      map['user_id'] = Get.find<AppConfigManager>().userInfo.userId;
    }
    if (BHPlatform.isAndroid) {
      // sim卡信息
      map["sim_country"] = _simCountry;
      // 是否自动设置时区
      map["is_auto_time_zone"] = await RiskChannel.instance.getAutoTimeZone() ? 1 : 0;
    }

    if (onlyBase) {
      // 只需要基础数据
      return map;
    }

    // 以下是风控上报需要增加的数据
    if (BHPlatform.isIOS) {
      // 是否越狱
      map['is_jailbreaking'] = await _openJailbreakOrRoot() ? 1 : 0;
    }
    map["is_emulator"] = _isSimulator() ? 1 : 0;
    if (BHPlatform.isAndroid) {
      // 是否多开
      map['is_run_in_virtual'] = await RiskChannel.instance.getVirtual() ? 1 : 0;
      // 是否root
      map['is_rooted'] = await _openJailbreakOrRoot() ? 1 : 0;
      // 是否hook
      map['is_hook'] = await RiskChannel.instance.getHook() ? 1 : 0;
    }
    return map;
  }

  // 对信息进行进行AES加密 ，加密后执行base64编码 RFC4648_URLSAFE
  Future<String?> infoEncrypt(String? key, bool onlyBaseInfo) async {
    try {
      if (key == null && Get.isRegistered<AppConfigManager>()) {
        key = Get.find<AppConfigManager>().appConfigModel?.riskControlInfoConfig?.kFactor;
      }
      if (key == null || key.isEmpty) {
        logger.e("加密密钥为空");
        return null;
      }
      Map<String, dynamic> info = {};
      if (BaseManager.instance.appInfo.riskInfo.isNotEmpty) {
        info = Map.from(BaseManager.instance.appInfo.riskInfo);
        if (onlyBaseInfo) {
          info.remove("user_id");
        } else {
          info["user_id"] = Get.find<AppConfigManager>().userInfo.userId;
        }
      } else {
        info = await _safeInfo(onlyBaseInfo);
      }
      final encryptStr = await _encrypt(jsonEncode(info), key);
      logger.d('安全信息:$encryptStr');
      return encryptStr;
    } catch (e) {
      logger.e("安全信息加密错误: $e");
      return null;
    }
  }

  // 加密
  Future<String> _encrypt(String plainText, String key) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(key), mode: encrypt.AESMode.ecb));
    final decryted = encrypter.encrypt(plainText);
    return base64Url.encode(decryted.bytes);
  }
}
