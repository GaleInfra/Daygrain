import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/business/say_hi/models/say_hi_recommend_broadcaster_model.dart';
import 'package:untitled1/common_logic/gift_manager.dart';
import 'package:untitled1/common_logic/vip_manager.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/homechange_tab_event.dart';
import 'package:untitled1/event_bus/rc_conversation/rc_total_unread_count_event.dart';
import 'package:untitled1/model/broadcaster/reward_model.dart';
import 'package:untitled1/business/say_hi/widget/say_hi_dialog.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/rong_cloud/rc_conversations_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/utils/risk_util.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
import 'package:untitled1/widget/msg_notication/message_pop_event.dart';

import '../../base_manager.dart';
import '../../common_logic/app_config_manager.dart';
import '../../common_logic/banner_strong_guide_logic.dart';
import '../../common_logic/coin_goods_logic.dart';
import '../../business/say_hi/robot_script_manager.dart';
import '../../business/say_hi/robot_chat_manager.dart';
import '../../event_bus/app_lifecycle_state_event.dart';
import '../../event_bus/none_flag/none_flag_event.dart';
import '../../net/request_repository.dart';
import '../../utils/sp_util.dart';
import '../broadcaster/widget/promotion_dialog.dart';
import '../broadcaster/widget/special_offer_dialog.dart';

class IndexLogic extends GetBaseController {
  /// 首页的key
  final GlobalKey pageKey = GlobalKey();

  final List<Map<String, dynamic>> tabItems = [
    {
      "unSelect": ImageAssets.tabsTab1,
      "select": ImageAssets.tabsTab1Select,
    },
    {
      "unSelect": ImageAssets.tabsTabFlash,
      "select": ImageAssets.tabsTabFlashSelect,
    },
    {
      "unSelect": ImageAssets.tabsTab2,
      "select": ImageAssets.tabsTab2Select,
    },
    {
      "unSelect": ImageAssets.tabsTab3,
      "select": ImageAssets.tabsTab3Select,
    },
  ];
  PageController pageController = PageController();
  final currentIndex = 0.obs;

  final unreadCount = 0.obs;

  /// 首页记录金币数，用户返回页判断金币数是否更改
  int coins = 0;

  /// 新人注册奖励
  RewardModel? rewardModel;

  /// 消息会话数监听
  StreamSubscription<RCTotalUnreadCountEvent>? _totalUnreadCountEvent;

  /// 全局配置管理
  final appConfig = Get.find<AppConfigManager>();

  /// 商品/促销商品管理
  final coinGoodsLogic = Get.find<CoinGoodsLogic>();

  // VIP 服务
  final _vipLogic = Get.find<VipManager>();

  /// 机器人话术管理器
  RobotScriptManager? _robotScriptManager;

  /// 空消息contentType
  String _contentType = "";

  /// 空消息通知
  StreamSubscription<NoneFlagEvent>? _noneFlagEvent;
  //前后台通知
  StreamSubscription? _appLifecycleSubscription;

  // 安全上报重试
  int _riskCount = 0;

  //是否首次准备弹出新用户促销
  bool isFirstShowPromotion = true;

  //首次打开时间
  DateTime? firstOpenTime;

  @override
  void onReady() async {
    super.onReady();
    firstOpenTime = DateTime.now();
    Get.find<RequestRepository>().log(event: "show", page: "IndexPage");
    _noneFlagEvent?.cancel();
    _noneFlagEvent = null;
    _totalUnreadCountEvent?.cancel();
    _totalUnreadCountEvent = null;
    _noneFlagEvent = EventBusUtil.listen<NoneFlagEvent>((event) {
      _contentType = event.contentType;
      if (Get.currentRoute == RoutePath.indexPage) {
        onDidPopNext();
      }
    });
    _totalUnreadCountEvent?.cancel();
    _totalUnreadCountEvent = EventBusUtil.listen<RCTotalUnreadCountEvent>((event) {
      unreadCount.trigger(event.count ?? 0);
    });
    RCConversationsManager().getTotalUnreadCount();
    coins = appConfig.userInfo.availableCoins ?? 0;
    // // 谷歌广告归因上报
    // await reportReferrerDetails();
    initRequest();
    onChangeIndex(appConfig.strategyModel?.initTab ?? 0);
    // /// 请求促销数据
    // requestPromotion(firstRequest: true);

    appConfig.onGetInfo();
    appConfig.getInfoflow();
    if (BaseManager.instance.appInfo.sdkVersion.isNotEmpty &&
        BaseManager.instance.appInfo.preLoginConfig == null) {
      //如果是SDK则重新获取一次策略接口
      appConfig.onGetStrategy();
    }
    // if (kReleaseMode) {
    _riskUpload();
    // }
    _onGetStrongGuide();

    // 初始化机器人话术管理器
    _initRobotScriptManager();
    
    // 初始化机器人搭讪管理器
    _initRobotChatManager();

    _appLifecycleSubscription = EventBusUtil.listen<AppLifecycleStateEvent>((event) {
      if (event.state == AppLifecycleState.resumed) {
        //回到前台
        if (BaseManager.instance.isLogin) {
          //重新加载促销数据
          requestPromotion(
            refreshSpecial: true,
            refreshPromotion: true,
            isFontAndBack: true,
          );
        }
      } else if (event.state == AppLifecycleState.paused) {}
    });
  }

