import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/throttle_util.dart';
import 'package:untitled1/widget/dialog/strong_guide_sheet_v2.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:untitled1/net/request_repository.dart';

import '../../common_logic/banner_strong_guide_logic.dart';
import '../../custom/swiper_pagination/my_swiper_pagination.dart';
import '../../model/banner_strong_guide/banner_info_model.dart';
import '../../res/my_color.dart';
import '../../utils/launch_util.dart';
import '../image/my_extended_network_image.dart';

/// create: 2023/7/3
/// desc: Banner
class BannerWidget extends StatefulWidget {
  const BannerWidget({
    Key? key,
    required this.showBanner,
    this.onlyStrongGuide = false,
    this.closeRecharge = false,
    this.horizontalPadding,
    this.swiperController,
    this.externalControl = false,
    this.borderRadius,
  }) : super(key: key);

  /// 是否显示banner，提供给外部的显隐字段
  final bool showBanner;

  /// 仅显示导量banner
  final bool onlyStrongGuide;

  /// 关闭充值弹窗
  final bool closeRecharge;

  final BorderRadius? borderRadius;

  final double? horizontalPadding;
  final SwiperController? swiperController;
  //是否外部控制
  final bool externalControl;

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> with AutomaticKeepAliveClientMixin, RouteAware {
  final _bannerLogic = Get.find<BannerStrongGuideLogic>();

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
  bool _hasLoggedStrongGuideEntry = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<BannerStrongGuideLogic>(builder: (logic) {
      Widget banner = const SizedBox(width: 0, height: 0);
      // 外部条件 && 非审核模式 && banner列表不为空
      if (widget.showBanner && !_appConfig.isReviewPkg.value && _bannerLogic.bannerList.isNotEmpty) {
        final List<BannerInfoModel> list = [];
        list.addAll(_bannerLogic.bannerList);

        // 只要存在可点击弹出大哥包红色弹窗的入口（type == 3），即上报一次入口展示
        if (!_hasLoggedStrongGuideEntry && list.any((e) => e.type == 3)) {
          _hasLoggedStrongGuideEntry = true;
          getReqRepo()?.log(
            event: "show",
            page: "strong_guide_banner_entry",
          );
        }

        // 是否超过2条banner数据
        many = list.length > 1;
        if (!widget.externalControl) {
          if (many) {
            _swiperController.startAutoplay();
          } else {
            _swiperController.stopAutoplay();
          }
        }

        if (list.isNotEmpty) {
          banner = Container(
            key: globalKey,
            width: double.infinity,
            height: 50.w,
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding ?? 8.w),
            child: VisibilityDetector(
              key: const ValueKey("Banner_widget"),
              onVisibilityChanged: (info) {
                if (!widget.externalControl) {
                  if (info.visibleFraction < 0.2) {
                    if (many) _swiperController.stopAutoplay();
                  } else {
                    if (many) _swiperController.startAutoplay();
                  }
                }
              },
              child: Swiper(
                loop: true,
                autoplayDelay: 5000,
                controller: _swiperController,
                itemCount: list.length,
                itemBuilder: (ctx, index) {
                  BannerInfoModel item = list[index];
                  return GestureDetector(
                    onTap: () => throttleUtil.throttle(() async => _onTapJump(item), key: "Banner", time: 500),
                    child: MyExtendedNetworkImage(
                      url: item.pic ?? "",
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.fitWidth,
                      shape: BoxShape.rectangle,
                      borderRadius:widget.borderRadius ?? BorderRadius.circular(5.w),
                    ),
                  );
                },
                pagination: many
                    ? SwiperPagination(
                        builder: MySwiperPagination(
                          activeColor: MyColor.grey1D2237,
                          color: MyColor.grey1D2237.withOpacity(.36),
                          activeWidth: 4.w,
                            width: 2.w,
                            height: 2.w,
                        ),
                      )
                    : null,
              ),
            ),
          );
        }
      } else {
        many = false;
        _swiperController.stopAutoplay();
      }
      return banner;
    });
  }

  /// 点击跳转
  void _onTapJump(BannerInfoModel item) async {
    if (widget.closeRecharge) {
      // RechargeDialog.dismiss();
    }
    logger.d("=====Banner点击=====\n${prettyJson(item.toJson())}");
    if (item.type == 1) {
      // 应用内webView
      if (item.bizType == "5" || item.bizType == "12") {
        WebViewPage.onJump(url: item.jumpUrl!, itemType: 5);
      } else {
        WebViewPage.onJump(url: item.jumpUrl!);
      }
    } else if (item.type == 3) {
      // 强化导量
      StrongGuideSheetV2.show(Get.context);
      getReqRepo()?.log(
        event: "click",
        page: "strong_guide_banner_entry",
      );
    } else if (item.type == 4) {
      // 跳外部浏览器
      logger.d("Banner跳外部浏览器===>${item.jumpUrl}");
      LaunchUtil.launchJump(url: item.jumpUrl!);
    }
  }

  @override
  bool get wantKeepAlive => true;
}
