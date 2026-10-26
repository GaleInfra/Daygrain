import 'dart:math';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/business/say_hi/models/say_hi_recommend_broadcaster_model.dart';
import 'package:untitled1/business/say_hi/robot_script_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/widget/detail_gift.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/widget/detail_info.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/widget/detail_video.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/utils/broadcaster_call_price_util.dart';
import 'package:untitled1/widget/button/call_button.dart';
import 'package:untitled1/widget/dialog/block_report_sheet.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../custom/swiper_pagination/my_swiper_pagination.dart';
import '../../../model/skip_model.dart';
import 'logic.dart';

/// 主播资料页
class BroadcasterDetailPage extends StatefulWidget {
  const BroadcasterDetailPage({Key? key}) : super(key: key);

  static Future<dynamic>? to(UserInfoModel userInfo) {
    if (Get.isRegistered<BroadcasterDetailLogic>(tag: userInfo.userId)) {
      // 已存在控制器，直接返回
      Get.back();
      return null;
    } else {
      // 不存在推送新页面
      return Get.toNamed(RoutePath.broadcasterDetailPage,
          arguments: {
            "userInfo": userInfo,
          },
          preventDuplicates: false);
    }
  }

  @override
  State<BroadcasterDetailPage> createState() => _BroadcasterDetailPageState();
}

class _BroadcasterDetailPageState extends State<BroadcasterDetailPage> {
  late final BroadcasterDetailLogic logic;

  final ScrollController scrollController = ScrollController();

  String tagUserId = "";

  UserInfoModel model = UserInfoModel();
  //图片比例
  double imageRatio = 4.0/3.0;

  @override
  void initState() {
    if (Get.arguments != null) {
      Map map = Get.arguments;
      if (map.containsKey("userInfo")) {
        model = map['userInfo'];
        tagUserId = model.userId != null ? (model.userId! + DateTime.now().millisecondsSinceEpoch.toString()) : "";
        logic = Get.put(BroadcasterDetailLogic(), tag: tagUserId, permanent: false)..initData(model);
        if (logic.userInfo?.mediaList?.isEmpty ?? true) {
          //防止主播墙传入的头像 然后本地再读取缓存后会导致图闪烁， 就是 头像图片快速 -->却换成了加载页面或者是主播的其他图片
          logic.userInfo?.avatarUrl = "";
        }
      }
    }
    super.initState();
  }

  final GlobalKey<__SwiperState> _swiperKey = GlobalKey<__SwiperState>();
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // 拦截返回，将部分操作回馈上一页
          // logic.onBack();
        }
      },
      child: Scaffold(
        appBar: DefaultAppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: MyColor.white),
            onPressed: () => logic.onBack(),
          ),
          
          action: [
            IconButton(
              onPressed: () => BlockReportSheet.show(
                bindWidget: context,
                toUserId: logic.userInfo?.userId ?? "",
                isFollow: logic.userInfo?.isFriend ?? false,
                isBlock: logic.userInfo?.isBlock ?? false,
                onFollowOrUnBack: (result) => logic.onFollowOrUnBack(result),
                onBlockOrUnBack: (result) => logic.onBlockOrUnBack(result),
              ),
              icon: const Icon(Icons.more_horiz, color: MyColor.white),
            ),
          ],
        ),
        backgroundColor: MyColor.appBackground,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // 轮播图部分
                  Container(
                    height: Get.width * imageRatio,
                    alignment: Alignment.topCenter,
                    child: _Swiper(key: _swiperKey, tagUserId: tagUserId),
                  ),
                  // 详情内容部分
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8.w),
                    decoration: const BoxDecoration(
                      color: MyColor.appBackground,
                    ),
                    child: Column(
                      children: [
                        DetailInfo(tagUserId: tagUserId),
                        DetailVideo(tagUserId: tagUserId),
                        _Impression(tagUserId: tagUserId),
                        DetailGift(tagUserId: tagUserId),
                        SizedBox(
                          height: 62.5.w,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 底部保持不变
            Container(
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 18.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GetBuilder<BroadcasterDetailLogic>(
                    tag: tagUserId,
                    builder: (logic) {
                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (RobotScriptManager.isCanSendSayHiInfo(logic.userInfo?.userId ?? "")) {
                                if (logic.userInfo == null) {
                                  return;
                                }
                                Get.find<RobotScriptManager>().onSayHiPressed([SayHiRecommendBroadcasterModel.fromUserInfoModel(logic.userInfo!)]);
                              } else {
                                MessageChatPage.to(logic.userInfo ?? UserInfoModel(userId: logic.userId));
                              }
                            },
                            child: RobotScriptManager.isCanSendSayHiInfo(logic.userInfo?.userId ?? "")
                                ? Container(
                                    height: 23.w,
                                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF504B6C),
                                      borderRadius: BorderRadius.circular(14.5.w),
                                    ),
                                    child: Row(
                                      children: [
                                        Transform.rotate(
                                          angle: 15 * pi / 180,
                                          child: Image.asset(
                                            ImageAssets.sayHi,
                                            fit: BoxFit.contain,
                                            width: 10.w,
                                            height: 10.w,
                                          ),
                                        ),
                                        MyGaps.hGaps3w,
                                        Text(
                                          "Say Hi".bhTR,
                                          style: TextStyle(color: MyColor.white, fontSize: 7.sp, fontWeight: FontWeight.w400),
                                        )
                                      ],
                                    ),
                                  )
                                : Container(
                                    height: 23.w,
                                    width: 23.w,
                                    color: Colors.transparent,
                                    child: Center(
                                      child: Image.asset(
                                        ImageAssets.broadcasterMsg,
                                        fit: BoxFit.cover,
                                        width: 15.w,
                                        height: 13.w,
                                      ),
                                    ),
                                  ),
                          ),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: GetBuilder<BroadcasterDetailLogic>(
                                tag: tagUserId,
                                builder: (logic) {
                                  return Obx(() {
                                    return CallButton(
                                      status: logic.onlineStatus.value,
                                      price: BroadcasterCallPriceUtil.displayPerMinutePriceText(
                                        broadcaster: logic.userInfo,
                                      ),
                                      onTap: () {
                                        logic.onVideoCall();
                                      },
                                    );
                                  });
                                }),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (tagUserId.isNotEmpty) {
      Get.delete<BroadcasterDetailLogic>(tag: tagUserId);
    }
  }
}