  Future<void> _onGetStrongGuide() async {
    await Get.find<BannerStrongGuideLogic>().onGetStrongGuide();
  }

  onChangeIndex(int index, {isPageScroll = false}) {
    if (index == tabItems.length - 1 && index != currentIndex.value) {
      appConfig.onGetInfo();
    }
    if (currentIndex.value != index && index == 0) {
      //底部Tab回到首页调用领取金币
      //获取领取金币 (需要免费用户)
      if (!(appConfig.userInfo.isRecharge ?? false)) {
        // 检查是否已完成五个主播弹窗
        final uid = appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
            ? appConfig.userInfo.userId!.toString()
            : 'guest';
        final completedKey = 'robot_chat_completed_$uid';
        final isCompleted = SPUtil.getBool(completedKey, defaultValue: false);
        
        if (isCompleted) {
          getReqRepo()?.coinPresentedGet(onSuccess: (RewardModel data) {});
        }
      }
    }

    currentIndex.value = index;
    if (!isPageScroll) {
      try {
        if (currentIndex.value == 2) {
          EventBusUtil.fire(MessagePopEvent());
        }
        //防止页面刷新过快导致组件为加载出来就转跳
        pageController.jumpToPage(currentIndex.value);
      } catch (e) {
        logger.e(e);
      }
    }
    EventBusUtil.fire<HomeChangeTabEvent>(HomeChangeTabEvent(index: currentIndex.value));

    resetLogHandle();
  }

  void resetLogHandle() {
    if (currentIndex.value == 0) {
      logHandle.initLog('wall', subPage: appConfig.wallParentTag, terPage: appConfig.walSubTag);
    } else if (currentIndex.value == 1) {
      logHandle.initLog('match');
    } else if (currentIndex.value == 2) {
      logHandle.initLog('im', subPage: appConfig.imTag.isEmpty ? 'message' : appConfig.imTag);
    } else if (currentIndex.value == 3) {
      logHandle.initLog('my');
    }
  }

  void nextLogHandle() {
    if (currentIndex.value == 0) {
      logHandle.nextUploadLog('wall', subPage: appConfig.wallParentTag, terPage: appConfig.walSubTag);
    } else if (currentIndex.value == 1) {
      logHandle.nextUploadLog('match');
    } else if (currentIndex.value == 2) {
      logHandle.nextUploadLog('im', subPage: appConfig.imTag.isEmpty ? 'message' : appConfig.imTag);
    } else if (currentIndex.value == 3) {
      logHandle.nextUploadLog('my');
    }
  }

  /// 风控上报
  Future _riskUpload() async {
    Timer? timer;
    try {
      // 等待时长
      int time = appConfig.appConfigModel?.riskControlInfoConfig?.kInterval ?? 5;
      timer = Timer(Duration(seconds: time), () async {
        String key = appConfig.appConfigModel?.riskControlInfoConfig?.kFactor ?? "";
        String info = await RiskUtil.instance.infoEncrypt(key, false) ?? "";
        await request.riskUpload(
          info: info,
          onSuccess: (data) {},
          onFail: (code, msg) {
            if (999998 == code) {
              // 登录999998不重试
              return;
            }
            timer?.cancel();
            timer ??= Timer(const Duration(seconds: 10), () {
              _riskCount += 1;
              timer?.cancel();
              timer = null;
              if (_riskCount < 2) {
                _riskUpload();
              }
            });
          },
        );
      });
    } catch (e) {
      logger.e("风控上报错误: $e");
      timer?.cancel();
      timer ??= Timer(const Duration(seconds: 10), () {
        _riskCount += 1;
        timer?.cancel();
        timer = null;
        if (_riskCount < 2) {
          _riskUpload();
        }
      });
    }
  }

