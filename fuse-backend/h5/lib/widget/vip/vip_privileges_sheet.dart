import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/event_bus/app_lifecycle_state_event.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/generated/assets.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/coin_goods_model.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/res/constant.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/dialog_queue_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/local_price_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/dialog/pay_channel_dialog.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/bgm_event.dart';
import 'package:untitled1/event_bus/recharge/recharge_success_event.dart';
import 'package:untitled1/widget/dialog/vip_coin_gift_dialog.dart';
import 'package:video_player/video_player.dart';
import 'package:untitled1/business/say_hi/robot_chat_manager.dart';

/// 从底部弹出的VIP特权展示组件
class VipPrivilegesSheet extends StatefulWidget {
  final bool fromRobotChat;
  
  VipPrivilegesSheet({Key? key, this.fromRobotChat = false}) : super(key: key);

  /// 非 VIP 时是否应拦截并弹本 sheet。
  /// Web 宿主下无 VIP 商品时不拦，避免空弹窗假死；走金币/充值链路。
  static bool shouldGateNonVip() {
    final appConfig = Get.findCanNull<AppConfigManager>();
    if (appConfig?.userInfo.hasEquity ?? false) {
      return false;
    }
    if (!Get.isRegistered<CoinGoodsLogic>()) {
      return true;
    }
    final coins = Get.find<CoinGoodsLogic>();
    if (coins.vipList.isNotEmpty || coins.hasVipProducts.value) {
      return true;
    }
    // 商品已拉过且没有 VIP 档：不要挡通话/匹配
    if (coins.list.isNotEmpty) {
      return false;
    }
    return true;
  }

  /// 个人中心 / 匹配页 VIP 入口是否展示。
  /// 已有权益可看状态；有 VIP 商品可购买；无商品且未开通则隐藏。
  static bool shouldShowVipEntry() {
    final appConfig = Get.findCanNull<AppConfigManager>();
    if (appConfig?.userInfo.hasEquity ?? false) {
      return true;
    }
    if (!Get.isRegistered<CoinGoodsLogic>()) {
      return false;
    }
    final coins = Get.find<CoinGoodsLogic>();
    return coins.vipList.isNotEmpty || coins.hasVipProducts.value;
  }

  static void show({bool fromRobotChat = false}) {
    DialogQueueUtil.to.addDialog(
      DialogQueueElement(
        allowWhenGateClosed: true,
        onShow: () {
          if (Get.isRegistered<RobotChatManager>()) {
            try { Get.find<RobotChatManager>().onVipDialogShown(); } catch (_) {}
          }
          return DialogUtil.showDialog(
            alignment: Alignment.bottomCenter,
            child: VipPrivilegesSheet(fromRobotChat: fromRobotChat),
            // bindPage: true,
            tag: _tag,
            onDismiss: () {
              if (Get.isRegistered<RobotChatManager>()) {
                try { Get.find<RobotChatManager>().onVipDialogDismissed(); } catch (_) {}
              }
            },
          );
        },
      ),
    );
  }

  static const String _tag = "VipPrivilegesSheet";

  //关闭
  static void dismiss() {
    DialogUtil.dismiss(tag: _tag);
  }

  @override
  State<VipPrivilegesSheet> createState() => _VipPrivilegesSheetState();
}

class _VipPrivilegesSheetState extends State<VipPrivilegesSheet> {
  // 当前选中的订阅选项索引
  int _selectedIndex = 1; // 默认选中1 Month选项
  
  // 是否来自机器人弹窗
  bool get fromRobotChat => widget.fromRobotChat;

  // 添加CoinGoodsLogic引用
  final CoinGoodsLogic _coinGoodsLogic = Get.find<CoinGoodsLogic>();

  // 添加AppConfigManager引用
  final AppConfigManager _appConfigManager = Get.find<AppConfigManager>();

