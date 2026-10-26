


// AFUploadUtil afUploadUtil = AFUploadUtil();
// String _kAfResKey = "af_res_key";

// /// create: 2023/5/31
// /// desc: AppsFlyer上报工具
// class AFUploadUtil {
//   AFUploadUtil._internal();

//   static final AFUploadUtil _instance = AFUploadUtil._internal();

//   factory AFUploadUtil() => _instance;

//   final _request = Get.find<RequestRepository>();

//   final _appConfig = Get.find<AppConfigManager>();

//   AppsflyerSdk? _appsflyerSdk;

//   /// af归因数据
//   Map<String, dynamic>? _afData;
//   Map<String, dynamic>? get afData => _afData;

//   /// 初始化
//   Future init() async {
//     try {
//       try {
//         String str = SPUtil.getString(_kAfResKey);
//         if (str.isNotEmpty) {
//           Map map = jsonDecode(str);
//           _afData = map.cast<String, dynamic>();
//         }
//       } catch (e) {
//         logger.e("获取归因缓存失败: $e");
//       }

//       if (_appsflyerSdk != null) {
//         return;
//       }

//       final AppsFlyerOptions options = AppsFlyerOptions(
//         afDevKey: BaseManager.instance.appInfo.appsFlyerKey,
//         appId: BaseManager.instance.appInfo.iosAppId, // Apple Application ID (for iOS only)
//         showDebug: false,
//         timeToWaitForATTUserAuthorization: 50, // for iOS 14.5
//         disableAdvertisingIdentifier: false, // Optional field
//         disableCollectASA: false, //Optional field
//         manualStart: true,
//       );
//       _appsflyerSdk = AppsflyerSdk(options);
//       await _appsflyerSdk?.initSdk(
//         registerConversionDataCallback: true,
//         registerOnAppOpenAttributionCallback: true,
//         registerOnDeepLinkingCallback: true,
//       );
//       _appsflyerSdk?.onAppOpenAttribution((res) {
//         logger.d("onAppOpenAttribution\n${prettyJson(res)}");
//       });
//       _appsflyerSdk?.onInstallConversionData((res) {
//         // 在此处获取归因数据 接口的header需要传。另外需要单独上传AF归因数据
//         logger.d("获取归因数据\n${prettyJson(res)}");
//         if (res != null) {
//           if (res is Map) {
//             if (res['status'] == 'success' &&
//                 res['payload'] != null &&
//                 res['payload'] is Map) {
//               _afData = res['payload'];
//               SPUtil.setString(_kAfResKey, jsonEncode(_afData));
//               //归因成功，上报数据
//               _request.appsFlyerAscribe(
//                 userId: _appConfig.userInfo.userId ?? "",
//                 afData: _afData,
//                 onSuccess: (result) {},
//                 onFail: (code, msg) {},
//               );
//             }
//           }
//         }
//       });
//       _appsflyerSdk?.startSDK();
//     } catch (e) {
//       logger.e("AF归因初始化失败: $e");
//     }
//   }

//   /// 上报购买
//   Future logEvent(double price) async {
//     try {
//       Map parameter = {
//         "af_revenue": price,
//         "af_price": price,
//         "af_currency": "USD",
//       };
//       await _appsflyerSdk?.logEvent("af_purchase", parameter);
//     } catch (e) {
//       logger.e("appsFlyer上报错误 ${e.toString()}");
//     }
//   }
// }
