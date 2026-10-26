import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/other_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/banner_strong_guide/strong_guide_model.dart';
import 'package:untitled1/model/infoflow/info_flow_model.dart';
import 'package:untitled1/model/message/im_limit_model.dart';
import 'package:untitled1/model/mine/user_oss_policy_model.dart';
import 'package:untitled1/pages/broadcaster/widget/country_picker.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/rong_cloud/rc_manager.dart';
import 'package:untitled1/utils/date_time_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/sp_util.dart';

import '../model/app_config_model.dart';
import '../model/broadcaster/strategy_model.dart';
import '../model/user/user_info_model.dart';
import '../net/request_repository.dart';
import '../rong_cloud/rc_conversations_manager.dart';
import '../widget/dialog/confirm_dialog.dart';

/// create: 2023/4/23
/// desc: App 配置管理
class AppConfigManager extends GetxController {
  /// 用户数据
  late UserInfoModel userInfo;

  /// 审核模式中
  final isReviewPkg = true.obs;

  /// 是否自动翻译
  final autoTranslate = false.obs;

  /// 测试模式：强制覆盖VIP状态（用于测试）
  final testOverrideVipStatus = false.obs;
  final testVipValue = false.obs;

  String logPageEvent = ''; //埋点界面
  List<String> logPageEventList = []; //埋点界面
  //主播想选项
  String wallParentTag = ''; //主播想选项
  String walSubTag = ''; //主播想选项
  //im
  String imTag = ''; //im
  /// app配置数据
  AppConfigModel? appConfigModel;

  /// 首页下发的配置数据
  StrategyModel? strategyModel;

  /// 导量数据
  StrongGuideModel? strongGuideModel;

  /// 系统帐号
  final Set<String> systemList = {};

  final Set<String> topSystemList = {};

  /// oss上传策略
  UserOssPolicyModel? ossPolicyModel;

  /// 获取请求仓库
  final RequestRepository _request = Get.find<RequestRepository>();

  late StreamSubscription<OtherEvent> _otherEvent;

  // 是否首次注册
  bool isFirstRegister = false;

  /// 首页三方入口
  final homeThirdInIsOut = false.obs;
  final homeThirdInUrl = ''.obs;

  Map<String, String> nameByEmoji = {};
  Map<String, String> codeByEmoji = {};

  List<InfoFlowModel> infoFlowList = [];

  // VIP到期提醒定时器
  Timer? _vipExpiryTimer;

  // 是否已开启限制IM
  // isSwitchIMLimit为false，isRecharge为ture isVip为true 满足任一都不限制
  // 非审核 && 开启IM限制 && 未充值 未开通VIP
  bool get switchImLimit {
    return !isReviewPkg.value &&
        (strategyModel?.isSwitchIMLimit ?? true) &&
        userInfo.isRecharge == false &&
        userInfo.isVip == false && userInfo.hasEquity == false;
  }

  //是否为付费用户
  bool get isRecharge => userInfo.isRecharge ?? false || (userInfo.isVip ?? false);

  // 是否达到限制IM的条件，即剩余可聊天人数是否为0
  bool get meetImLimit => (strategyModel?.imSessionBalance ?? 0) == 0;

  // AppConfig 请求是否完成
  bool appConfigReady = false;

  // 添加匹配类型全局参数
  bool isGoddessMatch = false; // 是否是女神匹配
  int matchIndex = 0; // 匹配索引

  AppConfigManager() {
    // 获取本地用户数据
    String str = SPUtil.getString(MyKeys.userInfo);
    if (str.isNotEmpty) {
      userInfo = UserInfoModel.fromJson(jsonDecode(str));
    } else {
      userInfo = UserInfoModel();
    }
    if (SPUtil.containsKey(MyKeys.autoTranslate)) {
      // 存在自动翻译设置值，读取
      autoTranslate.value = SPUtil.getBool(MyKeys.autoTranslate);
    } else {
      // 不存在自动翻译设置值，默认打开
      onChangeAutoTranslate(false);
    }
    _otherEvent = EventBusUtil.listen<OtherEvent>((event) {
      if (OtherType.flashChatFreeTimes == event.type) {
        _onUpdateFlashTime(event.data);
      }
    });
    appLoadCountryList();
  }