  // 周会员和月会员商品
  CoinGoodsModel? _weekVipProduct;
  CoinGoodsModel? _monthVipProduct;

  // 用于监听充值成功事件
  late StreamSubscription<RechargeSuccessEvent> _rechargeSuccessSubscription;

  // 用于监听支付成功商品代码
  late Worker _paySuccessWorker;

  // Web/WKWebView：asset+Chewie 会卡死；改用 networkUrl(assetsPrefix)+裸 VideoPlayer。
  // 先有声播放；浏览器拦截有声自动播放时静音开播，第一次点击再恢复音量。
  // 原生仍走 asset+Chewie。初始化失败/超时保留静态封面。
  VideoPlayerController? videoController;
  ChewieController? chewieController;
  final isPlaying = false.obs;
  bool _webAudioBlocked = false;
  StreamSubscription? _appLifecycleSubscription;

  @override
  void initState() {
    if (fromRobotChat) {
      try {
        EventBusUtil.fire(RobotRingPauseEvent());
      } catch (_) {}
    }

    _initBackgroundVideo();

    super.initState();
    _loadVipProducts();

    // 监听充值成功事件
    _rechargeSuccessSubscription = EventBusUtil.listen<RechargeSuccessEvent>((event) {
      // 订阅支付成功后，更新用户信息然后刷新UI
      if (event.subscribePay) {
        _updateUserInfoAndRefresh();
      }
    });

    // 使用GetX的Worker监听paySuccessGoodsCode变化
    _paySuccessWorker = ever(_coinGoodsLogic.payLogic.paySuccessGoodsCode, (String code) {
      if (code.isNotEmpty) {
        // 检查是否是VIP商品
        final isVipProduct = _coinGoodsLogic.vipList.any((item) => item.code == code);
        if (isVipProduct) {
          // 如果是VIP商品，则更新页面
          _updateUserInfoAndRefresh();
        }
      }
    });

    // 页面初始化时获取最新用户信息
    _updateUserInfoAndRefresh();
  }

  /// Flutter Web 把打包资源挂在 `assets/<assetKey>`；模块嵌入时 assetKey 带 packages 前缀。
  String _webBgVideoUrl() {
    final prefix = BaseManager.instance.assetsPrefix;
    return 'assets/$prefix${Assets.vipBGMp4}';
  }

  Future<void> _initBackgroundVideo() async {
    VideoPlayerController? controller;
    try {
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(_webBgVideoUrl()));
      } else {
        controller = VideoPlayerController.asset(Assets.vipBGMp4);
      }
      videoController = controller;
      await controller.initialize().timeout(const Duration(seconds: 5));
      if (!mounted || videoController != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);

