import 'dart:async';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/common_logic/user_status_service.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/model/user/user_info_model.dart';

import '../../common_logic/video_call_handler.dart';
import '../../custom/swiper_pagination/my_swiper_pagination.dart';
import '../../event_bus/base/event_bus_util.dart';
import '../../res/my_color.dart';
import '../../res/video_call_data.dart';
import '../../utils/broadcaster_call_price_util.dart';
import '../../utils/device_util.dart';
import '../../widget/button/call_button.dart';
import '../../widget/gradient_backgrond_widget.dart';
import '../../widget/image/my_extended_network_image.dart';

/// create: 2023/4/26
/// desc: 全屏看图
class SeeImagePage extends StatefulWidget {
  const SeeImagePage({
    Key? key,
  }) : super(key: key);

  @override
  State<SeeImagePage> createState() => _SeeImagePageState();
}

class _SeeImagePageState extends State<SeeImagePage> {
  final List<String> urls = [];
  int index = 0;
  int isChat = 0;
  late PageController pageController;
  final scaleStateController = <PhotoViewScaleStateController>[];
  final scaleStateController2 = <PhotoViewController>[];

  //在线状态
  final userStatus = kOffline.obs;

  LogHandle logHandle = LogHandle();

  //监听在线状态
  StreamSubscription? _userStateEvent;
  UserInfoModel? userInfo;
  SwiperController swiperController = SwiperController();

  @override
  void initState() {
    logHandle.initEvent();
    logHandle.initLog('photo_preview');
    if (Get.arguments != null) {
      userInfo = Get.arguments['userInfo'];
      index = Get.arguments['index'] ?? 0;
      isChat = Get.arguments['isChat'] ?? 0;
      urls.addAll(Get.arguments['urls'].toList() ?? []);
      scaleStateController.addAll(urls.map((e) => PhotoViewScaleStateController()).toList());
      scaleStateController2.addAll(urls.map((e) => PhotoViewController()).toList());
      swiperController.index = index;
    }
    pageController = PageController(initialPage: index);

    if (userInfo != null) {
      userStatus.value = getUserStatusService()?.getStatus(userInfo!.userId ?? "") ?? kOffline;
      getUserStatusService()?.addUserIdAndForceRefresh(userInfo!.userId ?? "");
      _userStateEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
        if (event.uidAndStatus.containsKey(userInfo!.userId)) {
          userStatus.value = event.uidAndStatus[userInfo!.userId] ?? kOffline;
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _userStateEvent?.cancel();
    _userStateEvent = null;
    logHandle.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Stack(
        children: [
          SizedBox(
            width: Get.width,
            height: Get.height,
            child: GestureDetector(
              onTap: () {
                if (isChat == 1) {
                  Get.back();
                } else {
                  if (scaleStateController[index].isZooming) {
                    scaleStateController[index].reset();
                    return;
                  }
                  Get.back();
                }

              },
              onDoubleTap: () {
                if (scaleStateController[index].isZooming) {
                  scaleStateController[index].reset();
                } else {
                  scaleStateController[index].setInvisibly(PhotoViewScaleState.covering);
                }
              },
              child: Container(
                color: Colors.transparent,
                child: Swiper(
                  itemBuilder: (ctx, index) => InteractiveViewer(
                    minScale: 0.5, // 最小缩放比例
                    maxScale: 3.0, // 最大缩放比例
                    child: MyExtendedNetworkImage(
                      url: urls[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.fitWidth,
                      isBroadcaster: true,
                      isAnimation: false,
                    ),
                  ),
                  controller: swiperController,
                  autoplay: false,
                  loop: false,
                  scrollDirection: Axis.horizontal,
                  index: index,
                  itemCount: urls.length,
                  onIndexChanged: (value) {
                    setState(() {
                      index = value;
                    });
                  },
                  onTap: (index) {
                    if (isChat == 1) {
                  Get.back();
                    } else {
                      if (scaleStateController[index].isZooming) {
                        scaleStateController[index].reset();
                        return;
                      }
                      Get.back();
                    }
                  },
                  pagination: urls.length > 1
                      ? SwiperPagination(
                          margin: EdgeInsets.all(15.w),
                          builder:  MySwiperPagination(
                            activeColor: MyColor.white,
                            color: MyColor.white,
                            activeWidth: 6.w,
                            width: 3.w,
                            height: 3.w,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            // backgroundDecoration: widget.backgroundDecoration,
            // pageController: widget.pageController,
            // onPageChanged: onPageChanged,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 14.w,
            child: AppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              toolbarHeight: DeviceUtil().toolbarHeight,
              leading: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  Get.back();
                },
                child: SizedBox(
                  width: 35.w,
                  height: 35.w,
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: MyColor.white,
                  ),
                ),
              ),
              title: Container(),
            ),
          ),
          Positioned(
              bottom: 15.w,
              right: 0,
              left: 0,
              child: Visibility(
                visible: userInfo != null,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  padding: EdgeInsets.symmetric(horizontal: 9.w),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 15.w),
                        child: Obx(() {
                          return CallButton(
                                status: userStatus.value,
                                price: BroadcasterCallPriceUtil.displayPerMinutePriceText(
                                  broadcaster: userInfo,
                                ),
                                onTap: () {
                                   Get.findCanNull<VideoCallHandler>()?.onCheckToCall(
                                            callSource: VideoCallSource.DETAIL_VIDEO_PAGE,
                                            onlineStatus: userStatus.value,
                                            userInfo: userInfo!,
                                          );
                                },
                              );
                        }),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