/// 轮播图
class _Swiper extends StatefulWidget {
  const _Swiper({
    Key? key,
    required this.tagUserId,
  }) : super(key: key);

  final String tagUserId;

  @override
  State<_Swiper> createState() => __SwiperState();
}

class __SwiperState extends State<_Swiper> with RouteAware {
  late SwiperController _swiperController;
  //是否开启还是关闭
  bool isTurnOn = true;

  void setIsTurnOn(bool value) {
    isTurnOn = value;
    if (isAutoPlay) {
      if (value) {
        _swiperController.startAutoplay();
      } else {
        _swiperController.stopAutoplay();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _swiperController = SwiperController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  void didPopNext() {
    // TODO: implement didPopNext
    super.didPopNext();
    if (isAutoPlay) _swiperController.startAutoplay();
  }

  @override
  void didPushNext() {
    // TODO: implement didPushNext
    super.didPushNext();
    if (isAutoPlay) _swiperController.stopAutoplay();
  }

  bool isAutoPlay = false;
  @override
  Widget build(BuildContext context) {
    return GetBuilder<BroadcasterDetailLogic>(
      tag: widget.tagUserId,
      builder: (logic) {
        var list = logic.userInfo?.mediaList?.where((element) => element.mediaType == "photo" && element.mediaUrl != null && element.mediaUrl!.isNotEmpty).toList();
        if (list?.isEmpty ?? true) {
          list = <MediaList>[];
          list.add(MediaList(mediaUrl: logic.userInfo?.avatarUrl ?? ""));
        }
        isAutoPlay = (list?.length ?? 0) > 1;
        isAutoPlay ? _swiperController.startAutoplay() : _swiperController.stopAutoplay();
        _swiperController.index = logic.imageIndex;
        return VisibilityDetector(
          key: ValueKey("broadcaster_swiper_${widget.tagUserId}"),
          onVisibilityChanged: (info) {
            if (info.visibleFraction == 0) {
              if (isAutoPlay) _swiperController.stopAutoplay();
            } else {
              if (isAutoPlay) _swiperController.startAutoplay();
            }
          },
          child: Stack(
            children: [
              ClipRRect(
                // 添加这个组件
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6.w),
                  bottomRight: Radius.circular(6.w),
                ),
                child: Swiper(
                  itemBuilder: (ctx, index) => MyExtendedNetworkImage(
                    url: list?[index].mediaUrl ?? "",
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    isBroadcaster: true,
                    isAnimation: false,
                  ),
                  controller: _swiperController,
                  index: logic.imageIndex,
                  loop: isAutoPlay,
                  itemCount: list?.length ?? 0,
                  autoplayDelay: 5000,
                  onTap: (index) {
                    if (logic.userInfo == null) {
                      return;
                    }
                    final urls = list?.where((e) => e.mediaUrl != null && e.mediaUrl!.isNotEmpty).map((e) => e.mediaUrl!).toList() ?? [];
                    if (urls.isEmpty) {
                      return;
                    }

                    Get.toNamed(RoutePath.seeImagePage, arguments: {"index": index, "urls": urls, "userInfo": logic.userInfo});
                  },
                  onIndexChanged: (index) {
                    logic.imageIndex = index;
                  },
                  pagination: isAutoPlay
                      ? SwiperPagination(
                          margin: EdgeInsets.only(bottom: 5.w),
                          builder: MySwiperPagination(
                            activeColor: MyColor.btnGradientColors.first,
                            color: MyColor.white,
                            activeWidth: 6.w,
                            width: 3.w,
                            height: 3.w,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                  left: BHLanguageMar().isRightToLeft.value ? 7.5.w : null,
                  right: BHLanguageMar().isRightToLeft.value ? null : 7.5.w,
                  bottom: 13.5.w,
                  child: GestureDetector(
                    onTap: () => logic.onFollowOrUnFollow(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .34), // 背景颜色
                        shape: BoxShape.circle, // 圆形
                      ),
                      width: 19.5.w,
                      height: 19.5.w,
                      child: Align(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 0, top: 2),
                          child: Image.asset(
                            (logic.userInfo?.isFriend ?? false) ? ImageAssets.broadcasterLikes : ImageAssets.broadcasterUnLikes,
                            width: 14.5.w,
                            height: 12.w, // 适应圆形容器的高度// 填充容器
                          ),
                        ),
                      ),
                    ),
                  ))
            ],
          ),
        );
      },
    );
  }
}