  // 进入首页请求
  Future initRequest() async {
    try {
      var list = <Future>[];
      // 发起首页弹窗请求 和 其他无需阻塞的请求
      if (Get.isRegistered<BannerStrongGuideLogic>()) {
        list.add(Get.find<BannerStrongGuideLogic>().onInitData()); // 导量和banner
      }
      list.add(coinGoodsLogic.getCoinGoodsSearch(bindPage: false));
      // 获取礼物列表
      list.add(GiftManager.to.getGift());
      list.add(requestPromotion(firstRequest: true));
      await Future.wait(list);
    } catch (e) {
      logger.e(e);
    }
  }

  /// 请求奖励和促销
  /// [firstRequest] 首次请求
  /// [refreshPromotion] 刷新新用户促销
  /// [refreshSpecial] 刷新活动促销
  /// [isFontAndBack] 是否是前后台切换
  Future requestPromotion({
    bool firstRequest = false,
    bool refreshPromotion = false,
    bool refreshSpecial = false,
    bool isFontAndBack = false,
  }) async {
    //获取当前时间

    if (appConfig.isReviewPkg.value) {
      // 审核模式，不显示弹窗
      _vipLogic.getGoods();
      return;
    }

    var list = <Future>[];
    if (firstRequest || refreshSpecial) {
      // 首次请求或刷新活动促销时
      // 每次获取活动促销之前，都获取渠道数据，用于显示最大赠送比例
      list.addAll([
        coinGoodsLogic.getCoinPayChannelGet(forceAwait: true),
        coinGoodsLogic.getCoinSpecialOffer(),
      ]);
    }
    if (firstRequest || refreshPromotion) {
      // 首次请求，或刷新新用户促销时，获取新用户促销商品
      list.add(coinGoodsLogic.getCoinPromotion());
    }

    List<SayHiRecommendBroadcasterModel> broadcasters = [];

    if (firstRequest) {
      // 首次请求获取注册奖励
      if (!(appConfig.userInfo.isRecharge ?? false)) {
        // 检查是否已完成五个主播弹窗
        final uid = appConfig.userInfo.userId?.toString().trim().isNotEmpty == true
            ? appConfig.userInfo.userId!.toString()
            : 'guest';
        final completedKey = 'robot_chat_completed_$uid';
        final isCompleted = SPUtil.getBool(completedKey, defaultValue: false);
        
        if (isCompleted) {
          list.add(request.coinPresentedGet(onSuccess: (data) {
            rewardModel = data;
            if ((rewardModel?.coins ?? 0) > 0) {
              appConfig.onGetInfo();
            }
          }));
        }
      }

      // 首次进入获取订阅商品
      list.add(_vipLogic.getGoods());

      // 首次进入获取SayHi推荐主播列表
      list.add(request.getSayHiRecommendBroadcasters(
        onSuccess: (data) {
          logger.d('SayHi推荐主播列表: $data');
          broadcasters = data;
        },
        onFail: (code, msg) {},
      ));
    }
    await Future.wait(list);
    if (isFirstShowPromotion && firstOpenTime != null) {
      isFirstShowPromotion = false;
      //获取时长
      var duration = DateTime.now().difference(firstOpenTime!).inSeconds;
      if (duration < 3) {
        //延迟5秒弹出
        await Future.delayed(Duration(seconds: 3 - duration));
      }
    }
    if (isFontAndBack) {
      return;
    }
    if (firstRequest) {
      // 显示导量
      DialogQueueUtil.to.addDialog(
        DialogQueueElement(onShow: () => StrongGuideSheetV2.show(pageKey.currentContext!)),
      );

      // 显示SayHi推荐主播列表（首个SayHi立刻展示，后续弹窗仍走队列）
      if (broadcasters.isNotEmpty) {
        for (var broadcaster in broadcasters) {
          if (broadcaster.country != null && broadcaster.country!.isNotEmpty) {
            if (Get.find<AppConfigManager>().nameByEmoji.containsKey(broadcaster.country!)) {
              broadcaster.countryAndEmoji = "${Get.find<AppConfigManager>().nameByEmoji[broadcaster.country]}${broadcaster.country}";
            } else if (Get.find<AppConfigManager>().codeByEmoji.containsKey(broadcaster.country!)) {
              broadcaster.countryAndEmoji = "${Get.find<AppConfigManager>().codeByEmoji[broadcaster.country]}${broadcaster.country}";
            } else {
              broadcaster.countryAndEmoji = broadcaster.country!;
            }
          }
        }

        try {
          // 在首个SayHi展示期间，抑制机器人弹窗，避免遮挡冲突
          if (Get.isRegistered<RobotChatManager>()) {
            Get.find<RobotChatManager>().setExternalSuppressed(true);
          }

          await SayHiDialog.show(
            bindWidget: pageKey.currentContext!,
            broadcasters: broadcasters,
            onSayHiPressed: () {
              _robotScriptManager?.onSayHiPressed(broadcasters);
            },
          );
        } catch (_) {} finally {
          if (Get.isRegistered<RobotChatManager>()) {
            Get.find<RobotChatManager>().setExternalSuppressed(false);
          }
        }
      }
    }
    // if (rewardModel != null && (rewardModel?.coins ?? 0) > 0 && firstRequest) {
    //   // 金币数大于0，且首次打开，显示注册奖励弹窗
    //   DialogQueueUtil.to.addDialog(DialogQueueElement(
    //       onShow: () => RewardDialog.show(
    //             rewardModel: rewardModel!,
    //             bindWidget: pageKey.currentContext!,
    //           )));
    // }
    if (coinGoodsLogic.promotionModel != null && (firstRequest || refreshPromotion)) {
      lastPromotionCode = coinGoodsLogic.promotionModel?.code;
      // 显示新用户促销
      DialogQueueUtil.to.addDialog(DialogQueueElement(onShow: () {
        return PromotionDialog.show(
            bindWidget: pageKey.currentContext!,
            onDismiss: () {
              //延迟 300 毫秒
              if (firstRequest) {
                Future.delayed(const Duration(milliseconds: 5000), () {
                  agentShowPromotionCount = true;
                });
              }
            });
      }));
    }
    if (coinGoodsLogic.specialOfferModel != null && (firstRequest || refreshSpecial)) {
      // 显示活动促销
      DialogQueueUtil.to.addDialog(DialogQueueElement(
          onShow: () => SpecialOfferDialog.show(
                bindWidget: pageKey.currentContext!,
              )));
    }
  }

