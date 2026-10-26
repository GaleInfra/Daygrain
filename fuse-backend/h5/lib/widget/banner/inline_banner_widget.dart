import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../custom/swiper_pagination/my_swiper_pagination.dart';
import '../../model/skip_model.dart';
import '../../res/my_color.dart';
import '../../utils/launch_util.dart';
import '../image/my_extended_network_image.dart';

/// create: 2024/12/XX
/// desc: 内联Banner组件（用于主播墙中插入）
class InlineBannerWidget extends StatefulWidget {
  const InlineBannerWidget({
    Key? key,
    this.closeRecharge = false,
    this.horizontalPadding,
    this.swiperController,
    this.externalControl = false,
    this.borderRadius,
  }) : super(key: key);

  /// 关闭充值弹窗
  final bool closeRecharge;

  final BorderRadius? borderRadius;

  final double? horizontalPadding;
  final SwiperController? swiperController;
  //是否外部控制
  final bool externalControl;

  @override
  State<InlineBannerWidget> createState() => _InlineBannerWidgetState();
}

class _InlineBannerWidgetState extends State<InlineBannerWidget> with AutomaticKeepAliveClientMixin, RouteAware {
  final _appConfig = Get.find<AppConfigManager>();

  final GlobalKey globalKey = GlobalKey();

  late SwiperController _swiperController;

  bool isCanRoute = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context) is PageRoute) {
      isCanRoute = false;
      routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
    } else {
      isCanRoute = true;
      routeObserver.unsubscribe(this);
    }
  }

  @override
  void didPushNext() {
    if (many) _swiperController.stopAutoplay();
    super.didPushNext();
  }

  @override
  void didPopNext() {
    if (many) _swiperController.startAutoplay();

    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();
    _swiperController = widget.swiperController ?? SwiperController();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  bool many = false;

  /// 从接口获取 customList 的 content 数据
  List<CustomListItem> get customListContent {
    final customList = _appConfig.strategyModel?.customList;
    return customList?.content ?? [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<AppConfigManager>(builder: (appConfig) {
      Widget banner = const SizedBox(width: 0, height: 0);
      // 非审核模式 && customList content 不为空
      final contentList = customListContent;
      if (!appConfig.isReviewPkg.value && contentList.isNotEmpty) {
        // 是否超过1条banner数据
        many = contentList.length > 1;
        if (!widget.externalControl) {
          if (many) {
            _swiperController.startAutoplay();
          } else {
            _swiperController.stopAutoplay();
          }
        }

        banner = Container(
          key: globalKey,
          width: double.infinity,
          height: 50.w,
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding ?? 3.w),
          child: VisibilityDetector(
            key: const ValueKey("InlineBanner_widget"),
            onVisibilityChanged: (info) {
              if (!widget.externalControl) {
                if (info.visibleFraction < 0.2) {
                  if (many) _swiperController.stopAutoplay();
                } else {
                  if (many) _swiperController.startAutoplay();
                }
              }
            },
            child: many
                ? Swiper(
                    loop: false, // 不循环播放，只播放一次
                    autoplayDelay: 5000,
                    controller: _swiperController,
                    itemCount: contentList.length,
                    physics: const NeverScrollableScrollPhysics(), // 禁止用户手动滑动，只允许自动播放
                    itemBuilder: (ctx, index) {
                      CustomListItem item = contentList[index];
                      return GestureDetector(
                        onTap: () => throttleUtil.throttle(() async => _onTapJump(item), key: "InlineBanner", time: 500),
                        child: MyExtendedNetworkImage(
                          url: item.image ?? "",
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.fitWidth,
                          shape: BoxShape.rectangle,
                          borderRadius: widget.borderRadius ?? BorderRadius.circular(5.w),
                        ),
                      );
                    },
                    pagination: SwiperPagination(
                      builder: MySwiperPagination(
                        activeColor: MyColor.grey1D2237,
                        color: MyColor.grey1D2237.withOpacity(.36),
                        activeWidth: 4.w,
                        width: 2.w,
                        height: 2.w,
                      ),
                    ),
                    onIndexChanged: (index) {
                      // 当播放到最后一个时，停止自动播放
                      if (index == contentList.length - 1) {
                        _swiperController.stopAutoplay();
                      }
                    },
                  )
                : GestureDetector(
                    // 只有一张图时，不使用 Swiper，直接显示图片，避免滑动事件
                    onTap: () => throttleUtil.throttle(() async => _onTapJump(contentList[0]), key: "InlineBanner", time: 500),
                    child: MyExtendedNetworkImage(
                      url: contentList[0].image ?? "",
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.fitWidth,
                      shape: BoxShape.rectangle,
                      borderRadius: widget.borderRadius ?? BorderRadius.circular(5.w),
                    ),
                  ),
          ),
        );
      } else {
        many = false;
        _swiperController.stopAutoplay();
      }
      return banner;
    });
  }

  /// 点击跳转
  void _onTapJump(CustomListItem item) async {
    if (widget.closeRecharge) {
      // RechargeDialog.dismiss();
    }
    logger.d("=====InlineBanner点击=====\n${prettyJson(item.toJson())}");
    if (item.url != null && item.url!.isNotEmpty) {
      // 直接使用 url 跳转到外部浏览器
      logger.d("InlineBanner跳外部浏览器===>${item.url}");
      LaunchUtil.launchJump(url: item.url!);
      getReqRepo()?.log(
        event: "click",
        page: "home_custom_jumb",
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
}