/// 标题
class DetailTitle extends StatelessWidget {
  const DetailTitle({
    Key? key,
    required this.icon,
    required this.title,
  }) : super(key: key);

  final String icon;

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 7.5.w),
      child: Row(
        children: [
          // SizedBox(
          //   width: 15.5.w,
          //   height: 13.w,
          //   child: Center(
          //     child: Image.asset(
          //       icon,
          //       width: 15.5.w,
          //       height: 13.w,
          //       fit: BoxFit.contain,
          //     ),
          //   ),
          // ),
          // MyGaps.hGaps3w,
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: MyColor.white,
              fontSize: 8.sp,
            ),
          )
        ],
      ),
    );
  }
}

/// 标签内容
class _Impression extends StatelessWidget {
  const _Impression({
    Key? key,
    required this.tagUserId,
  }) : super(key: key);

  final String tagUserId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Visibility(
        visible: !Get.find<AppConfigManager>().isReviewPkg.value,
        child: GetBuilder<BroadcasterDetailLogic>(
          tag: tagUserId,
          builder: (logic) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyGaps.vGaps10w,
                if ((logic.extraInfoModel?.labelsList ?? []).isNotEmpty) DetailTitle(icon: ImageAssets.broadcasterInfoLabelLabel, title: "label_impression".bhTR),
                Padding(
                  padding: EdgeInsets.only(right: 7.5.w, left: 7.5.w, top: 5.w),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    alignment: WrapAlignment.start,
                    spacing: 5.w,
                    runSpacing: 5.w,
                    children: (logic.extraInfoModel?.labelsList ?? []).map((e) {
                      // 拆分标签和数字
                      final parts = e.split(':');
                      if (parts.length == 2) {
                        final label = parts[0].bhTR; // 添加.bhTR后缀
                        final number = parts[1];
                        return Container(
                          key: ValueKey(e),
                          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.w),
                          decoration: BoxDecoration(
                            color:const Color(0xFF26203A),
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          child: Text(
                            '$label:$number', // 重新拼接
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 6.sp,
                            ),
                          ),
                        );
                      }
                      // 如果格式不符合,返回原始文本
                      return Container(
                        key: ValueKey(e),
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.w),
                        decoration: BoxDecoration(
                          color: MyColor.gray45,
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        child: Text(
                          e.bhTR,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 6.sp,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}
