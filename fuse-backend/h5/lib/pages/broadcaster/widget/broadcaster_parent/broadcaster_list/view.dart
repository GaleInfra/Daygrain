import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/business/say_hi/robot_script_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/user_status_service.dart';
import 'package:untitled1/event_bus/keyboard_event.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/utils/online_status_util.dart';
import 'package:untitled1/utils/preconnect_origins.dart';
import 'package:untitled1/widget/banner/banner_widget.dart';
import 'package:untitled1/widget/banner/inline_banner_widget.dart';
import 'package:untitled1/widget/dialog/vip_coin_gift_dialog.dart';
import 'package:untitled1/widget/online_status_widget.dart';
import 'package:untitled1/widget/status/refresh_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../event_bus/base/event_bus_util.dart';
import '../../../../../model/broadcaster/broadcaster_model.dart';
import '../../../../../res/image_assets.dart';
import '../../../../../res/my_color.dart';
import '../../../../../widget/image/my_extended_network_image.dart';
import 'logic.dart';

/// 主播墙-列表
class BroadcasterListComment extends StatefulWidget {
  const BroadcasterListComment({
    super.key,
    required this.category,
    required this.tag,
    // 配置该功能是否使用
    this.enableInlineBanner = false,
    /// 配置该功能的间隔个数，每隔多少个主播插入一个Banner，默认4个
    /// 注意：由于是2列布局，实际是每隔 interval/2 行插入一个Banner
    this.inlineBannerInterval = 12,
  });

  /// 分类
  final String category;

  /// 标签
  final String tag;

  /// 是否启用内联Banner功能（在主播列表中插入Banner）
  final bool enableInlineBanner;

  /// 内联Banner插入间隔（每隔多少个主播插入一个Banner，默认4个）
  /// 注意：由于是2列布局，实际是每隔 interval/2 行插入一个Banner
  final int inlineBannerInterval;

  @override
  State<BroadcasterListComment> createState() => _BroadcasterListCommentState();
}

class _BroadcasterListCommentState extends State<BroadcasterListComment> with AutomaticKeepAliveClientMixin {
  late BroadcasterListLogic logic;

  /// logic的标签分类
  late String logicTag;

  @override
  void initState() {
    logicTag = "${widget.category}${widget.tag}";
    logic = Get.put(BroadcasterListLogic(), tag: logicTag);
    logic.initData(widget.category, widget.tag);
    super.initState();
  }

  /// 从接口获取 enableInlineBanner 的值
  /// 优先使用接口 customList.show 字段，如果接口没有配置则使用传入的默认值
  bool get enableInlineBanner {
    final appConfig = Get.find<AppConfigManager>();
    final customList = appConfig.strategyModel?.customList;
    if (customList?.show != null) {
      // 将字符串 "true"/"false" 转换为 bool
      return customList!.show!.toLowerCase() == 'true';
    }
    return widget.enableInlineBanner;
  }

  /// 从接口获取 inlineBannerInterval 的值
  /// 优先使用接口 customList.num 字段，如果接口没有配置则使用传入的默认值
  int get inlineBannerInterval {
    final appConfig = Get.find<AppConfigManager>();
    final customList = appConfig.strategyModel?.customList;
    if (customList?.num != null) {
      // 将字符串转换为 int
      final numValue = int.tryParse(customList!.num!);
      if (numValue != null && numValue > 0) {
        return numValue;
      }
    }
    return widget.inlineBannerInterval;
  }