  void appLoadCountryList() async {
    final list = await loadCountryList();
    for (var item in list) {
      nameByEmoji[item['name']] = item['emoji'];
      codeByEmoji[item['code']] = item['emoji'];
    }
  }

  /// 保存用户信息
  void saveUserInfo(UserInfoModel info, {bool isFirstRegister = false}) {
    userInfo = info;

    // 如果测试模式开启，覆盖VIP状态
    if (testOverrideVipStatus.value) {
      userInfo.isVip = testVipValue.value;
      userInfo.hasEquity = testVipValue.value;
      if (!testVipValue.value) {
        userInfo.equityExpiryTime = null;
      } else if (userInfo.equityExpiryTime == null) {
        // 如果设置为VIP但没有过期时间，设置一个一年后的过期时间
        final expiry = DateTime.now().add(Duration(days: 365));
        userInfo.equityExpiryTime = expiry.millisecondsSinceEpoch.toString();
      }
    }

    this.isFirstRegister = isFirstRegister;
    SPUtil.setString(MyKeys.userInfo, jsonEncode(info.toJson()));
    update();
    // 发出通知
    EventBusUtil.fire(OtherEvent(type: OtherType.userInfoUpdate, data: null));

    try {
      JSRongCloudManager.myRecharge((userInfo.isRecharge == true ? "1" : "0"));
    } catch (e) {
      print(e);
    }

    // 检查是否需要启动VIP到期提醒定时器
    _checkAndSetupVipExpiryTimer();
  }