  //上一次显示的活动促销Code
  String? lastPromotionCode;

  ///首次打开可以多一次机会
  bool agentShowPromotionCount = false;

  /// 回到当前页
  void onDidPopNext() {
    // 回到当前页重新获取用户数据
    //打点

    appConfig.onGetInfo();
    bool refreshSpecial = false;
    bool refreshPromotion = false;
    // 重新回到当前页面
    if (_contentType == "special_offer") {
      // 重新获取新活动促销
      _contentType = "";
      refreshSpecial = true;
    }
    if ((coins != appConfig.userInfo.availableCoins && lastPromotionCode != coinGoodsLogic.promotionModel?.code) || agentShowPromotionCount) {
      // 当前页面缓存金币数与用户金币数不一致，且当前没有新用户促销商品时，请求接口
      refreshPromotion = true;
      if (lastPromotionCode != null) {
        agentShowPromotionCount = false;
      }

      coins = appConfig.userInfo.availableCoins ?? 0;
    }
    if (refreshPromotion || refreshSpecial) {
      requestPromotion(
        refreshSpecial: refreshSpecial,
        refreshPromotion: refreshPromotion,
      );
    }
  }

  @override
  void onClose() {
    _totalUnreadCountEvent?.cancel();
    _noneFlagEvent?.cancel();
    _appLifecycleSubscription?.cancel();
    _robotScriptManager?.stopAllTimers();
    super.onClose();
  }

  /// 初始化机器人话术管理器
  void _initRobotScriptManager() {
    try {
      // 检查是否已经注册，如果没有则注册
      if (!Get.isRegistered<RobotScriptManager>()) {
        Get.put<RobotScriptManager>(RobotScriptManager(), permanent: true);
      }
      _robotScriptManager = Get.find<RobotScriptManager>();

      // 延迟启动定时器，确保主页完全加载完成
      Future.delayed(const Duration(milliseconds: 500), () {
        _robotScriptManager?.startRobotScriptTimers();
      });

      logger.d('Robot script manager initialized and timers started');
    } catch (e) {
      logger.e('Failed to initialize robot script manager: $e');
    }
  }

  /// 初始化机器人搭讪管理器
  void _initRobotChatManager() {
    try {
      // 检查是否已经注册，如果没有则注册
      if (!Get.isRegistered<RobotChatManager>()) {
        Get.put<RobotChatManager>(RobotChatManager(), permanent: true);
      }
      final robotChatManager = Get.find<RobotChatManager>();

      // 延迟启动定时器，确保主页完全加载完成
      Future.delayed(const Duration(milliseconds: 1000), () {
        robotChatManager.startRobotChatTimer();
      });

      logger.d('Robot chat manager initialized and timers started');
    } catch (e) {
      logger.e('Failed to initialize robot chat manager: $e');
    }
  }

}