  bool isVisibleBanner = false;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 使用 GetBuilder 监听 AppConfigManager 的变化，确保配置更新时 UI 能够刷新
    return GetBuilder<AppConfigManager>(
      builder: (appConfig) {
        return GetBuilder<BroadcasterListLogic>(
          tag: logicTag,
          builder: (logic) {
            return RefreshWidget(
              logic: logic,
              autoNoMore: false,
              loadingWidget: const _BroadcasterWallSkeleton(),
              child: CustomScrollView(
                cacheExtent: 800,
                controller: logic.scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: NotificationListener(
                      onNotification: (n) {
                        // 因为NotificationListener是向上冒泡通知
                        // 当返回true时，会消费掉事件，不会继续向上通知
                        // 这里的Banner一直会触发滑动事件，所以在此处消费
                        return true;
                      },
                      child: VisibilityDetector(
                        key: ValueKey("banner_${logic.showBanner}"),
                        onVisibilityChanged: (info) {
                          if (info.visibleFraction <= 0.1) {
                            isVisibleBanner = false;
                            logic.swiperController?.stopAutoplay();
                          } else {
                            if (isVisibleBanner == false) {
                              logic.swiperController?.startAutoplay();
                              isVisibleBanner = true;
                            }
                          }
                        },
                        child: BannerWidget(
                          showBanner: logic.showBanner,
                          horizontalPadding: 3.w,
                          swiperController: logic.swiperController, //如果正在下拉刷新则不可自动播放
                          externalControl: true,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: (logic.showBanner && !appConfig.isReviewPkg.value) ? 8 : 0),
                    sliver: enableInlineBanner
                        ? _buildMixedGridList(logic, inlineBannerInterval)
                        : _buildOriginalGridList(logic),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 构建原始Grid列表（不使用内联Banner）
  Widget _buildOriginalGridList(BroadcasterListLogic logic) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return RepaintBoundary(
            child: _Item(
              key: ValueKey(logic.list[index].userId),
              item: logic.list[index],
              onTap: () => BroadcasterDetailPage.to(UserInfoModel.fromJson(logic.list[index].toJson())),
              onCall: () => logic.onCall(logic.list[index]),
              onSayHi: () => logic.onSayHi(logic.list[index]),
              onChat: () => logic.onChat(logic.list[index]),
            ),
          );
        },
        findChildIndexCallback: (key) {
          if (key is ValueKey) {
            final id = key.value;
            return logic.list.indexWhere((item) => item.userId == id);
          }
          return null;
        },
        childCount: logic.list.length,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: false,
      ),
    );
  }

  /// 构建混合列表（主播 + 内联Banner）
  Widget _buildMixedGridList(BroadcasterListLogic logic, int interval) {
    final int broadcasterCount = logic.list.length;
    // 计算需要多少行（每行2个主播）
    final int rowCount = (broadcasterCount / 2).ceil();
    // 计算每隔多少行插入一个banner（interval个主播 = interval/2 行）
    final int rowsPerBanner = (interval / 2).ceil();
    // Banner 只插入一次，所以总行数 = 主播行数 + 1（一个Banner）
    final int totalRowCount = rowCount + 1;
    
    // 计算每个item的宽度和高度（保持原来的宽高比 0.75）
    final double screenWidth = ScreenUtil().screenWidth;
    final double itemWidth = (screenWidth - (3.w * 2) - 8.w) / 2; // 减去padding和间距
    final double itemHeight = itemWidth / 0.75; // 保持原来的宽高比
    
    // 计算Banner应该插入在哪一行（第一个满足间隔条件的位置）
    int bannerInsertRow = -1;
    if (rowsPerBanner > 0 && rowCount > 0) {
      // 找到第一个满足间隔条件的位置
      for (int i = 1; i < rowCount; i++) {
        if (i % rowsPerBanner == 0) {
          bannerInsertRow = i;
          break; // 只插入一次，找到第一个就退出
        }
      }
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // 计算当前index应该显示什么
          int displayIndex = 0;
          
          for (int i = 0; i < rowCount; i++) {
            // 只在第一个满足条件的位置插入一次banner
            if (bannerInsertRow >= 0 && i == bannerInsertRow) {
              // 这是banner位置
              if (displayIndex == index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8), // 使用固定值8，与原来的mainAxisSpacing保持一致
                  child: NotificationListener(
                    onNotification: (notification) {
                      // 消费滚动事件，防止 Swiper 的滑动事件冒泡到 CustomScrollView
                      // 避免触发列表的加载更多逻辑
                      return true;
                    },
                    child: InlineBannerWidget(
                      horizontalPadding: 0,
                      externalControl: true,
                    ),
                  ),
                );
              }
              displayIndex++;
            }
            
            // 这是主播行
            if (displayIndex == index) {
              // 构建主播行
              final int broadcasterStartIndex = i * 2;
              final bool hasSecond = (broadcasterStartIndex + 1) < broadcasterCount;
              
              return Padding(
                padding: EdgeInsets.only(bottom: 8), // 使用固定值8，与原来的mainAxisSpacing保持一致
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: itemHeight,
                        child: RepaintBoundary(
                          child: _Item(
                            key: ValueKey(logic.list[broadcasterStartIndex].userId),
                            item: logic.list[broadcasterStartIndex],
                            onTap: () => BroadcasterDetailPage.to(UserInfoModel.fromJson(logic.list[broadcasterStartIndex].toJson())),
                            onCall: () => logic.onCall(logic.list[broadcasterStartIndex]),
                            onSayHi: () => logic.onSayHi(logic.list[broadcasterStartIndex]),
                            onChat: () => logic.onChat(logic.list[broadcasterStartIndex]),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8), // 使用固定值8，与原来的crossAxisSpacing保持一致
                    Expanded(
                      child: hasSecond
                          ? SizedBox(
                              height: itemHeight,
                              child: RepaintBoundary(
                                child: _Item(
                                  key: ValueKey(logic.list[broadcasterStartIndex + 1].userId),
                                  item: logic.list[broadcasterStartIndex + 1],
                                  onTap: () => BroadcasterDetailPage.to(UserInfoModel.fromJson(logic.list[broadcasterStartIndex + 1].toJson())),
                                  onCall: () => logic.onCall(logic.list[broadcasterStartIndex + 1]),
                                  onSayHi: () => logic.onSayHi(logic.list[broadcasterStartIndex + 1]),
                                  onChat: () => logic.onChat(logic.list[broadcasterStartIndex + 1]),
                                ),
                              ),
                            )
                          : SizedBox(height: itemHeight),
                    ),
                  ],
                ),
              );
            }
            displayIndex++;
          }
          
          return const SizedBox.shrink();
        },
        findChildIndexCallback: (key) {
          if (key is ValueKey) {
            final id = key.value;
            final broadcasterIndex = logic.list.indexWhere((item) => item.userId == id);
            if (broadcasterIndex >= 0) {
              final int row = broadcasterIndex ~/ 2;
              // 计算考虑banner后的位置（Banner只插入一次）
              final int rowsPerBanner = (interval / 2).ceil();
              int bannerCountBefore = 0;
              if (rowsPerBanner > 0 && row >= rowsPerBanner) {
                // 如果当前行在Banner插入行之后，需要加1
                for (int i = 1; i < row; i++) {
                  if (i % rowsPerBanner == 0) {
                    bannerCountBefore = 1;
                    break; // 只插入一次
                  }
                }
              }
              return row + bannerCountBefore;
            }
          }
          return null;
        },
        childCount: totalRowCount,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _Item extends StatefulWidget {
  const _Item({
    Key? key,
    required this.item,
    this.onTap,
    this.onCall,
    this.onSayHi,
    this.onChat,
  }) : super(key: key);

  final BroadcasterModel item;

  final VoidCallback? onTap;

  final VoidCallback? onCall;

  final VoidCallback? onSayHi;

  final VoidCallback? onChat;

  @override
  State<_Item> createState() => _ItemState();
}

class _ItemState extends State<_Item> with AutomaticKeepAliveClientMixin {
  AppConfigManager? appConfig;
  //状态
  final userStatus = kOffline.obs;
  StreamSubscription? _userStateEvent;
  final UserStatusService? userStatusService = getUserStatusService();

  /// 监听SayHiEvent
  StreamSubscription<SayHiEvent>? _sayHiEvent;

  @override
  void initState() {
    appConfig = Get.find<AppConfigManager>();
    userStatus.value = widget.item.status ?? kOffline;
    _sayHiEvent = EventBusUtil.listen<SayHiEvent>((event) {
      if (event.broadcasterId == widget.item.userId) {
        setState(() {
          
        });
      }
    });
    super.initState();
  }

  //监听显示隐藏
  void onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 0) {
      removeListener();
    } else {
      userStatusService?.addUserId(widget.item.userId ?? "");
      if (_userStateEvent == null) {
        registerListener();
        final stat = userStatusService?.getStatus(widget.item.userId ?? "");
        if (stat != null && stat != userStatus.value) {
          userStatus.value = stat;
          widget.item.status = userStatus.value;
        }
      }
    }
  }

  //监听状态刷新
  void registerListener() {
    removeListener();
    _userStateEvent = EventBusUtil.listen<UserStatusChangeEvent>((event) {
      if (event.uidAndStatus.containsKey(widget.item.userId)) {
        final status = event.uidAndStatus[widget.item.userId];
        if (status != userStatus.value) {
          userStatus.value = status ?? kOffline;
          widget.item.status = userStatus.value;
        }
      }
    });
  }

  //移除监听
  void removeListener() {
    if (_userStateEvent != null) {
      _userStateEvent!.cancel();
      _userStateEvent = null;
    }
  }

  @override
  void dispose() {
    removeListener();
    _sayHiEvent?.cancel();
    _sayHiEvent = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: ValueKey("broadcaster_cell_${widget.item.userId}"),
      onVisibilityChanged: (info) {
        onVisibilityChanged(info);
      },
      child: LayoutBuilder(builder: (context, constraints) {
        //当前宽高
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;
        return GestureDetector(
          onTap: widget.onTap,
          child: Stack(
              alignment: Alignment.topCenter,
              children: [
                MyExtendedNetworkImage(
                  url: _notedAvatar(widget.item.displayAvatar),
                  fallbackUrl: widget.item.avatar,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  // startReload: false,
                  isBroadcaster: true,
                  borderRadius: BorderRadius.all(Radius.circular(6.w)),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      Image.asset(
                        ImageAssets.broadcasterHeader,
                        width: double.infinity,
                        height: 25.w,
                        fit: BoxFit.fill,
                      ),
                    ],
                  ),
                ),
                
                Positioned(
                    top: 5.w,
                    right: 0.w,
                    child: Container(
                      width: (ScreenUtil().screenWidth - (7.w * 2) - 6.w) / 2,
                      alignment: Alignment.centerRight,
                      child: Visibility(
                        visible: widget.item.activityTagUrl != null && widget.item.activityTagUrl!.isNotEmpty,
                        child: MyExtendedNetworkImage(
                          url: widget.item.activityTagUrl ?? '',
                          width: 43.w,
                          height: 11.w,
                          fit: BoxFit.contain,
                          // startReload: false,
                        ),
                      ),
                    )),
                Positioned(
                  bottom: 3.w,
                  left: BHLanguageMar().isRightToLeft.value ? 3.w : 3.w,
                  right: BHLanguageMar().isRightToLeft.value ? 3.w : 3.w,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildUserInfo(),
                      ),
                      Obx(() {
                        return GestureDetector(
                          onTap: () {
                            if (userStatus.value == OnlineStatusUtil.online) {
                              widget.onCall?.call();
                            } else {
                              if (RobotScriptManager.isCanSendSayHi(widget.item.userId ?? "", userStatus.value)) {
                                widget.onSayHi?.call();
                              } else {
                                widget.onChat?.call();
                              }
                            }
                          },
                          child: Stack(
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: Center(
                                  child: Image.asset(
                                    userStatus.value == OnlineStatusUtil.online
                                        ? ImageAssets.broadcasterCall
                                        : (RobotScriptManager.isCanSendSayHi(widget.item.userId ?? "", userStatus.value) ? ImageAssets.broadcasterHi : ImageAssets.broadcasterChatIcon),
                                    width: 20.w,
                                    height: 20.w,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: BHLanguageMar().isRightToLeft.value ? null : 0.w,
                                left: BHLanguageMar().isRightToLeft.value ? 0.w : null,
                                bottom: 3.w,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Obx(() {
                                    return Visibility(
                                      visible: !Get.find<AppConfigManager>().isReviewPkg.value,
                                      child: OnlineStatusWidget(
                                        width: 4.w,
                                        height: 4.w,
                                        status: userStatus.value,
                                      ),
                                    );
                                  }),
                                )),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
        );
      }),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: (ScreenUtil().screenWidth - (7.w * 2) - 6.w) / 2 - 8.w - 20.w,
              child: Text(
                "${widget.item.nickname}".fixAutoLines(),
                maxLines: 1,
                // textDirection: TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                        color: MyColor.white,
                        fontSize: 6.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // SizedBox(width: 7.5.w),
            SizedBox(
              width: (ScreenUtil().screenWidth - (7.w * 2) - 6.w) / 2 - 8.w - 20.w,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.item.countryAndEmoji ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: MyColor.white,
                        fontSize: 6.sp,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Text(
                    " | ",
                    style: TextStyle(
                      color: MyColor.white,
                      fontSize: 5.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Text(
                    "${widget.item.age}",
                    maxLines: 1,
                    style: TextStyle(
                      color: MyColor.white,
                      fontSize: 6.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Row(
        //     mainAxisAlignment: MainAxisAlignment.center,
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Text(
        //         "${widget.item.callCoins}",
        //         style: TextStyle(
        //           color: MyColor.white,
        //           fontSize: 5.sp,
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //       SizedBox(width: 1.w),
        //       Image.asset(
        //         ImageAssets.broadcasterDiamondSmall,
        //         width: 4.5.w,
        //         height: 4.5.w,
        //       ),
        //       SizedBox(width: 1.w),
        //       Text(
        //         "/min".bhTR,
        //         style: TextStyle(
        //           color: MyColor.white,
        //           fontSize: 5.sp,
        //           fontWeight: FontWeight.w600,
        //         ),
        //       ),
        //       SizedBox(width: 1.w),
        //     ],
        //   )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

String _notedAvatar(String url) {
  PreconnectOrigins.note(url);
  return url;
}

/// Same tokens as the HTML `.startup-shell` cards, so the wall keeps its shape until data arrives.
class _BroadcasterWallSkeleton extends StatelessWidget {
  const _BroadcasterWallSkeleton();

  static const _card = Color(0xFF242322);
  static const _border = Color(0xFF302F2E);
  static const _block = Color(0xFF343332);

  Widget _cell() {
    return Container(
      padding: const EdgeInsets.all(14),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Container(
        width: 64,
        height: 12,
        decoration: BoxDecoration(color: _block, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: [
                Expanded(child: Row(children: [Expanded(child: _cell()), const SizedBox(width: 12), Expanded(child: _cell())])),
                const SizedBox(height: 12),
                Expanded(child: Row(children: [Expanded(child: _cell()), const SizedBox(width: 12), Expanded(child: _cell())])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
