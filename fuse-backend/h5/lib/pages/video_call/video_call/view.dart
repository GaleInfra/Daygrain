import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/video_call_handler.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/event_bus/base/event_bus_util.dart';
import 'package:untitled1/event_bus/keyboard_event.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/video_call/video_call/widget/flash_chat_banner.dart';
import 'package:untitled1/pages/video_call/video_call/widget/gift_ask_widget.dart';
import 'package:untitled1/pages/video_call/video_call/widget/gift_banner_widget.dart';
import 'package:untitled1/pages/video_call/video_call/widget/video_local_widget.dart';
import 'package:untitled1/pages/video_call/video_call/widget/video_remote_widget.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../res/image_assets.dart';
import '../../../res/my_gaps.dart';
import '../../../widget/dialog/report_sub_sheet.dart';
import '../../../widget/image/my_extended_network_image.dart';
import 'logic.dart';
import 'widget/video_call_input_widget.dart';

/// 视频通话页
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> with RouteAware {
  final logic = Get.find<VideoCallLogic>();
  //监听键盘
  final isShowKeyboard = false.obs;
  late StreamSubscription<KeyboardEvent> _keyboardEvent;

  @override
  void initState() {
    super.initState();
    _wakelockPlusEnable();
    // 兜底：进入视频通话页后确保关闭来电铃声，避免偶现接听后铃声未关闭
    if (Get.isRegistered<VideoCallHandler>()) {
      Get.find<VideoCallHandler>().onShopCallPlayer();
    }
    _keyboardEvent = EventBusUtil.listen<KeyboardEvent>((event) {
      isShowKeyboard.value = event.isShow;
    });
    // //开启禁止截屏录屏
    // if (BHPlatform.isAndroid) {
    //   ScreenProtector.protectDataLeakageOn();
    // }
    // if (BHPlatform.isIOS) {
    //   //禁止截屏
    //   ScreenProtector.preventScreenshotOn();
    // }
  }

  @override
  void dispose() {
    if (!kIsWeb) WakelockPlus.disable();
    _keyboardEvent.cancel();
    // if (BHPlatform.isIOS) {
    //   ScreenProtector.preventScreenshotOff();
    // }
    // if (BHPlatform.isAndroid) {
    //   ScreenProtector.protectDataLeakageOff();
    // }
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  _wakelockPlusEnable() async {
    Future.delayed(const Duration(seconds: 2), () async {
      if (Get.currentRoute == RoutePath.videoCallPage) {
        if (!kIsWeb) await WakelockPlus.enable();
      }
    });
  }

  @override
  void didChangeDependencies() async {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    // 返回当前页
    logic.onListenPageShow(true);
    super.didPopNext();
  }

  @override
  void didPushNext() {
    // 前进到下一页
    logic.onListenPageShow(false);
    super.didPushNext();
  }

  //处理点击背景判断是否收起键盘 还是显示内容逻辑
  void _handleClickBackground() {
    if ((VideoCallInputWidget.myGlobalKey.currentState?.isShowKeyboard.value ?? false) || (VideoCallInputWidget.myGlobalKey.currentState?.showEmoji ?? false)) {
      VideoCallInputWidget.myGlobalKey.currentState?.onCloseAll(unFocus: true);
      return;
    }
    logic.isClearScreen.value = !logic.isClearScreen.value;
    VideoCallInputWidget.myGlobalKey.currentState?.onCloseAll(unFocus: true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      key: logic.pageKey,
      onWillPop: () async {
        logic.onHangUp();
        return false;
      },
      child: Container(
        color: MyColor.black,
        child: GestureDetector(
          onTap: () {
            _handleClickBackground();
          },
          child: Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: Get.width,
                    height: Get.height,
                    child: const VideoRemoteWidget(),
                  ),
                ),
                //添加点击蒙层，H5下视频会拦截点击事件
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      _handleClickBackground();
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),

                _joinTime(),
                Obx(() => Visibility(visible: !logic.isClearScreen.value, child: const _UserInfo())),

                const GiftBannerWidget(),
                Positioned(
                  top: (DeviceUtil().statusBarHeight ?? 0) + 7.w,
                  right: BHLanguageMar().isRightToLeft.value ? null : 8.w,
                  left: BHLanguageMar().isRightToLeft.value ? 8.w : null,
                  child: Obx(() => Visibility(
                        visible: !logic.isClearScreen.value,
                        child: SafeArea(
                          child: SizedBox(
                            height: 17.w,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                
                                GestureDetector(
                                  onTap: () {
                                    if (logic.userInfo?.userId != null) {
                                      VideoCallInputWidget.myGlobalKey.currentState?.onCloseAll(unFocus: true);
                                      ReportSubSheet.show(userId: logic.userInfo!.userId!, bindWidget: context);
                                    }
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(
                                    padding: EdgeInsets.only(left: 3.w, right: 3.w, top: 2.w, bottom: 4.w),
                                    decoration: BoxDecoration(
                                      color: MyColor.black.withOpacity(.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.warning_rounded,
                                        size: 10.w,
                                        color: MyColor.white,
                                      ),
                                    ),
                                  ),
                                ),
                                MyGaps.hGaps5w,
                                GestureDetector(
                                  onTap: () {
                                    VideoCallInputWidget.myGlobalKey.currentState?.onCloseAll(unFocus: true);
                                    logic.onHangUp();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(3.w),
                                    decoration: BoxDecoration(
                                      color: MyColor.black.withOpacity(.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 10.w,
                                      weight: 1.5,
                                      color: MyColor.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Obx(() => Visibility(
                        visible: !logic.isClearScreen.value,
                        child: VideoCallInputWidget(
                          key: VideoCallInputWidget.myGlobalKey,
                          context: context,
                        ),
                      )),
                ),
                VideoLocalWidget(
                  isShowMatchTime: logic.showFlachMatchDown.value,
                ),

                Positioned(
                  top: 30.w + (DeviceUtil().statusBarHeight ?? 0),
                  left: 0,
                  right: 0,
                  child: Obx(() {
                    if (logic.showFlachMatchDown.value) {
                      // 显示匹配倒计时
                      return const FlashChatBanner();
                    }
                    return const SizedBox();
                  }),
                ),

                // 礼物动画
                GetBuilder<VideoCallLogic>(
                  builder: (logic) {
                    return RepaintBoundary(
                      child: logic.giftWidget,
                    );
                  },
                ),
                //防止被输入框遮挡
                const GiftAskWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 加入倒计时
  Widget _joinTime() {
    return Obx(() {
      // double progress = logic.joinNum.value / 20;
      if (logic.joinNum.value == -1 && logic.joinState.value == VideoJoinState.joined) {
        return const SizedBox();
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 25.w,
              height: 25.w,
              child: Lottie.asset(
                'assets/lottie/video_join.json',
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(
              height: 2.w,
            ),
            Text(
              "info_hostJoining".bhTR,
              style: TextStyle(
                fontSize: 8.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// 顶部主播信息
class _UserInfo extends StatelessWidget {
  const _UserInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (DeviceUtil().statusBarHeight ?? 0) + 5.w,
      left: BHLanguageMar().isRightToLeft.value ? Get.width * .35 : 8.w,
      right: BHLanguageMar().isRightToLeft.value ? 8.w : Get.width * .35,
      child: SafeArea(
        child: GetBuilder<VideoCallLogic>(
          builder: (logic) {
            if (logic.userInfo == null) {
              return const SizedBox();
            }

            var countryText = logic.userInfo?.country ?? "";
            var appConfig = Get.find<AppConfigManager>();
            if (appConfig.nameByEmoji.containsKey(countryText)) {
              countryText = "${appConfig.nameByEmoji[countryText]}$countryText";
            } else if (appConfig.codeByEmoji.containsKey(countryText)) {
              countryText = "${appConfig.codeByEmoji[countryText]}$countryText";
            }

            return Row(
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: MyColor.black.withOpacity(.5),
                      borderRadius: BorderRadius.circular(8.5.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MyExtendedNetworkImage(
                          url: logic.userInfo?.avatarThumbUrl ?? "",
                          shape: BoxShape.circle,
                          width: 13.w,
                          height: 13.w,
                        ),
                        MyGaps.hGaps2w,
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (logic.userInfo?.nickname ?? "").fixAutoLines(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 6.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                 
                                  Flexible(
                                    child: Container(
                                      child: Text(
                                        countryText.fixAutoLines(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: MyColor.white,
                                          fontSize: 4.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                       
                        MyGaps.hGaps2w,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