      if (kIsWeb) {
        // Web 跳过 Chewie，直接 VideoPlayer，避免控件层卡死 WKWebView。
        await _playWebBackground(controller);
      } else {
        chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: true,
          showControls: false,
        );
        if (!controller.value.isPlaying) {
          await controller.seekTo(Duration.zero);
          await controller.play();
          isPlaying.value = true;
          if (mounted) setState(() {});
        }
      }

      _appLifecycleSubscription =
          EventBusUtil.listen<AppLifecycleStateEvent>((event) {
        final active = videoController;
        if (active == null || !active.value.isInitialized) return;
        if (event.state == AppLifecycleState.resumed) {
          if (!active.value.isPlaying) {
            active.play();
            isPlaying.value = true;
            setState(() {});
          }
        } else if (event.state == AppLifecycleState.paused) {
          if (active.value.isPlaying) {
            active.pause();
            isPlaying.value = false;
            setState(() {});
          }
        }
      });
    } catch (_) {
      try {
        await controller?.dispose();
      } catch (_) {}
      if (identical(videoController, controller)) {
        videoController = null;
      }
      chewieController?.dispose();
      chewieController = null;
      isPlaying.value = false;
    }
  }

  /// 宿主 WebView 已放开有声自动播放时直接出声。
  /// 浏览器仍拦截时静音开播，留给第一次点击恢复音量。
  Future<void> _playWebBackground(VideoPlayerController controller) async {
    _webAudioBlocked = false;
    await controller.setVolume(1);
    var audible = false;
    try {
      await controller.play();
      audible = controller.value.isPlaying;
    } catch (_) {
      audible = false;
    }
    if (!audible) {
      _webAudioBlocked = true;
      try {
        await controller.setVolume(0);
        await controller.play();
      } catch (_) {}
    }
    isPlaying.value = controller.value.isPlaying;
    if (mounted) setState(() {});
  }

  void _onBackgroundPointerDown(PointerDownEvent event) {
    if (!kIsWeb || !_webAudioBlocked) return;
    _unmuteWebBackground();
  }

  Future<void> _unmuteWebBackground() async {
    if (!_webAudioBlocked) return;
    final active = videoController;
    if (active == null || !active.value.isInitialized) return;
    _webAudioBlocked = false;
    try {
      await active.setVolume(1);
      if (!active.value.isPlaying) {
        await active.play();
      }
    } catch (_) {
      _webAudioBlocked = true;
    }
  }

  @override
  void dispose() {
    // 如果来自机器人弹窗，恢复机器人弹窗的铃声播放
    if (fromRobotChat) {
      try {
        EventBusUtil.fire(RobotRingResumeEvent());
      } catch (_) {}
    }
    
    videoController?.dispose();
    chewieController?.dispose();
    _appLifecycleSubscription?.cancel();
    // 取消订阅
    _rechargeSuccessSubscription.cancel();
    _paySuccessWorker.dispose();
    super.dispose();
  }

  // 更新用户信息并刷新UI
  Future<void> _updateUserInfoAndRefresh() async {
    // 刷新用户信息
    await _appConfigManager.onGetInfo();
    // 刷新UI
    if (mounted) {
      setState(() {
        // 这里不需要做任何事情，setState会触发重建
      });
    }
  }

  // 加载VIP商品数据
  void _loadVipProducts() {
    // 如果vipList为空，先获取商品列表
    if (_coinGoodsLogic.vipList.isEmpty) {
      _coinGoodsLogic.getCoinGoodsSearch(bindPage: false).then((_) {
        if (mounted) _initVipProducts();
      });
    } else {
      _initVipProducts();
    }
  }

  // 初始化VIP商品数据
  void _initVipProducts() {
    setState(() {
      // 查找周会员商品(subType=103)
      if (_coinGoodsLogic.vipList.isNotEmpty) {
        _weekVipProduct = _coinGoodsLogic.vipList[0];
      }

      // 查找月会员商品(subType=101)
      if (_coinGoodsLogic.vipList.length > 1) {
        _monthVipProduct = _coinGoodsLogic.vipList[1];
      }

      // 默认选中月会员
      _selectedIndex = _monthVipProduct != null ? 1 : 0;
    });
  }

  // 获取当前选中的商品。槽位为空时用 exchangeDays/validDays/validity 会员档补上。
  CoinGoodsModel? get _selectedProduct {
    final slotted = _selectedIndex == 0 ? _weekVipProduct : _monthVipProduct;
    return _coinGoodsLogic.resolveVipPurchase(slotted);
  }

  bool get _bgVideoVisible {
    if (!isPlaying.value) return false;
    final active = videoController;
    if (active == null || !active.value.isInitialized) return false;
    if (kIsWeb) return true;
    return chewieController != null;
  }

  Widget _buildBackgroundVideoLayer() {
    final active = videoController;
    if (active == null || !active.value.isInitialized) {
      return const SizedBox.shrink();
    }
    if (kIsWeb) {
      final size = active.value.size;
      final w = size.width <= 0 ? 1080.0 : size.width;
      final h = size.height <= 0 ? 1600.0 : size.height;
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: w,
          height: h,
          child: VideoPlayer(active),
        ),
      );
    }
    if (chewieController == null) {
      return const SizedBox.shrink();
    }
    return Chewie(controller: chewieController!);
  }

  @override
  Widget build(BuildContext context) {
     double aspectRatio =  1080.0/1600.0;
     double containerW = Get.width;

    double containerH = containerW / aspectRatio;

   

    //计算视频组件的宽高 使其充满屏幕
    double videoWidth = containerW;
    double videoHeight = containerW / aspectRatio;
    // double scale = 1.0; // unused
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onBackgroundPointerDown,
      child: Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
                    width: containerW,
                    height: containerH,
                    child: ClipRRect(
                      child: Container(
                        color: Colors.transparent,
                                        height: videoHeight,
                                        width: videoWidth,
                        child: Obx(
                          () => Stack(
                            children: [
                              Image.asset(Assets.vipBGJpeg,fit: BoxFit.cover,),
                              Offstage(
                                offstage: !_bgVideoVisible,
                                child: _buildBackgroundVideoLayer(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          //左上角关闭按钮 黑色圆形半透明背景 ，兼容阿拉伯语
          Positioned(
            top: 5.w + (DeviceUtil().statusBarHeight ?? 0),
            left: BHLanguageMar().isRightToLeft.value ? null : 5.w,
            right: BHLanguageMar().isRightToLeft.value ? 5.w : null,
            child: GestureDetector(
              onTap: () => VipPrivilegesSheet.dismiss(),
              child: Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF000000).withValues(alpha: .5),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 10.w,
                  ),
              ),
              
            ),
          ),
          // 内容层
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPrivilegesList(),
              _buildSubscriptionOptions(),
              _buildFooter(),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // VIP特权列表
  Widget _buildPrivilegesList() {
    return Container(
      padding: EdgeInsets.only(
        top: 90.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(left: 14.w, right: 14.w, bottom: 0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "title_vip_privileges".bhTR,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                MyGaps.vGaps11w,
                _divider(),
                _buildPrivilegeItem("Unlock 18+ video calls".bhTR, ImageAssets.vip18),
                MyGaps.vGaps5w,
                _divider(),
                _buildPrivilegeItem("Unlimited dirty chat".bhTR, ImageAssets.vipMessage),
                MyGaps.vGaps5w,
                _divider(),
                _buildPrivilegeItem("Match Hot Goddess".bhTR, ImageAssets.vipFire),
                MyGaps.vGaps5w,
                _divider(),
                _buildPrivilegeItem("Enjoy rear camera".bhTR, ImageAssets.vipPhoto),
                MyGaps.vGaps5w,
                _divider(),
                _buildPrivilegeItem("Exclusive Avatar Fame".bhTR, ImageAssets.vipVip),
                MyGaps.vGaps5w,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 分隔线
  Widget _divider() {
    return SizedBox(
      width: double.infinity,
      height: 0.5.w,
    );
  }

  // 单个特权项
  Widget _buildPrivilegeItem(String title, String iconPath) {
    return Row(
      children: [
        Image.asset(
          iconPath,
          width: 12.w,
          height: 12.w,
        ),
        SizedBox(width: 7.w),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 7.sp,
            ),
          ),
        ),
      ],
    );
  }

  // 订阅选项
  Widget _buildSubscriptionOptions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 5.w),
      child: Column(
        children: [
          if (_weekVipProduct != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              child: _buildSubscriptionCard(
                price: localPrice(_weekVipProduct!),
                orginalPrice: "\$0.01/${"unit_days".bhTR}",
                description: _weekVipProduct!.getDisplyValidity(),
                bonus: "+${_weekVipProduct?.exchangeCoin ?? 100}",
                isHot: false,
                isSelected: _selectedIndex == 0,
                orginalPriceLineThrough: false,
              ),
            ),
          if (_monthVipProduct != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              child: _buildSubscriptionCard(
                price: localPrice(_monthVipProduct!),
                orginalPrice: localPrice(_monthVipProduct!) == localOriginalPrice(_monthVipProduct!) ? localOriginalPrice(_monthVipProduct!) : "",
                description: _monthVipProduct!.getDisplyValidity(),
                bonus: "+${_monthVipProduct?.exchangeCoin ?? 500}",
                isHot: true,
                isSelected: _selectedIndex == 1,
                orginalPriceLineThrough: true,
              ),
            ),
        ],
      ),
    );
  }

  // 单个订阅卡片
  Widget _buildSubscriptionCard({
    required String price,
    required String orginalPrice,
    required String description,
    required String bonus,
    required bool isHot,
    required bool orginalPriceLineThrough,
    bool isSelected = false,
  }) {
    //渐变色边框颜色值
    final List<Color> gradientColors = isSelected ? MyColor.btnGradientColors : [const Color(0xFF404040), const Color(0xFF404040)];

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(0.5.w),
          margin: EdgeInsets.only(left: BHLanguageMar().isRightToLeft.value ? 8.w : 4.w, right: BHLanguageMar().isRightToLeft.value ? 4.w : 8.w, top: 4.w, bottom: 4.w),
          height: 27.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors, begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(4.5.w),
          ),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.5.w), color: const Color(0xFF111419)),
            child: Row(children: [
              SizedBox(
                width: 5.w,
              ),
              //单选框
              Image.asset(
                isSelected ? ImageAssets.vipIcSelected : ImageAssets.vipIcUnSelect,
                width: 11.w,
                height: 11.w,
              ),
              SizedBox(
                width: 6.w,
              ),
              //价格  原价格 价格字体大一些， 原价格小一些并且有中划线
              RichText(
                textDirection: TextDirection.ltr,
                text: TextSpan(children: <TextSpan>[
                  TextSpan(
                    text: "$price ",
                    style: TextStyle(
                      color: MyColor.white,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isHot)
                  TextSpan(
                    text: orginalPrice,
                    style: TextStyle(
                      color: MyColor.grey5D5D5D,
                      fontSize: 7.sp,
                      decoration: orginalPriceLineThrough ? TextDecoration.lineThrough:TextDecoration.none,
                    ),
                  ),
                ]),
              ),
              const Spacer(),
              //description
              SizedBox(width: 6.w),
              //描述
              Text(
                description,
                style: TextStyle(
                  color: MyColor.white,
                  fontSize: 7.sp,
                ),
              ),
              SizedBox(
                width: 5.w,
              ),
            ]),
          ),
        ),
        if (isHot)
          Positioned(
            top: 0,
            right: 0,
            // left: BHLanguageMar().isRightToLeft.value ? 0 : null,
            child: Image.asset(
              ImageAssets.hot,
              height: 8.w,
            ),
          ),
      ],
    );
  }

  // 底部按钮和条款
  Widget _buildFooter() {
    

    return GetBuilder<AppConfigManager>(
      builder: (appConfig){

    // 检查是否有VIP权益
    final hasVipEquity = appConfig.userInfo.hasEquity ?? false;

    // 获取VIP过期时间
    final expiryTimeStr = appConfig.userInfo.equityExpiryTime;

    // 格式化过期时间
    String formattedExpiryTime = "";
    if (hasVipEquity && expiryTimeStr == null) {
      formattedExpiryTime = "Lifetime".bhTR;
    }
    if (expiryTimeStr != null && expiryTimeStr.isNotEmpty) {
      try {
        DateTime expiryDate;
        if (expiryTimeStr.contains("-")) {
          // ISO格式日期字符串，如"2023-06-15T10:30:00.000Z"
          expiryDate = DateTime.parse(expiryTimeStr);
        } else {
          // 时间戳格式，如"1686827400000"
          expiryDate = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryTimeStr));
        }
        // 格式化为YYYY-MM-DD
        formattedExpiryTime = "${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}";
      } catch (e) {
        print("Error parsing expiry time: $e");
        formattedExpiryTime = "unknown".bhTR;
      }
    }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 7.5.w, vertical: 7.5.w),
          child: Column(
            children: [
              // 根据用户是否有VIP权益显示不同的内容
              hasVipEquity
                  ? Container(
                      width: double.infinity,
                      height: 22.5.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11.25.w),
                        color: Color(0xFF524B43),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "${("vip_expires".bhTR)}: $formattedExpiryTime",
                        style: TextStyle(
                          color: Color(0xFFFFDAB1),
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : MyGradientButton(
                      width: double.infinity,
                      height: 22.5.w,
                      borderRadius: BorderRadius.circular(11.25.w),
                      gradientColor: MyColor.btnGradientColors,
                      onTap: () {
                        _purchaseSelectedVip();
                      },
                      child: Text(
                        "action_buy_now".bhTR,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
              SizedBox(height: 7.5.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTextButton("vip_terms_of_use".bhTR),
                  SizedBox(width: 12.w),
                  _buildTextButton("vip_privacy".bhTR),
                  SizedBox(width: 12.w),
                  _buildTextButton("vip_restore".bhTR),
                ],
              ),
              SizedBox(height: 10.w),
            ],
          ),
        );
      }
    );
  }

  // 底部文字按钮
  Widget _buildTextButton(String text) {
    return GestureDetector(
      onTap: () {
        // 处理点击事件
        if (text == "vip_terms_of_use".bhTR) {
          // 跳转到用户协议页面
          WebViewPage.onJump(url: Constant.termsConditions, title: "terms_termsConditions".bhTR);
        } else if (text == "vip_privacy".bhTR) {
          // 跳转到隐私政策页面
          WebViewPage.onJump(url: Constant.privacyPolicy, title: "terms_privacyPolicy".bhTR);
        } else if (text == "vip_restore".bhTR) {
          // 显示刷新成功提示
          Toast.showMsg("refresh_success".bhTR);
        }
      },
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF676767),
          fontSize: 6.sp,
        ),
      ),
    );
  }

  // 购买选中的VIP商品
  void _purchaseSelectedVip() {
    final selectedProduct = _coinGoodsLogic.resolveVipPurchase(_selectedProduct);
    final appConfig = Get.find<AppConfigManager>();

    // 检查是否已经有VIP权益
    final hasVipEquity = appConfig.userInfo.hasEquity ?? false;

    if (hasVipEquity) {
      Toast.showMsg("error_already_vip".bhTR);
      return;
    }

    // 检查选中的商品是否有效
    if (selectedProduct == null || selectedProduct.code == null) {
      Toast.showMsg("error_product_incomplete".bhTR);
      return;
    }

    // // 关闭当前弹窗
    // DialogUtil.dismiss();

    // 检查是否有赠送金币
    if (selectedProduct.exchangeCoin != null && selectedProduct.exchangeCoin! > 0) {
      // 使用Worker监听支付成功
      Worker? paySuccessWorker;
      paySuccessWorker = ever(_coinGoodsLogic.payLogic.paySuccessGoodsCode, (String code) {
        if (code == selectedProduct.code) {
          // 支付成功，显示金币赠送弹窗
          Future.delayed(const Duration(milliseconds: 500), () {
            VipPrivilegesSheet.dismiss();
            VipCoinGiftDialog.show(coins: selectedProduct.exchangeCoin!.toInt());
          });
          // 取消监听
          paySuccessWorker?.dispose();
        }
      });
    }

    // 执行购买操作
    _coinGoodsLogic.onPay(
      model: selectedProduct,
      goodsType: GoodsType.normal, // 使用normal类型，因为枚举中没有vip类型
      entry: "VipPrivilegesSheet",
    );
  }
}
