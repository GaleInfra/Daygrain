import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:js' as js;

import '../../../../res/image_assets.dart';
import '../../../../res/my_color.dart';
import '../../../../utils/device_util.dart';
import '../logic.dart';

/// create: 2023/5/10
/// desc: 视频通话-本地端
class VideoLocalWidget extends StatefulWidget {
  const VideoLocalWidget({Key? key, this.isShowMatchTime = false}) : super(key: key);
  final bool isShowMatchTime;
  @override
  State<VideoLocalWidget> createState() => _VideoLocalWidgetState();
}

class _VideoLocalWidgetState extends State<VideoLocalWidget> {
  double dX = 0;
  double dY = 0;
  double width =  44.w;
  double height = 66.7.w;

  late html.IFrameElement _localFrame;

  @override
  void initState() {
    dX = BHLanguageMar().isRightToLeft.value ? 12.w : Get.width - width - 12.w;
    dY = 25.w + (DeviceUtil().statusBarHeight ?? 0) + (widget.isShowMatchTime ? 0 : 10.w);
     var screen = html.window.screen;
    var width2 = screen?.width ?? 0;
    var height2 = screen?.height ?? 0;
    _localFrame = html.IFrameElement()
      ..id = 'localVideoFrame'
      ..src = 'local_video.html' // 指向你的 HTML 文件
      ..style.border = 'none'
      ..width = '${width2}px' // 设置宽度
      ..height = '${height2}px' // 设置高度
      ..style.pointerEvents = 'none';

    ui.platformViewRegistry.registerViewFactory("v_localFrame", (int viewId) {
      return _localFrame;
    });
    super.initState();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    //移动中
    moveLocalVideo();
    dX += details.delta.dx;
    dY += details.delta.dy;
    if (dX < 0) {
      // 限制右边
      dX = 0;
    }
    if (dX > Get.width - width) {
      // 限制左边
      dX = Get.width - width;
    }
    if (dY < kToolbarHeight) {
      // 限制上面
      dY = kToolbarHeight;
    }
    if (dY > Get.height - height - 30.w) {
      // 限制下面
      dY = Get.height - height - 30.w;
    }
    setState(() {});

    //延迟执行，只执行最后一次
    Future.delayed(const Duration(milliseconds: 200), () {
      //结束移动
      endMoveLocalVideo();
    });
  }

  void moveLocalVideo() {
    if (kIsWeb) {
      js.context.callMethod("moveLocalVideo");
    }
  }

  void endMoveLocalVideo() {
    if (kIsWeb) {
      js.context.callMethod("endMoveLocalVideo");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VideoCallLogic>(
      builder: (logic) {
        return Obx(() => Positioned(
            left: dX,
            top: dY + (logic.showFlachMatchDown.value ? 19.w : 0),
            child: GestureDetector(
              onPanUpdate: _handlePanUpdate,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.w),
                child: Container(
                  width: width,
                  height: height,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      const Positioned.fill(
                        child: HtmlElementView(
                          viewType: 'v_localFrame',
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Visibility(
                                    visible: logic.appConfig.strategyModel?.isCallRearCamera ?? false,
                                    child: GestureDetector(
                                      onTap: () => logic.onSwitchCamera(),
                                      child: Container(
                                          color: MyColor.transparent,
                                          child: Stack(
                                            alignment: Alignment.bottomCenter,
                                            children: [
                                              Container(
                                                width: 9.w,
                                                height: 8.w,
                                                margin: EdgeInsets.only(bottom: 1.w),
                                                child: Align(
                                                  alignment: Alignment.bottomCenter,
                                                  child: Image.asset(
                                                    ImageAssets.videoCallPhoto,
                                                    width: 7.w,
                                                    height: 6.5.w,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: BHLanguageMar().isRightToLeft.value ? null : 0,
                                                left: BHLanguageMar().isRightToLeft.value ? 0 : null,
                                                child: Obx(() {
                                                  return Visibility(
                                                    visible: logic.showRearCameraRed.value,
                                                    child: Container(
                                                      width: 3.w,
                                                      height: 3.w,
                                                      decoration: const BoxDecoration(
                                                        color: MyColor.redFF5E5E,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ],
                                          )),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            )));
      },
    );
  }
}
