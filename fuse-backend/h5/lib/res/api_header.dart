
import 'package:flutter/foundation.dart';
import 'package:untitled1/res/baked_config.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/rong_cloud/rc_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/sp_util.dart';

import '../base_manager.dart';
import '../utils/bh_platform.dart';
import '../utils/device_util.dart';
import '../utils/package_info_util.dart';
import 'dart:ui' as ui;

Map<String, dynamic> webHeader = {};
final String lan_id = uuid.v1();

/// Host app version reported to the backend. The H5's own pubspec version must
/// never be reported: review strategy is matched on package + this version.
String reportedAppVersion() {
  if (BaseManager.instance.appInfo.sdkVersion.isNotEmpty) {
    return BaseManager.instance.appInfo.sdkVersion;
  }
  if (BakedConfig.appVersion.isNotEmpty) return BakedConfig.appVersion;
  return PackageInfoUtil().packageInfo.version;
}

/// create: 2023/5/8
/// desc: 获取接口/socket 请求头
Map<String, dynamic> getHeader() {
  if (kIsWeb && webHeader.isNotEmpty) {
    if (SPUtil.containsKey(MyKeys.token)) {
      webHeader["Authorization"] = "Bearer ${SPUtil.getString(MyKeys.token)}";
    }
    return webHeader;
  } else {
    final appVer = reportedAppVersion();
    Map<String, dynamic> header = {
      "ver": appVer, // app版本
      "device-id":
          DeviceUtil().deviceId, //DeviceUtil().androidDeviceInfo?.id, // 设备id
      "model": DeviceUtil().model, // 手机型号，如小米
      "lang": ui.window.locale.languageCode, // 系统语言
      "sys_lan": ui.window.locale.languageCode,
      "is_anchor": "false",
      "pkg": BaseManager.instance.appInfo.packageName,
      "platform": "iOS",
      'device_lang': ui.window.locale.languageCode,
      'device_country': ui.window.locale.countryCode ?? "",
      'time_zone': DeviceUtil().timeZone,
      "platform_ver": appVer
    };

    if (SPUtil.containsKey(MyKeys.token)) {
      header.addAll(
          {"Authorization": "Bearer ${SPUtil.getString(MyKeys.token)}"});
    }
    // if (afUploadUtil.afData != null) {
    //   // 添加appsFlyer归因数据
    //   header.addAll({
    //     "utm-source": Uri.encodeComponent(afUploadUtil.afData?['media_source'] ?? ''), // AF的归因来源
    //     "af_adgroup_id": Uri.encodeComponent(afUploadUtil.afData?['adgroup_id'] ?? ''),
    //     "af_adset": Uri.encodeComponent(afUploadUtil.afData?['adset'] ?? ""),
    //     "af_adset_id": Uri.encodeComponent(afUploadUtil.afData?['adset_id'] ?? ""),
    //     "af_status": Uri.encodeComponent(afUploadUtil.afData?['af_status'] ?? ""),
    //     "af_agency": Uri.encodeComponent(afUploadUtil.afData?['agency'] ?? ""),
    //     "af_channel": Uri.encodeComponent(afUploadUtil.afData?['af_channel'] ?? ""),
    //     "campaign": Uri.encodeComponent(afUploadUtil.afData?['campaign'] ?? ""),
    //     "campaign_id": Uri.encodeComponent(afUploadUtil.afData?['campaign_id'] ?? ""),
    //   });
    // } else {
    header.addAll({"utm-source": ""});
    // }

    if (rcAreaCode() != null && (rcAreaCode()?.isNotEmpty ?? false)) {
      header.addAll({"rc_type": rcAreaCode()});
    }
    header.addAll({"sec_ver": "0"});
    //是否安卓
    if (BHPlatform.isAndroid) {
      header.addAll({"google_ad_id": DeviceUtil().advertisingId});
    }
    return header;
  }
}
