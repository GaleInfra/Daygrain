
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/user_status_service.dart';
import 'package:untitled1/config/route_observer.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/dynamic/dy_scale_video/DyVideoHandleModel.dart';
import 'package:untitled1/pages/dynamic/dy_scale_video/custom_refresh_header.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/utils/online_status_util.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/status/refresh_widget.dart';
import 'package:chewie/chewie.dart';

import 'logic.dart';

class DyScaleVideoCard extends StatefulWidget {
  const DyScaleVideoCard({Key? key, required this.item}) : super(key: key);

  final DyVideoHandleModel item;

  @override
  State<DyScaleVideoCard> createState() => _DyScaleVideoCardState();
}

class _DyScaleVideoCardState extends State<DyScaleVideoCard>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  void initState() {
    super.initState();

    widget.item.viewRefresh = () {
      setState(() {});
    };
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPopNext() {
    // widget.item.didPopNext();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    // widget.item.didPushNext();
    super.didPushNext();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String imageUrl = widget.item.item.videoPaths?.first.thumbUrl ?? "";
    if (imageUrl.isEmpty) {
      imageUrl = widget.item.item.videoPaths?.first.middleThumbUrl ?? "";
    }
    Widget texts = Align(
      alignment: BHLanguageMar().isRightToLeft.value
          ? Alignment.bottomRight
          : Alignment.bottomLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 7.w),
        margin: EdgeInsets.only(bottom: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.item.nickname ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w500),
            ),
            SizedBox(
              height: 3.w,
            ),
            Text(
              widget.item.item.about ?? "",
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
    Widget floatsWidget = Positioned(
      left: BHLanguageMar().isRightToLeft.value ? 7.w : null,
      right: BHLanguageMar().isRightToLeft.value ? null : 7.w,
      bottom: 62.w,
      child: GetBuilder<DyScaleVideoLogic>(builder:(logic) {
        bool isOnline = (logic.userStatus.value == OnlineStatusUtil.online ||
            logic.userStatus.value == OnlineStatusUtil.available);
        return logic.currentItem.value?.item.userId?.isEmpty ?? true ? Container() : Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //头像
            SizedBox(
              width: 22.w,
              height: 26.w,
              child:  Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: 头像点击,去详情
                      logic.onAvatarTap();
                    },
                    child: MyExtendedNetworkImage(
                      url: logic.currentItem.value?.item.avatar ?? "",
                      width: 22.w,
                      height: 22.w,
                      shape: BoxShape.circle,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (!(logic.currentItem.value?.item.isFriend ?? false))
                    GestureDetector(
                      onTap: (){
                        logic.onFollowTouch();
                      },
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 22.w,
                          height: 10.w,
                          color: Colors.transparent,
                          alignment: Alignment.bottomCenter,
                          child: Image.asset(
                            ImageAssets.dyFollowAdd,
                            width: 8.w,
                            height: 8.w,
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
            SizedBox(
              height: 13.w,
            ),
            GestureDetector(
              onTap: () {
                if (logic.currentItem.value?.item.userId?.isNotEmpty ?? false) {
                  MessageChatPage.to(
                      UserInfoModel(userId: logic.currentItem.value?.item.userId ?? ""));
                }
              },
              child: Container(
                width: 22.w,
                height: 22.w,
                decoration: BoxDecoration(
                  color: MyColor.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(11.w),
                ),
                child: Center(
                  child: Image.asset(
                    ImageAssets.broadcasterChat,
                    fit: BoxFit.cover,
                    width: 12.w,
                    height: 9.w,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 13.w,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isOnline
                    ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: GestureDetector(
                    onTap: () {
                      logic.onVideoCall();
                    },
                    child: Image.asset(
                      ImageAssets.broadcasterCall,
                      fit: BoxFit.fill,
                    ),
                  ),
                )
                    : GestureDetector(
                  onTap: () {
                    logic.onVideoCall();
                  },
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: Image.asset(
                      ImageAssets.messageVideoCall,
                      width: 22.w,
                      height: 22.w,
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      }),
    );
    Widget placeImage = Align(
      child: Container(
        margin: EdgeInsets.only(top: DeviceUtil().statusBarHeight ?? 0),
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
    Widget noVideo = Stack(
      children: [
        placeImage,
        const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        texts,
        floatsWidget
      ],
    );

    // if (widget.item == null || widget.item.controller == null) {
    //   return noVideo;
    // }

      return Obx(() => widget.item.isVideoInitialized.value && widget.item.controller != null ? Stack(
        children: [

          Align(
            child: Container(
              margin: EdgeInsets.only(top: DeviceUtil().statusBarHeight ?? 0),
              child: Chewie(
                controller: widget.item.controller!,
              ),
            ),
          ),
          texts,
          floatsWidget
        ],
      ):noVideo,);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }
}

class DyScaleVideoPage extends StatefulWidget {
  const DyScaleVideoPage({super.key});

  @override
  State<DyScaleVideoPage> createState() => _DyScaleVideoPageState();
}

class _DyScaleVideoPageState extends State<DyScaleVideoPage> with RouteAware {
  late DyScaleVideoLogic logic;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPushNext() {
    logic.closeWakelock();
    for (var element in logic.itemModels) {
      element.didPushNext();
    }
    super.didPushNext();
  }

  @override
  void didPopNext() {
    // 回到当前页
    for (var element in logic.itemModels) {
      element.didPopNext();
    }
    super.didPopNext();
  }

  @override
  void dispose() {
    super.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //获取首帧再执行关闭
    logic = Get.put(DyScaleVideoLogic());
  }

  @override
  Widget build(BuildContext context) {
    Widget topWidget = Positioned(
      top: BHPlatform.isWeb ? (DeviceUtil().statusBarHeight ?? 0) : 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 24.w,
                      padding: EdgeInsets.only(left: 2.w),
                      child: Stack(
                        children: [
                          Padding(
                              padding: EdgeInsets.only(left: 2.w),
                              child: Image.asset(
                                ImageAssets.storyTabTop,
                                width: 15.w,
                                height: 15.w,
                                fit: BoxFit.contain,
                              )),
                          Container(
                            alignment: Alignment.bottomCenter,
                            padding: EdgeInsets.only(bottom: 4.w),
                            child: Text("Story".bhTR,
                                style: FontUtils.boldItalic(
                                    size: 10.w, color: MyColor.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GetBuilder<DyScaleVideoLogic>(builder: (logic) {
              String tips = "";
              if (logic.indicatorMode.value == IndicatorMode.drag) {
                tips = "pull_to_refresh".bhTR;
              } else if (logic.indicatorMode.value == IndicatorMode.armed) {
                tips = "release_to_refresh".bhTR;
              } else if (logic.indicatorMode.value == IndicatorMode.ready) {
                tips = "refreshing".bhTR;
              } else if (logic.indicatorMode.value == IndicatorMode.done) {
                tips = "refresh_completed".bhTR;
              } else {
                tips = "";
              }
              return Container(
                width: double.infinity,
                height: 24.w,
                alignment: Alignment.center,
                child: Text(tips,
                    style:TextStyle(fontSize: 9.w, color: MyColor.white)),
              );
            })
          ],
        ),
      ),
    );

    // Widget floatsWidget = Positioned(
    //   left: BHLanguageMar().isRightToLeft.value ? 7.w : null,
    //   right: BHLanguageMar().isRightToLeft.value ? null : 7.w,
    //   bottom: 62.w,
    //   child: Obx(() {
    //     bool isOnline = (logic.userStatus.value == OnlineStatusUtil.online ||
    //         logic.userStatus.value == OnlineStatusUtil.available);
    //     return logic.currentItem.value?.item.userId?.isEmpty ?? true
    //         ? Container()
    //         : Column(
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               //头像
    //               Container(
    //                 width: 22.w,
    //                 height: 26.w,
    //                 child: Stack(
    //                   children: [
    //                     GestureDetector(
    //                       onTap: () {
    //                         // TODO: 头像点击,去详情
    //                         logic.onAvatarTap();
    //                       },
    //                       child: MyExtendedNetworkImage(
    //                         url: logic.currentItem.value?.item.avatar ?? "",
    //                         width: 22.w,
    //                         height: 22.w,
    //                         shape: BoxShape.circle,
    //                         fit: BoxFit.cover,
    //                       ),
    //                     ),
    //                     if (!(logic.currentItem.value?.item.isFriend ?? false))
    //                       GestureDetector(
    //                         onTap: () {
    //                           logic.onFollowTouch();
    //                         },
    //                         child: Align(
    //                           alignment: Alignment.bottomCenter,
    //                           child: Container(
    //                             width: 22.w,
    //                             height: 10.w,
    //                             color: Colors.transparent,
    //                             alignment: Alignment.bottomCenter,
    //                             child: Image.asset(
    //                               ImageAssets.dyFollowAdd,
    //                               width: 8.w,
    //                               height: 8.w,
    //                             ),
    //                           ),
    //                         ),
    //                       )
    //                   ],
    //                 ),
    //               ),
    //               SizedBox(
    //                 height: 13.w,
    //               ),
    //               GestureDetector(
    //                 onTap: () {
    //                   if (logic.currentItem.value?.item.userId?.isNotEmpty ??
    //                       false) {
    //                     MessageChatPage.to(UserInfoModel(
    //                         userId: logic.currentItem.value?.item.userId ?? ""));
    //                   }
    //                 },
    //                 child: Container(
    //                   width: 22.w,
    //                   height: 22.w,
    //                   decoration: BoxDecoration(
    //                     color: MyColor.black.withOpacity(0.5),
    //                     borderRadius: BorderRadius.circular(11.w),
    //                   ),
    //                   child: Center(
    //                     child: Image.asset(
    //                       ImageAssets.broadcasterChat,
    //                       fit: BoxFit.cover,
    //                       width: 12.w,
    //                       height: 9.w,
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //               SizedBox(
    //                 height: 13.w,
    //               ),
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 children: [
    //                   isOnline
    //                       ? Container(
    //                           width: 22.w,
    //                           height: 22.w,
    //                           child: GestureDetector(
    //                             onTap: () {
    //                               logic.onVideoCall();
    //                             },
    //                             child: Image.asset(
    //                               ImageAssets.broadcasterCall,
    //                               fit: BoxFit.fill,
    //                             ),
    //                           ),
    //                         )
    //                       : GestureDetector(
    //                           onTap: () {
    //                             logic.onVideoCall();
    //                           },
    //                           child: Container(
    //                             width: 22.w,
    //                             height: 22.w,
    //                             child: Image.asset(
    //                               ImageAssets.broadcasterUnCall,
    //                               width: 22.w,
    //                               height: 22.w,
    //                             ),
    //                           ),
    //                         ),
    //                 ],
    //               )
    //             ],
    //           );
    //   }),
    // );

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: MyColor.blank22,
        ),
        // Image.asset(
        //   ImageAssets.flashBackground,
        //   width: double.infinity,
        //   height: double.infinity,
        //   fit: BoxFit.fill,
        // ),
        SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                // topStarFlowWidget,
                GetBuilder<DyScaleVideoLogic>(builder: (logic) {
                  return Stack(
                    children: [
                      Align(
                        child: RefreshWidget(
                          logic: logic,
                          emptyMsg: "error_noData".bhTR,
                          header: const CustomRefreshHeader(),
                          child: PageView.builder(
                              controller: logic.pageController,
                              scrollDirection: Axis.vertical,
                              onPageChanged: (value) {
                                final oldIndex = logic.index.value;
                                logic.index.trigger(value);
                                // logic.index.value = value;
                                // 只初始5个Iten 的 VideoPlayerController  只初始化 index的前后两个
                                // 判断当前 下标和新的下标  然后销毁超出部分

                                for (int i = 0; i < logic.itemModels.length; i++) {
                                  if ((i - value) > 2 || value > i) {
                                    logic.itemModels[i].dispose();
                                  }else {
                                    logic.itemModels[i].initializeVideo();
                                    if (i == value) {
                                      logic.itemModels[i].videoPlayerController?.play();
                                    }else {
                                      logic.itemModels[i].videoPlayerController?.pause();
                                    }
                                  }
                                }

                                // if (oldIndex > value) {
                                //   // 销毁 大于当前下标的
                                //   if (logic.index.value + 2 <
                                //       logic.itemModels.length) {
                                //     logic.itemModels[oldIndex + 2]
                                //         .dispose();
                                //   }
                                //   if (value - 2 >= 0) {
                                //     logic.itemModels[value - 2]
                                //         .initializeVideo();
                                //         logic.itemModels[value - 2].controller?.pause();
                                //   }
                                //
                                //
                                // } else {
                                //   // 销毁 小于当前下标的
                                //   if (oldIndex - 2 >= 0) {
                                //     logic.itemModels[oldIndex - 2]
                                //        .dispose();
                                //   }
                                //   if (value + 2 < logic.itemModels.length) {
                                //     logic.itemModels[value + 2]
                                //        .initializeVideo();
                                //         logic.itemModels[value + 2].controller?.pause();
                                //   }
                                // }
                                //   if(value - 1 >= 0){
                                //     logic.itemModels[value - 1]
                                //        .initializeVideo();
                                //        logic.itemModels[value - 1].controller?.pause();
                                //   }
                                //   if(value + 1 < logic.itemModels.length){
                                //     logic.itemModels[value + 1]
                                //        .initializeVideo();
                                //        logic.itemModels[value + 1].controller?.pause();
                                //   }
                                //   logic.itemModels[value]
                                //     .initializeVideo();
                                

                                logic.currentItem
                                    .trigger(logic.itemModels[value]);
                                    // logic.currentItem.value?.controller?.play();
                                getUserStatusService()
                                    ?.addUserIdAndForceRefresh(
                                        logic.currentItem.value?.item.userId ??
                                            "");
                              },
                              itemCount: logic.itemModels.length,
                              itemBuilder: (context, index) {
                                final currentModel = logic.itemModels[index];
                                if (index - logic.index.value > 1 || logic.index.value - index > 1) {
                                  return Container();
                                }
                                return Container(
                                  child: DyScaleVideoCard(
                                    item: currentModel,
                                  ),
                                );
                              }),
                        ),
                      )
                    ],
                  );
                }),
                topWidget,
                // if (logic.currentItem?.value?.userId?.isNotEmpty ?? false)
                // floatsWidget
                // wheelTexts,ƒ
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// class DyScaleVideoPage extends StatelessWidget {
//   DyScaleVideoPage({Key? key}) : super(key: key);
//
//   // final logic = Get.find<DyVideoLogic>();
//
//   @override
//   Widget build(BuildContext context) {
//     final logic = Get.put(DyScaleVideoLogic());
//     bool isOnline = false;
//     Widget topWidget = Positioned(
//       top: BHPlatform.isWeb ? (DeviceUtil().statusBarHeight ?? 0) : 0,
//       left: 0,
//       right: 0,
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   child: Stack(
//                     children: [
//                       Padding(padding: EdgeInsets.only(left: 2.w,bottom: 2.w), child: Image.asset(
//                         ImageAssets.topTabBack,
//                         width: 10.5.w,
//                         height: 10.5.w,
//                         fit: BoxFit.contain,
//                       )),
//                       Container(
//                         padding: EdgeInsets.symmetric(vertical: 3.w),
//                         child: Text(
//                           "Story".bhTR,
//                           style: FontUtils.boldItalic(
//                               size:  8.5.w,
//                               color: MyColor.white
//                           ),
//                         ),
//                       ),
//
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Align(
//                     alignment: BHLanguageMar().isRightToLeft.value ? Alignment.centerLeft : Alignment.centerRight,
//                     child: IconButton(
//                       onPressed: () => BlockReportSheet.show(
//                         bindWidget: context,
//                         toUserId:  "",
//                         isFollow: false,
//                         isBlock: false,
//                         onFollowOrUnBack: (result) {},
//                         onBlockOrUnBack: (result) {},
//                       ),
//                       icon: const Icon(Icons.more_horiz, color: MyColor.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//
//     Widget floatsWidget = Positioned(
//       left: BHLanguageMar().isRightToLeft.value ? 7.w : null,
//       right: BHLanguageMar().isRightToLeft.value ? null : 7.w,
//       bottom: 12.w,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//          //头像
//           Obx(
//           () => Container(
//               width: 22.w,
//               height: 26.w,
//               child: Stack(
//                 children: [
//                   GestureDetector(
//                     onTap: (){},
//                     child: MyExtendedNetworkImage(url: logic.currentItem?.value?.avatar ?? "", width: 22.w, height: 22.w, shape: BoxShape.circle,fit: BoxFit.cover,),
//                   ),
//                   Align(
//                     alignment: Alignment.bottomCenter,
//                     child: Image.asset(ImageAssets.dyFollowAdd,width: 8.w,height: 8.w,),
//                   )
//                 ],
//               ),
//             ),
//           ),
//           SizedBox(height: 13.w,),
//           GestureDetector(
//             onTap: () => MessageChatPage.to(UserInfoModel(userId: logic.currentItem?.value?.userId ?? "")),
//             child: Container(
//               width: 22.w,
//               height: 22.w,
//               decoration: BoxDecoration(
//                 color: MyColor.black.withOpacity(0.5),
//                 borderRadius: BorderRadius.circular(11.w),
//               ),
//               child: Center(
//                 child: Image.asset(
//                   ImageAssets.broadcasterChat,
//                   fit: BoxFit.cover,
//                   width: 12.w,
//                   height: 9.w,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 13.w,),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               isOnline
//                   ? Container(
//                 width: 22.w,
//                 height: 22.w,
//                 child: GestureDetector(
//                   onTap: () {
//                     // logic.onVideoCall();
//                   },
//                   child: Image.asset(
//                     ImageAssets.broadcasterCall,
//                     fit: BoxFit.fill,
//
//                   ),
//                 ),
//               )
//                   : Container(
//                 width: 22.w,
//                 height: 22.w,
//                 child: Image.asset(
//                   ImageAssets.broadcasterUnCall,
//                   width: 22.w,
//                   height: 22.w,
//                 ),
//               ),
//             ],
//           )
//         ],
//       ),
//     );
//
//     return Stack(
//       children: [
//         Container(
//           width: double.infinity,
//           height: double.infinity,
//           color: MyColor.appBackground,
//         ),
//         // Image.asset(
//         //   ImageAssets.flashBackground,
//         //   width: double.infinity,
//         //   height: double.infinity,
//         //   fit: BoxFit.fill,
//         // ),
//         SafeArea(
//           child: Scaffold(
//             body: Stack(
//               children: [
//                 // topStarFlowWidget,
//                 GetBuilder<DyScaleVideoLogic>(builder: (logic) {
//                   return PageView.builder(
//                     scrollDirection: Axis.vertical,
//                     onPageChanged: (value) {
//                       logic.index.value = value;
//                       logic.currentItem.value = logic.list[value];
//                     },
//                     itemCount: logic.list.length,
//                     itemBuilder: (context, index) {
//                       final item = logic.list[index];
//                       return DyScaleVideoCard(
//                         item: item,
//                         index: index,
//                       );
//                     },
//                   );
//                 }),
//                 topWidget,
//                 floatsWidget
//                 // wheelTexts,
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
