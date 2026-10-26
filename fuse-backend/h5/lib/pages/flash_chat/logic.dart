import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/index/logic.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/permission_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/msg_notication/message_notication.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';

import '../../common_logic/app_config_manager.dart';
import '../../config/route.dart';
import '../../event_bus/app_lifecycle_state_event.dart';
import '../../event_bus/base/event_bus_util.dart';
import '../../res/pay_entry.dart';
import '../../widget/dialog/recharge_dialog.dart';

/// 注意，因为club主播推荐位提层到与促销相同位置的[HomePageDialog]中，显示所以[FlashChatLogic]类也提前到[IndexPage]中注入
class FlashChatLogic extends GetBaseController {


  /// 页面可见度
  double pagePercentage = 0;

  int matchIndex = 0;

  Worker? worker;

  final videoHandler = Get.find<VideoCallHandler>();
  StreamSubscription<AppLifecycleStateEvent>? _appLifecycleStateEvent;

  //支付结果监听
  StreamSubscription<RechargeSuccessEvent>? _payResultEvent;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

  }

  @override
  void onReady() {
    // 在tab切换时，页面中的VisibilityDetector有时候不会生效，所以在这里在监听一下
    worker = ever(Get.find<IndexLogic>().currentIndex, (callback) {
      if (callback == 2) {
        onChangeVisiblePercentage(100);
      } else {
        onChangeVisiblePercentage(0);
      }
    });
    _appLifecycleStateEvent =
        EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        if (pagePercentage == 100) {
          onChangeVisiblePercentage(100);
        }
        Get.find<AppConfigManager>().onGetStrategy();
      } else if (event.state == AppLifecycleState.paused) {
      }
    });

    _payResultEvent = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      Get.find<AppConfigManager>().onGetStrategy();
    });

    super.onReady();
  }

  

  /// 当前页面可见度
  void onChangeVisiblePercentage(double percentage) {
    if (percentage == 100) {
      // 重新回到当前页面
      
    } else {
      // 离开页面，停止刷新
      
    }
    pagePercentage = percentage;
  }

  /// 发起匹配
  void onJumpMatch(int matchIndex, {bool isGoddessMatch = false}) {
    if (videoHandler.onCallModel != null) {
      logger.i(
          "发起匹配拦截 onCallModel : ${prettyJson(videoHandler.onCallModel?.toJson())}");
      return;
    }
  
    // WKWebView 上 connectivity_plus 偶发永不回调，匹配会整页卡住；3s 超时后按有网继续。
    Connectivity()
        .checkConnectivity()
        .timeout(const Duration(seconds: 3), onTimeout: () => ConnectivityResult.wifi)
        .then((result) {
      if (result == ConnectivityResult.none) {
        // 没有网络，直接清空清空数据
        Toast.showMsg("suggestion_checkNetworkSettings".bhTR);
      } else {
        throttleUtil.throttle(() async {
          final appConfig = Get.find<AppConfigManager>();

          // 设置全局匹配类型参数
          appConfig.setMatchType(matchIndex, isGoddessMatch);
    
          // 女神匹配逻辑
          if (isGoddessMatch) {
            if (VipPrivilegesSheet.shouldGateNonVip()) {
              VipPrivilegesSheet.show();
              return;
            }
            final requiredCoins = appConfig.strategyModel?.genderMatchCoin
                    ?.goddessMatchCoins(hasEquity: true) ??
                0;
            if ((appConfig.userInfo.availableCoins ?? 0) >= requiredCoins) {
              try {
                await checkCameraAndMicrophonePermission(
                    showDialog: true, isAwait: true);
              } catch (e) {
                logger.e(e);
                //点击获取权限则中断流程
                return;
              }
              // 金币充足，进入女神匹配
              print("进入女神匹配，金币数量: ${appConfig.userInfo.availableCoins}");
              //关闭消息弹窗
              MessageNotication.dismiss();
              Get.toNamed(RoutePath.startMatchPage);
            } else {
              // 金币不足，提示充值
              print("女神匹配金币不足，当前金币: ${appConfig.userInfo.availableCoins}");
              Toast.showMsg("error_insufficientDiamonds".bhTR);
              RechargeDialog.show(entry: PayEntry.SOURCE_28, bindWidget: null);
            }
            return;
          }

            
          // 普通匹配逻辑
          if ((appConfig.strategyModel?.flashChatConfig?.isFreeCall ?? false) &&
              (appConfig.strategyModel?.flashChatConfig?.residueFreeCallTimes ??
                      0) >
                  0) {
            try {
              await checkCameraAndMicrophonePermission(
                  showDialog: true, isAwait: true);
            } catch (e) {
              logger.e(e);
              //点击获取权限则中断流程
              return;
            }
            // 当前有免费匹配次数，正常进入匹配
            print(
                "进入普通匹配，免费次数: ${appConfig.strategyModel?.flashChatConfig?.residueFreeCallTimes}");
            //关闭消息弹窗
            MessageNotication.dismiss();
            Get.toNamed(RoutePath.startMatchPage);
          } else {
            if (VipPrivilegesSheet.shouldGateNonVip()) {
              VipPrivilegesSheet.show();
              return;
            }
            // 非免费匹配
            if ((appConfig.userInfo.availableCoins ?? 0) >=
                (appConfig.strategyModel?.genderMatchCoin?.femaleCoins ?? 0)) {
              try {
                await checkCameraAndMicrophonePermission(
                    showDialog: true, isAwait: true);
              } catch (e) {
                logger.e(e);
                //点击获取权限则中断流程
                return;
              }
              // 金币充足，正常进入匹配
              print("进入普通匹配，金币数量: ${appConfig.userInfo.availableCoins}");
              //关闭消息弹窗
              MessageNotication.dismiss();
              Get.toNamed(RoutePath.startMatchPage);
            } else {
              // 金币不足，随机获取主播并进入金币不足
              print("普通匹配金币不足，当前金币: ${appConfig.userInfo.availableCoins}");
              Toast.showMsg("error_insufficientDiamonds".bhTR);
              RechargeDialog.show(entry: PayEntry.SOURCE_28, bindWidget: null);
            }
          }
        }, key: "on_jump_match", time: 2000);
      }
    });
  }

  @override
  void onClose() {
    worker?.dispose();
    _appLifecycleStateEvent?.cancel();
    _appLifecycleStateEvent = null;
    _payResultEvent?.cancel();
    _payResultEvent = null;
    super.onClose();
  }
}
