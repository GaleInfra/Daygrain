
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/assets_handle.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/widget/carousel_widget.dart';
import 'package:untitled1/widget/dialog/recharge_dialog.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../res/pay_entry.dart';
import 'logic.dart';

/// 匹配tab
class FlashChatPage extends StatefulWidget {
  const FlashChatPage({super.key});

  @override
  State<FlashChatPage> createState() => _FlashChatPageState();
}

class _FlashChatPageState extends State<FlashChatPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final logic = Get.find<FlashChatLogic>();
  final appConfig = Get.find<AppConfigManager>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 顶部金币
    Widget coinWidget = Positioned(
      top: BHPlatform.isWeb ? (DeviceUtil().statusBarHeight ?? 0) : 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 24.w,
                  child: Stack(
                    children: [
                      Padding(
                          padding: EdgeInsets.only(left: 2.w),
                          child: Image.asset(
                            ImageAssets.matchTabTop,
                            width: 15.w,
                            height: 15.w,
                            fit: BoxFit.contain,
                          )),
                      Padding(
                          padding: EdgeInsets.only(left: 2.w),
                          child: Image.asset(
                            ImageAssets.matchTabTop,
                            width: 15.w,
                            height: 15.w,
                            fit: BoxFit.contain,
                          )),
                      Container(
                        alignment: Alignment.bottomCenter,
                        padding: EdgeInsets.only(bottom: 4.w),
                        child: Text(
                          "action_match".bhTR,
                          style: FontUtils.boldItalic(size: 10.w, color: MyColor.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: BHLanguageMar().isRightToLeft.value
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // VIP 标识：无 VIP 商品且未开通时隐藏
                        GetBuilder<AppConfigManager>(
                          builder: (_) => GetBuilder<CoinGoodsLogic>(
                            builder: (coins) => Obx(() {
                              coins.hasVipProducts.value;
                              if (!VipPrivilegesSheet.shouldShowVipEntry()) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: GestureDetector(
                                  onTap: () => VipPrivilegesSheet.show(),
                                  child: Image.asset(
                                    (Get.find<AppConfigManager>().userInfo.hasEquity ?? false)
                                        ? ImageAssets.hasopen
                                        : ImageAssets.unopen,
                                    width: 12.w,
                                    height: 12.w,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => RechargeDialog.show(
                              entry: PayEntry.SOURCE_11, bindWidget: context),
                          child: Container(
                            decoration: BoxDecoration(
                              color:const Color(0xFF828282).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14.w/2.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding:  EdgeInsets.all(2.0.w),
                                  child: Image.asset(
                                    ImageAssets.broadcasterDiamondBig,
                                    width: 12.w,
                                    height: 10.w,
                                  ),
                                ),
                                MyGaps.hGaps3w,
                                Flexible(
                                  child: GetBuilder<AppConfigManager>(
                                    builder: (logic) {
                                      return Text(
                                        "${logic.userInfo.availableCoins ?? 0}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: MyColor.white,
                                          fontSize: 8.sp,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                MyGaps.hGaps3w,
                                Image.asset(
                                  ImageAssets.addCoins,
                                  width: 14.w,
                                  height: 14.w,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            MyGaps.vGaps20w,
          ],
        ),
      ),
    );
    // 中间的匹配按钮

    var height = Get.width * 0.7 * 4 / 3.0;
    var paddingBottom = 0.0;
    // if (Get.height < 669) {
    //   height = 342.0;
    //   paddingBottom = 50;
    // }

    Widget centerMatch = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            CarouselWidget(
              items:  [
                AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon0),
                AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon1),
                AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon2),
                AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon3),
                AssetsHandle.instance.getPassiveAssetsDomain(ImageAssets.matchIcon4),
                ],
              height: height + 8.w,
              autoPlayInterval: const Duration(seconds: 3),
              animationDuration: const Duration(milliseconds: 1000),
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
          SizedBox(
            height: paddingBottom,
          ),
        ],
      ),
    );
    // 底部的匹配按钮
    Widget button = Positioned(
      //判断是否 iphone 8 / mini / SE 屏幕尺寸手机 
      bottom: Get.height < 669 ? 5.w : 26.w,
      right: 0,
      left: 0,
      child: Center(
        child: buildMenuWidget(),
      ),
    );

    return VisibilityDetector(
      key: const Key("BroadcasterPage"),
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;
        logic.onChangeVisiblePercentage(visiblePercentage);
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.7, 1],
            colors: MyColor.matchBgColors,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                centerMatch,
                coinWidget,
                button,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 匹配底部菜单
  /// 
  Widget buildMenuWidget() {
    return GetBuilder<AppConfigManager>(
        builder: (appConfig) {
          // 是否免费匹配
          bool isFreeCall =
              (appConfig.strategyModel?.flashChatConfig?.isFreeCall ??
                      false) &&
                  (appConfig.strategyModel?.flashChatConfig
                              ?.residueFreeCallTimes ??
                          0) >
                      0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 卡片式匹配按钮
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 普通匹配按钮
                    GestureDetector(
                      onTap: () => logic.onJumpMatch(logic.matchIndex),
                      child: Container(
                        width: 83.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 普通匹配背景图
                            Positioned.fill(
                              child: Padding(
                                padding:  EdgeInsets.only(top: 3.w ,left:  BHLanguageMar().isRightToLeft.value ? 3.w : 0,right: BHLanguageMar().isRightToLeft.value ?  0 : 3.w),
                                child: Transform.scale(
                                  scaleX: BHLanguageMar().isRightToLeft.value ? -1 : 1,
                                  child: Image.asset(
                                    ImageAssets.flashBgRandom,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only( top: 13.w,left: 6.w,right: 6.w), // 减小内边距
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "label_random".bhTR,
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                      color:const Color(0xFF5D75FF),
                                    ),
                                  ),
                                  SizedBox(height: 1.w),
                                  Row(
                                    children: [
                                      Image.asset(
                                        ImageAssets.coinsStore1,
                                        width: 6.w,
                                        height: 6.w,
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        isFreeCall
                                            ? "label_free".bhTR
                                            : "${appConfig.strategyModel?.genderMatchCoin?.femaleCoins ?? 9}/${"label_match".bhTR}",
                                        style: TextStyle(
                                          fontSize: 6.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3.w),
                                  Transform.scale(scaleX: BHLanguageMar().isRightToLeft.value ? -1 : 1, child: Image.asset(ImageAssets.flashBtnRandom,width: 20.w,height: 12.w,))
                                ],
                              ),
                            ),
                            // if (isFreeCall && !(appConfig.userInfo.hasEquity ?? false))
                            //   Positioned(
                            //     top: 4.w,
                            //     right: 4.w,
                            //     child: Container(
                            //       padding: EdgeInsets.symmetric(
                            //         horizontal: 3.w,
                            //         vertical: 1.w,
                            //       ),
                            //       decoration: BoxDecoration(
                            //         color: Colors.green,
                            //         borderRadius: BorderRadius.circular(4.w),
                            //       ),
                            //       child: Text(
                            //         "label_free".bhTR,
                            //         style: TextStyle(
                            //           color: Colors.white,
                            //           fontSize: 4.sp,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                            //     ),
                            //   ),
                            if(!(appConfig.userInfo.hasEquity ?? false) && !isFreeCall)
                              //右上角的皇冠
                              Positioned(
                                top: 0,
                                right:  BHLanguageMar().isRightToLeft.value ? null:0,
                                left:  BHLanguageMar().isRightToLeft.value ? 0:null,
                                child: Transform.scale(scaleX: BHLanguageMar().isRightToLeft.value ? -1:1,
                                  child: Image.asset(
                                    ImageAssets.flashIcVipKing,
                                    width: 15.w,
                                    height: 15.w,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    // 女神匹配按钮
                    GestureDetector(
                      onTap: () => logic.onJumpMatch(logic.matchIndex,
                          isGoddessMatch: true),
                      child: Container(
                        width: 83.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 普通匹配背景图
                            Positioned.fill(
                              child: Padding(
                                padding:  EdgeInsets.only(top: 3.w ,left:  BHLanguageMar().isRightToLeft.value ? 3.w : 0,right: BHLanguageMar().isRightToLeft.value ?  0 : 3.w),
                                child: Transform.scale(
                                  scaleX: BHLanguageMar().isRightToLeft.value ? -1 : 1,
                                  child: Image.asset(
                                    ImageAssets.flashBgGoddess,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only( top: 13.w,left: 6.w,right: 6.w), // 减小内边距
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "label_goddess".bhTR,
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                      color:const Color(0xFFFF23CF),
                                    ),
                                  ),
                                  SizedBox(height: 1.w),
                                  Row(
                                    children: [
                                      Image.asset(
                                        ImageAssets.coinsStore1,
                                        width: 6.w,
                                        height: 6.w,
                                      ),
                                      SizedBox(width: 2.w),
                                      Text(
                                        "${appConfig.strategyModel?.genderMatchCoin?.goddessMatchCoins(hasEquity: appConfig.userInfo.hasEquity ?? false) ?? 0}/${"label_match".bhTR}",
                                        style: TextStyle(
                                          fontSize: 6.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3.w),
                                  Transform.scale(scaleX: BHLanguageMar().isRightToLeft.value ? -1:1,child:  Image.asset(ImageAssets.flashBtnGoddess,width: 20.w,height: 12.w,))
                                ],
                              ),
                            ),
                            
                            if(!(appConfig.userInfo.hasEquity ?? false))
                              //右上角的皇冠
                              Positioned(
                                top: 0,
                                right:  BHLanguageMar().isRightToLeft.value ? null:0,
                                left:  BHLanguageMar().isRightToLeft.value ? 0:null,
                                child: Transform.scale(scaleX: BHLanguageMar().isRightToLeft.value ? -1:1,
                                  child: Image.asset(
                                    ImageAssets.flashIcVipKing,
                                    width: 15.w,
                                    height: 15.w,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
  }

  @override
  bool get wantKeepAlive => true;
}
