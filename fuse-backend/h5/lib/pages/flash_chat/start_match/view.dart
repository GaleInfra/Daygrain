import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/flash_chat/match_connect/widget/gradient_progress_view.dart';
import 'package:untitled1/pages/flash_chat/start_match/widget/loop_avatar_widget.dart';
import 'package:untitled1/pages/flash_chat/start_match/widget/water_ripples.dart';
import 'package:untitled1/utils/assets_handle.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/widget/carousel_widget.dart';

import '../../../res/image_assets.dart';
import '../../../res/my_color.dart';
import '../../../res/my_gaps.dart';
import '../../../widget/app_bar/default_app_bar.dart';
import '../../../widget/image/my_extended_network_image.dart';
import 'logic.dart';

/// 开始匹配页
class StartMatchPage extends StatefulWidget {
  const StartMatchPage({super.key});

  @override
  State<StartMatchPage> createState() => _StartMatchPageState();
}

class _StartMatchPageState extends State<StartMatchPage>
    with TickerProviderStateMixin {
  final logic = Get.find<StartMatchLogic>();


  @override
  void initState() {
    super.initState();


  }

  @override
  void dispose() {
    super.dispose();
  }



  // 构建匹配文本和状态
  Widget _buildMatchingStatus() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            child: Obx(() {
              return Center(
                child: Text(
                  logic.content.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MyColor.white,
                    fontSize: 7.sp,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 7.5.w),
          // 女神匹配时显示Goddess文案
          if (logic.isGoddessMatch)
            Text(
              "label_goddess".bhTR,
              textAlign: TextAlign.center,
              style: FontUtils.boldItalic(
                color: Colors.pinkAccent.shade200,
                size: 16.sp,
              ),
            ),
          Text(
            "${"action_matching".bhTR.fixAutoLines()}...",
            style: FontUtils.boldItalic(
                color: logic.isGoddessMatch
                    ? Colors.pinkAccent.shade200
                    : MyColor.highlightColor,
                size: 16.sp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isHaveBack = false;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 3 && details.localPosition.dx < 50) {
          if (!logic.matchSuccess.value) {
            if (!isHaveBack) {
              isHaveBack = true;
              logic.onBack();
            }
          }
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          if (!isHaveBack &&  !logic.matchSuccess.value) {
            isHaveBack = true;
            return true;
          }else {
            return false;
          }

        },
        child: PopScope(
          canPop: !logic.matchSuccess.value,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              if (!isHaveBack) {
                isHaveBack = true;
                logic.onBack();
              }
            }
          },
          child: Container(
            decoration:const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.7, 1],
            colors: MyColor.matchBgColors,
          ),
        ),
            child: SafeArea(
              child: Stack(
                children: [
                  Obx(
                    () {
                      var height = Get.width * 0.7 * 4 / 3.0;
                      return Visibility(
                        visible: logic.matchSuccess.value,
                        replacement: Stack(
                          children: [
                            Align(child:Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CarouselWidget(
                                  items: [
                                  AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon0),
                                  AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon1),
                                  AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon2),
                                  AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon3),
                                  AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon4),
                                  ],
                                  height: height + 8.w,
                                  autoPlayInterval: const Duration(seconds: 1),
                                  animationDuration: const Duration(milliseconds: 300),
                                  itemBuilder: (item, index) {
                                  final String imageUrl = item as String;
                                  return MyExtendedNetworkImage(
                                    url: imageUrl,
                                    // width: Get.width * 0.7,
                                    borderRadius: BorderRadius.circular(12.w),
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                                SizedBox(height: 7.5.w,),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 9.w),
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      Container(
                                        child: Obx(() {
                                          return Center(
                                            child: Text(
                                              logic.content.value,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: MyColor.white,
                                                fontSize: 7.sp,
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      SizedBox(height: 7.5.w,),
                                      Text(
                                        "Matching...".bhTR.fixAutoLines(),
                                        style: FontUtils.boldItalic(
                                            color: MyColor.highlightColor, size: 16.sp),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),),
                            DefaultAppBar(onBack: logic.onBack),
            
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15.w),
                              child: Container(
                                width: Get.width - 17.w * 2,
                                height: (Get.width - 17.w * 2) * 395 / 308,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.w),
                                  color: MyColor.white.withOpacity(0.2),
                                ),
                                child: Stack(
                                  children: [
                                    MyExtendedNetworkImage(
                                      url: logic.userInfo?.avatarMiddleThumbUrl ?? "",
                                      width: Get.width - 17.w * 2,
                                      height: (Get.width - 17.w * 2) * 395 / 308,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                        left: BHLanguageMar().isRightToLeft.value
                                            ? null
                                            : 6.w,
                                        right: BHLanguageMar().isRightToLeft.value
                                            ? 6.w
                                            : null,
                                        bottom: 10.w,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              (logic.userInfo?.nickname ?? "").fixAutoLines(),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: MyColor.white,
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            MyGaps.vGaps2w,
                                            Text(
                                              "${logic.userInfo?.age ?? 0},${logic.userInfo?.country ?? ''}",
                                              style: TextStyle(
                                                color: MyColor.white,
                                                fontSize: 7.sp,
                                              ),
                                            )
                                          ],
                                        ))
                                  ],
                                ),
                              ),
                            ),
                            MyGaps.vGaps10w,
                            Column(
                              children: [
                                Text(
                                  "status_connecting".bhTR,
                                  style: TextStyle(
                                      color: MyColor.white,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(
                                  height: 2.w,
                                ),
                                GradientProgressView(
                                    progressColors: MyColor.btnGradientColors,
                                    progressCornerRadius: 9,
                                    backgroundColor: Colors.white,
                                    isRightToLeft: BHLanguageMar()
                                        .isRightToLeft
                                        .value // 0.0 到 1.0 之间的值
                                ),
                                SizedBox(
                                  height: 20.w,
                                ),
                                // Text(
                                //   "WE’RE\nA MATCH!".bhTR,
                                //   textAlign: TextAlign.center,
                                //   style: FontUtils.boldItalic(
                                //     color: MyColor.highlightColor,
                                //     size: 16.sp,
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