  /// 检查并设置VIP到期提醒定时器
  void _checkAndSetupVipExpiryTimer() {
    // 取消现有定时器
    _vipExpiryTimer?.cancel();
    _vipExpiryTimer = null;

    // 检查用户是否是VIP
    if (userInfo.isVip != true) {
      print("用户不是VIP会员，不启动定时器");
      return;
    }

    // 检查VIP到期时间是否存在
    if (userInfo.vipExpiryTime == null || userInfo.vipExpiryTime!.isEmpty) {
      print("VIP到期时间为空，不启动定时器");
      return;
    }

    try {
      // 解析VIP到期时间（秒级时间戳）
      int expiryTimestamp = int.parse(userInfo.vipExpiryTime!);

      // 检查是否是今天到期
      if (DateTimeUtil.isToday(expiryTimestamp)) {
        print("VIP今天到期，启动定时刷新定时器");

        // 创建定时器，每分钟刷新一次用户信息
        _vipExpiryTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          print("VIP到期定时器触发，刷新用户信息");
          onGetInfo();
        });

        print("VIP到期提醒定时器已启动，将每分钟刷新用户信息");
      } else {
        print("VIP不是今天到期，不启动定时器");
      }
    } catch (e) {
      print("解析VIP到期时间出错: $e");
    }
  }

  @override
  void onClose() {
    _otherEvent.cancel();
    // 取消VIP到期提醒定时器
    _vipExpiryTimer?.cancel();
    super.onClose();
  }

  /// 改变审核状态
  onChangeReviewPkg(bool value) {
    isReviewPkg.value = value;
  }

  /// 更新是否自动翻译
  onChangeAutoTranslate(bool value) {
    autoTranslate.value = value;
    SPUtil.setBool(MyKeys.autoTranslate, autoTranslate.value);
  }

  /// 获取用户数据
  Future onGetInfo() async {
    await _request.userGetInfo(
      userId: userInfo.userId ?? "",
      bindPage: false,
      onSuccess: (data) {
        // 打印userGetInfo接口完整返回数据
        print("\n======== userGetInfo接口返回数据开始 ========");
        print("接口原始数据: ${jsonEncode(data.toJson())}");
        print("\n===== 数据详情 =====");
        try {
          Map<String, dynamic> userMap = data.toJson();
          userMap.forEach((key, value) {
            print("$key: $value");
          });
        } catch (e) {
          print("数据解析异常: $e");
        }
        print("======== userGetInfo接口返回数据结束 ========\n");

        // 检查是否有会员特权相关字段，如果有则更新到VIP权益数据中
        if (data.hasEquity != null || data.equityExpiryTime != null) {
          print("\n======== userGetInfo中的VIP权益数据 ========");
          print("hasEquity: ${data.hasEquity}");
          print("equityExpiryTime: ${data.equityExpiryTime}");

          // 不需要额外处理VIP权益数据，会直接在userInfo中保存和使用
          print("======== VIP权益数据更新结束 ========\n");
        }

        userInfo = data;
        // 更新本地用户数据
        saveUserInfo(userInfo);
      },
      onFail: (code, msg) {
        print("获取用户信息失败: code=$code, msg=$msg");
      },
    );
  }

  /// 获取app配置信息，登录后获取
  Future onGetAppConfig() async {
    String? ver = "0";
    String appConfigStr = SPUtil.getString(MyKeys.appConfig);
    if (appConfigStr.isNotEmpty) {
      // 本地存在appConfig配置数据，立即标记就绪并后台刷新
      appConfigModel = AppConfigModel.fromJson(jsonDecode(appConfigStr));
      appConfigReady = true;
      ver = appConfigModel?.ver ?? "0";
      _request.appConfig(
        ver: ver,
        onSuccess: (data) {
          if (data != null) onSaveAppConfig(data);
        },
        onFail: (code, msg) {},
      );
      return;
    }
    await _request.appConfig(
      ver: ver,
      onSuccess: (data) {
        if (data != null) {
          onSaveAppConfig(data);
        }
      },
      onFail: (code, msg) {
        //log
        print("onFail: $code, $msg");
      },
    );
  }

  //保存AppConfig
  void onSaveAppConfig(AppConfigModel config) {
    appConfigModel = config;
    SPUtil.setString(MyKeys.appConfig, jsonEncode(config.toJson()));
    appConfigReady = true;
  }

  /// 各项配置信息获取
  Future onGetStrategy({StrategyModel? model}) async {
    if (model != null) {
      strategyModel = model;
      SPUtil.setString('cached_strategy_v1', jsonEncode(model.toJson()));
    } else {
      final cached = SPUtil.getString('cached_strategy_v1');
      if (cached.isNotEmpty && strategyModel == null) {
        try {
          strategyModel = StrategyModel.fromJson(jsonDecode(cached));
        } catch (_) {}
      }
      if (strategyModel != null) {
        _request.getStrategy(
          onSuccess: (data) async {
            strategyModel = data;
            SPUtil.setString('cached_strategy_v1', jsonEncode(data.toJson()));
          },
          onFail: (code, msg) {},
        );
      } else {
        await _request.getStrategy(
          onSuccess: (data) async {
            strategyModel = data;
            SPUtil.setString('cached_strategy_v1', jsonEncode(data.toJson()));
            String strBase64 = base64Encode(utf8.encode(json.encode(strategyModel)));
            try {
              await JSRongCloudManager.updateStrategy(strBase64);
              if (strategyModel?.isReviewPkg == true && BaseManager.instance.appInfo.sdkVersion.isNotEmpty) {
                BaseManager.instance.loseLogin();
              }
            } catch (e) {}
          },
          onFail: (code, msg) {},
        );
      }
    }
    // 发出通知
    EventBusUtil.fire(OtherEvent(type: OtherType.strategyUpdate, data: null));
    if (strategyModel != null) {
      systemList.clear();
      systemList.add(strategyModel?.userServiceAccountId! ?? "");
      systemList.addAll(strategyModel?.reviewOfficialBlacklistUserIds ?? []);
      systemList.addAll(strategyModel?.officialBlacklistUserIds ?? []);
      systemList.addAll(strategyModel?.topOfficialUserIds ?? []);
      onChangeReviewPkg(strategyModel?.isReviewPkg ?? true);
      topSystemList.clear();
      topSystemList.add(strategyModel?.userServiceAccountId! ?? "");
      topSystemList.addAll(strategyModel?.topOfficialUserIds ?? []);

      if (Get.isRegistered<RCManager>()) {
        // 获取各大系统帐号未读数
        RCConversationsManager().getSystemUnreadCount();
      }
    }
    update();
  }

  void getInfoflow() async {
    await _request.getInfo_flows(
        params: {"limit": 20, "mediaType": "video", "needCallPrice": true, "page": 1},
        page: 1,
        onSuccess: (data) {
          infoFlowList = data;
        },
        onFail: (code, msg) {});
  }

  // 刷新免费匹配次数
  void _onUpdateFlashTime(int time) {
    strategyModel?.flashChatConfig?.residueFreeCallTimes = time;
    update();
  }

  /// 更新IM限制
  void onUpdateIMLimit(ImLimitModel item) {
    strategyModel?.imSessionBalance = item.balance ?? 0;
    strategyModel?.imSessionBroadcasterIds = item.broadcasterIds;
    // item.broadcasterIds?.forEach((element) {
    //   strategyModel?.imSessionBroadcasterIds?.add(element);
    // });
    update();
  }

  /// 切换免打扰
  void onSwitchDisturb({
    BuildContext? bindWidget,
    bool? isSwitchNotDisturbCall,
    bool? isSwitchNotDisturbIm,
  }) async {
    if (false == isSwitchNotDisturbIm || false == isSwitchNotDisturbCall) {
      isSwitchNotDisturbCall ??= userInfo.isSwitchNotDisturbCall ?? false;
      isSwitchNotDisturbIm ??= userInfo.isSwitchNotDisturbIm ?? false;
      await _request.switchNotDisturb(
        isSwitchNotDisturbCall: isSwitchNotDisturbCall,
        isSwitchNotDisturbIm: isSwitchNotDisturbIm,
        onSuccess: (data) {
          if (data) {
            userInfo.isSwitchNotDisturbCall = isSwitchNotDisturbCall;
            userInfo.isSwitchNotDisturbIm = isSwitchNotDisturbIm;
            update();
          }
        },
      );
    } else {
      String text = "";
      if (isSwitchNotDisturbCall == true) {
        text = "confirm_disableCallsQuestion".bhTR;
      }
      if (isSwitchNotDisturbIm == true) {
        text = "confirm_disableStrangerMessagesQuestion".bhTR;
      }
      DialogUtil.showDialog(
        bindWidget: bindWidget,
        bindPage: false,
        child: ConfirmDialog(
          title: text,
          onConfirm: () async {
            DialogUtil.dismiss();
            isSwitchNotDisturbCall ??= userInfo.isSwitchNotDisturbCall ?? false;
            isSwitchNotDisturbIm ??= userInfo.isSwitchNotDisturbIm ?? false;
            await _request.switchNotDisturb(
              isSwitchNotDisturbCall: isSwitchNotDisturbCall!,
              isSwitchNotDisturbIm: isSwitchNotDisturbIm!,
              onSuccess: (data) {
                if (data) {
                  userInfo.isSwitchNotDisturbCall = isSwitchNotDisturbCall;
                  userInfo.isSwitchNotDisturbIm = isSwitchNotDisturbIm;
                  update();
                }
              },
            );
          },
        ),
      );
    }
  }

  /// 检查是否为系统帐号
  bool onCheckSystem(String userId) {
    return systemList.contains(userId);
  }

  /// 通过key获取appConfigModel中的值
  dynamic getAppConfigByKey(String key) {
    var list = appConfigModel?.items?.where((element) => element.name == key);
    if (list?.isNotEmpty ?? false) {
      return list!.first.data;
    }
    return null;
  }

  String getEncryptKey() {
    return getAppConfigByKey("encrypt_key");
  }

  /// 静态方法获取用户信息
  static UserInfoModel get userInfoModel =>
      Get.find<AppConfigManager>().userInfo;

  // 设置匹配类型
  void setMatchType(int index, bool isGoddess) {
    matchIndex = index;
    isGoddessMatch = isGoddess;
    update();
    print(
        "全局设置匹配类型: ${isGoddessMatch ? '女神匹配' : '普通匹配'}, matchIndex: $matchIndex");
  }

  /// 切换测试VIP状态（仅用于测试）
  void toggleTestVipStatus() {
    testOverrideVipStatus.value = !testOverrideVipStatus.value;

    if (testOverrideVipStatus.value) {
      // 启用测试模式时设置为非VIP
      testVipValue.value = false;

      // 立即应用到当前用户信息
      userInfo.isVip = false;
      userInfo.hasEquity = false;
      userInfo.equityExpiryTime = null;

      // 保存并通知更新
      SPUtil.setString(MyKeys.userInfo, jsonEncode(userInfo.toJson()));
      update();
      EventBusUtil.fire(OtherEvent(type: OtherType.userInfoUpdate, data: null));
    } else {
      // 禁用测试模式时恢复正常流程，重新获取用户信息
      onGetInfo();
    }
  }
}

AppConfigManager? getAppConfigManager() {
  return Get.findCanNull<AppConfigManager>();
}
