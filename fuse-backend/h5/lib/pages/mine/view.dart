import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/coin_goods_logic.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/date_time_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/utils/launch_util.dart';
import 'package:untitled1/widget/banner/banner_widget.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/dialog/privacy_mode_dialog.dart';
import 'package:untitled1/widget/vip/vip_privileges_sheet.dart';

// import 'package:untitled1/widget/dialog/invite_code_dialog.dart';
import 'package:untitled1/pages/mine/logic.dart';

/// 个人中心
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage>
    with AutomaticKeepAliveClientMixin {
  final logic = Get.put(MineLogic());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GradientBackgroundWidget(
      child: SingleChildScrollView(
        child: Column(
          children: [
            MyGaps.vGaps40w,
            _TopInfo(),
            MyGaps.vGaps5w,

            ///vip：无 VIP 商品且未开通时隐藏
            _vipInfo(),
            _coinInfo(),
            MyGaps.vGaps5w,
            const BannerWidget(showBanner: true, onlyStrongGuide: true),
            // MyGaps.vGaps5w,
            // Visibility(
            //   visible: Platform.isAndroid,
            //   child: GetBuilder<AppConfigManager>(
            //     builder: (appManager) {
            //       final vipLogic = Get.find<VipManager>();
            //       String text = "\$9.99/${"title_month".bhTR}";
            //       if (appManager.userInfo.isVip ?? false) {
            //         text =
            //             "${"term_validUntil".bhTR} ${DateTimeUtil.getDateTimeStr(dateTime: DateTime.fromMillisecondsSinceEpoch(int.parse(appManager.userInfo.vipExpiryTime ?? "0")))}";
            //       } else if (vipLogic.goodsList.isNotEmpty) {
            //         text =
            //             "\$${vipLogic.goodsList.first.price}/${vipLogic.goodsList.first.validityUnit}";
            //       }
            //       return _Item(
            //         imagePath: ImageAssets.mineIconVip,
            //         title: "VIP",
            //         trailingText: text,
            //         onTap: () => Get.toNamed(RoutePath.vipPage),
            //       );
            //     },
            //   ),
            // ),
            // if (Platform.isAndroid) MyGaps.hLine,
            _items(),

            // 添加VIP测试按钮
            // MyGaps.vGaps15w,
            // _buildTestButton(),
          ],
        ),
      ),
    );
  }

  List<Widget> _getList() {
    List<Widget> list = [];
    final appManager = Get.find<AppConfigManager>();
    if (!appManager.isReviewPkg.value) {
      list.add(_Item(
        imagePath: ImageAssets.myLevel,
        title: "title_myLevel".bhTR,
        trailingText: "Lv ${appManager.userInfo.level ?? 0}",
        onTap: () => Get.toNamed(RoutePath.myLevelPage),
      ));
      list.add(_Item(
        imagePath: ImageAssets.customServiceIcon,
        title: "more_service".bhTR,
        onTap: () => Get.toNamed(RoutePath.robotPage),
      ));
    }
    // if (logic.isShowInvite.value) {
    //   list.add(_Item(
    //     imagePath: ImageAssets.mineInviteCode,
    //     title: "title_lnvitation_code".bhTR,
    //     onTap: () {
    //       showInviteCodeDialog();
    //     },
    //   ));
    // }
    list.addAll([
      
      _Item(
        imagePath: ImageAssets.mineBlocked,
        title: "title_blockedList".bhTR,
        onTap: () => Get.toNamed(RoutePath.blockedPage),
      ),
      _Item(
        imagePath: ImageAssets.mineAbout,
        title: "title_about".bhTR,
        onTap: () => Get.toNamed(RoutePath.aboutPage),
      ),
      // _Item(
      //   imagePath: ImageAssets.report,
      //   title: "title_report".bhTR,
      //   onTap: () => Get.toNamed(RoutePath.reportPage),
      // ),
      _Item(
        imagePath: ImageAssets.mineSetting,
        title: "title_settings".bhTR,
        onTap: () => Get.toNamed(RoutePath.settingPage),
      ),
    ]);

    // 根据 customList.show 决定是否显示客服 tab
    final customList = appManager.strategyModel?.customList;
    if (customList?.show != null && customList!.show!.toLowerCase() == 'true') {
      // 获取 customList.content 中第一个 item 的 url
      final firstContentUrl = customList.content?.isNotEmpty == true 
          ? customList.content?.first.url 
          : null;
      
      if (firstContentUrl != null && firstContentUrl.isNotEmpty) {
        list.add(
          _Item(
            imagePath: ImageAssets.customerService,
            title: "more_service".bhTR,
            onTap: () {
              getReqRepo()?.log(
                event: "click",
                page: "mine_custom_jumb",
              );
              // 使用与 banner 相同的跳转方式
              LaunchUtil.launchJump(url: firstContentUrl);
            },
          ),
        );
      }
    }

    return list;
  }

  @override
  bool get wantKeepAlive => true;

  Widget _vipInfo() {
    return GetBuilder<AppConfigManager>(
      builder: (_) => GetBuilder<CoinGoodsLogic>(
        builder: (coins) => Obx(() {
          // 读 Rx，商品拉取后立刻刷新入口可见性
          coins.hasVipProducts.value;
          if (!VipPrivilegesSheet.shouldShowVipEntry()) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => VipPrivilegesSheet.show(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF252733),
                          Color(0xFF5A6070),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Container(
                      height: 23.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GetBuilder<AppConfigManager>(builder: (appManager) {
                                  return Image.asset(
                                    appManager.userInfo.hasEquity ?? false
                                        ? ImageAssets.hasopen
                                        : ImageAssets.unopen,
                                    width: 17.w,
                                    height: 17.w,
                                  );
                                }),
                                MyGaps.hGaps5w,
                                Text(
                                  "VIP",
                                  maxLines: 1,
                                  style: FontUtils.boldItalic(
                                    color: MyColor.white,
                                    size: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                            GetBuilder<AppConfigManager>(builder: (appManager) {
                              String displayText = "vip_unlock".bhTR;
                              const textColor = Color(0xFFFFDAB1);

                              if (appManager.userInfo.hasEquity ?? false) {
                                if (appManager.userInfo.equityExpiryTime != null) {
                                  try {
                                    final timestamp =
                                        int.parse(appManager.userInfo.equityExpiryTime!);
                                    final expiryDate =
                                        DateTime.fromMillisecondsSinceEpoch(timestamp);
                                    displayText =
                                        "${("vip_expires".bhTR)}: ${DateTimeUtil.getDateTimeStr(dateTime: expiryDate)}";
                                  } catch (e) {
                                    displayText = "";
                                  }
                                } else {
                                  displayText = "Lifetime".bhTR;
                                }
                              }

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayText,
                                    maxLines: 1,
                                    style: FontUtils.sansSemiBold(
                                      color: textColor,
                                      size: 6.sp,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Obx(() {
                                    final isRTL = BHLanguageMar().isRightToLeft.value;
                                    final arrow = Image.asset(
                                      ImageAssets.righticon,
                                      width: 5.w,
                                      height: 5.w,
                                    );
                                    return isRTL
                                        ? Transform(
                                            transform: Matrix4.identity()..rotateY(3.14159),
                                            alignment: Alignment.center,
                                            child: arrow,
                                          )
                                        : arrow;
                                  }),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                MyGaps.vGaps5w,
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _coinInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Container(
        decoration: BoxDecoration(
          gradient:const LinearGradient(colors: MyColor.messageBGs, begin:  AlignmentDirectional.centerEnd ,end: AlignmentDirectional.centerStart),
          borderRadius: BorderRadius.all(Radius.circular(8.w))
        ),
        child: GestureDetector(
          onTap: () => Get.toNamed(RoutePath.coinStorePage),
          child: Stack(
            alignment: Alignment.center,
            children: [
              
              Container(
                height: 46.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        ImageAssets.coinsStore1,
                        width: 21.w,
                        height: 21.w,
                      ),
                      MyGaps.hGaps5w,
                      Expanded(
                          child: AutoSizeText(
                        "lable_my_coins".bhTR,
                        maxLines: 1,
                        style: FontUtils.boldItalic(
                          color: MyColor.black,
                          size: 11.sp,
                        ),
                      )),
                      MyGaps.hGaps5w,
                      GetBuilder<AppConfigManager>(
                        builder: (logic) {
                          return Text(
                            "${logic.userInfo.availableCoins ?? 0}",
                            maxLines: 1,
                            style: FontUtils.sansSemiBold(
                              color: MyColor.white,
                              size: 10.sp,
                            ),
                          );
                        },
                      ),
                      // Expanded(
                      //   child: Align(
                      //     alignment: BHLanguageMar().isRightToLeft.value ? Alignment.centerLeft : Alignment.centerRight,
                      //     child: GetBuilder<AppConfigManager>(
                      //       builder: (logic) {
                      //         return Text(
                      //           "${logic.userInfo.availableCoins ?? 0}",
                      //           maxLines: 1,
                      //           style: TextStyle(
                      //             color: MyColor.black,
                      //             fontSize: 10.sp,
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //         );
                      //       },
                      //     ),
                      //   ),
                      // ),
                      SizedBox(width: 8.w),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _items() {
    List<Widget> list = _getList();

    return GridView.builder(
      itemCount: list.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(8.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4.w,
        crossAxisSpacing: 4.w,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return list[index];
      },
    );
  }

  // 构建测试按钮
  Widget _buildTestButton() {
    final appManager = Get.find<AppConfigManager>();

    return Obx(() {
      final isTestMode = appManager.testOverrideVipStatus.value;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: GestureDetector(
          onTap: () {
            appManager.toggleTestVipStatus();
          },
          child: Container(
            height: 30.w,
            decoration: BoxDecoration(
              color: isTestMode
                  ? Colors.red.withOpacity(0.7)
                  : Colors.blue.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: Center(
              child: Text(
                isTestMode ? "测试模式：VIP已关闭" : "开启测试模式",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// 顶部信息页
class _TopInfo extends StatelessWidget {
  _TopInfo({Key? key}) : super(key: key);

  final pageLogic = Get.find<MineLogic>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      child: GetBuilder<AppConfigManager>(
        builder: (logic) {
          Widget avatar = MyExtendedNetworkImage(
            url: logic.userInfo.avatarUrl ?? "",
            width: 37.w,
            height: 37.w,
            fit: BoxFit.cover,
            shape: BoxShape.circle,
          );

          // 使用自定义头像边框组件
          avatar = _AvatarFrameWidget(
            avatar: avatar,
            isVip: logic.userInfo.hasEquity ?? false,
          );

          return Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Get.toNamed(RoutePath.modifyInfoPage);
                      },
                      child: avatar,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(RoutePath.modifyInfoPage),
                    behavior: HitTestBehavior.translucent,
                    child: Container(
                      width: 50.w,
                      color: MyColor.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          MyGaps.vGaps5w,
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                  child: Text(
                                (logic.userInfo.nickname ?? "").fixAutoLines(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 8.sp,
                                ),
                              )),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(1.5.r)),
                                ),
                                width: 8.w,
                                height: 8.w,
                                alignment: Alignment.center,
                                child: Image.asset(
                                  ImageAssets.mineModify,
                                  width: 6.w,
                                  height: 6.w,
                                ),
                              )
                            ],
                          ),
                          MyGaps.vGaps2w,
                          // AgeCountryRowWidget(
                          //   age: "${logic.userInfo?.age ?? 0}",
                          //   country: (logic.userInfo?.country ?? ""),
                          //   countryMaxLength: 20,
                          // )

                          // Row(
                          //   children: [
                          //     Container(
                          //       decoration: BoxDecoration(
                          //         color: MyColor.white,
                          //         borderRadius: BorderRadius.circular(4.w),
                          //       ),
                          //       padding: EdgeInsets.symmetric(horizontal: 4.w),
                          //       child: Text(
                          //         "${logic.userInfo.age ?? 0}",
                          //         style: TextStyle(
                          //           color: MyColor.pinkFF6FA7,
                          //           fontSize: 6.sp,
                          //         ),
                          //       ),
                          //     ),
                          //     MyGaps.hGaps5w,
                          //     Text(
                          //       logic.userInfo.country ?? "",
                          //       maxLines: 1,
                          //       overflow: TextOverflow.ellipsis,
                          //       style: TextStyle(
                          //         color: MyColor.white,
                          //         fontSize: 8.sp,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ),
                  GetBuilder<AppConfigManager>(
                    builder: (appManager) {
                      var imageList = <String>[
                        ImageAssets.level0,
                        ImageAssets.level1,
                        ImageAssets.level2,
                        ImageAssets.level3,
                        ImageAssets.level4,
                        ImageAssets.level5,
                        ImageAssets.level6,
                        ImageAssets.level7,
                        ImageAssets.level8,
                        ImageAssets.level9,
                        ImageAssets.level10,
                      ];

                      String image = imageList[
                          (appManager.userInfo.level ?? 0) > 10
                              ? 0
                              : (appManager.userInfo.level ?? 0)];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22.w,
                            height: 8.w,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.w),
                              color: LevelColor.levelColorList[
                                  (appManager.userInfo.level ?? 0)],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  image,
                                  width: 10.w,
                                  height: 6.w,
                                ),
                                Text(
                                  "Lv${(appManager.userInfo.level ?? 0)}",
                                  style: TextStyle(
                                    fontSize: 5.sp,
                                    color: (appManager.userInfo.level ?? 0) == 0
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          MyGaps.hGaps2w,
                          Text(
                            "ID:${appManager.userInfo.userId ?? 0}",
                            style: TextStyle(
                              fontSize: 6.sp,
                              color: MyColor.grey8C8C8C,
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ],
              ),
              Positioned(
                top: 32.w,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(RoutePath.modifyInfoPage);
                  },
                  child: Image.asset(
                    ImageAssets.settingAvatarUpdate,
                    width: 10.w,
                    height: 10.w,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// VIP用户和普通用户的头像框组件
class _AvatarFrameWidget extends StatelessWidget {
  final Widget avatar;
  final bool isVip;

  const _AvatarFrameWidget({
    Key? key,
    required this.avatar,
    required this.isVip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isVip) {
      return _buildVipAvatarFrame();
    } else {
      return _buildNormalAvatarFrame();
    }
  }

  /// 构建VIP用户头像框
  Widget _buildVipAvatarFrame() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 基本的头像容器
        Container(
          width: 41.w,
          height: 41.w,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(ImageAssets.vipAvatarBorder),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 37.w,
              height: 37.w,
              child: avatar,
            ),
          ),
        ),
        // 顶部皇冠效果
        Positioned(
          top: -10.w, // 调整位置使皇冠位于头像顶部
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset(
              ImageAssets.queen, // 使用皇冠图片
              width: 18.w,
              height: 14.w,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建普通用户头像框
  Widget _buildNormalAvatarFrame() {
    return Container(
      width: 41.w,
      height: 41.w,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageAssets.avtarBorder),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 37.w,
          height: 37.w,
          child: avatar,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.onTap,
    this.trailingText,
  }) : super(key: key);

  /// 图片路径
  final String imagePath;

  /// 名称
  final String title;

  /// 点击
  final VoidCallback? onTap;

  // 尾部文字
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    Widget trailing = Icon(
      Icons.arrow_forward_ios_rounded,
      color: MyColor.menuArrowColor,
    );
    if (trailingText != null) {
      trailing = Row(
        children: [
          Text(
            trailingText ?? "",
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 6.sp,
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 2.w,
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: MyColor.menuArrowColor,
          )
        ],
      );
    }
    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 55.w,
          width: 55.w,
          decoration: BoxDecoration(
            color: MyColor.rechargeItemBG,
            borderRadius: BorderRadius.circular(8.w),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    MyGaps.vGaps10w,
                    SizedBox(
                      width: 15.w,
                      height: 15.w,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                    MyGaps.vGaps5w,
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 6.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded(child: SizedBox()),
              // trailing
            ],
          ),
        )

        // Row(
        //   onTap: onTap,
        //   contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.w),
        //   leading: SizedBox(
        //     width: 10.w,
        //     height: 10.w,
        //     child: Image.asset(
        //       imagePath,
        //     ),
        //   ),
        //   horizontalTitleGap: 0,
        //   title: Text(
        //     title,
        //     style: TextStyle(
        //       color: MyColor.white,
        //       fontSize: 8.sp,
        //     ),
        //   ),
        //   trailing: trailing,
        // ),
        );
  }
}

class LevelColor {
  static List<Color> levelColorList = [
    const Color(0XFF565656),
    const Color(0XFF95FFE2),
    const Color(0XFF6FE1F3),
    const Color(0XFF2BD7FF),
    const Color(0XFF54B9FF),
    const Color(0XFF7392FF),
    const Color(0XFF8769FF),
    const Color(0XFFA073FF),
    const Color(0XFFA73BFF),
    const Color(0XFFFF73EB),
    const Color(0XFFFF737C),
  ];
}
