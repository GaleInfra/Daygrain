import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/ranking/rank_cp_model.dart';
import 'package:untitled1/model/ranking/ranking_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';


/// create: 2023/4/25
/// desc: 排行榜-顶部信息
class RankingTopWidget extends StatelessWidget {
  const RankingTopWidget({
    Key? key,
    required this.index,
    required this.items,
  }) : super(key: key);
  final int index;
  final List<RankingModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.length < 3) {
      while (items.length < 3) {
        items.add(RankingModel());
      }
    }
    return SizedBox(
      height: 145.w,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 第一名
          _buildFirstPlace(),
          // 第二名
          _buildSecondPlace(),
          // 第三名
          _buildThirdPlace(),

          Padding(
              padding: EdgeInsets.only(bottom: 8.w),
              child: Image.asset(
                ImageAssets.rankingTopBottom,
                width: double.infinity,
                height: 29.5.w,
                fit: BoxFit.cover,
              )),
          // Positioned(
          //   left: BHLanguageMar().isRightToLeft.value ? null : 0,
          //   right: BHLanguageMar().isRightToLeft.value ? 0 : null,
          //   bottom: 0,
          //   child: Container(
          //     height: 16.w,
          //     margin: EdgeInsets.only(left: 8.w),
          //     decoration: BoxDecoration(
          //       color: MyColor.grey4C,
          //       borderRadius: BorderRadius.circular(8.w),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: itemTitles.map((e) {
          //         return Container(
          //           height: double.infinity,
          //           padding: EdgeInsets.symmetric(horizontal: 5.w),
          //           decoration: BoxDecoration(
          //             gradient: itemTitles[selectIndex] == e
          //                 ? MyLinearGradient.getGradient()
          //                 : null,
          //             borderRadius: BorderRadius.circular(8.w),
          //           ),
          //           child: Center(
          //             child: Text(
          //               e,
          //               style: FontUtils.boldItalic(
          //                 size: 9.w,
          //                 color: itemTitles[selectIndex] == e
          //                     ? MyColor.white
          //                     : MyColor.greyCE,
          //               ),
          //             ),
          //           ),
          //         );
          //       }).toList(),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
    //   SizedBox(
    //   height: 140.w,
    //   child: Stack(
    //     children: [
    //       Positioned(
    //         top: 5.w,
    //         left: 0,
    //         child: Image.asset(
    //           ImageAssets.rankingFireworksLeft,
    //           width: 60.w,
    //           height: 100.w,
    //           fit: BoxFit.cover,
    //         ),
    //       ),
    //       Positioned(
    //         top: 15.w,
    //         right: 0,
    //         child: Image.asset(
    //           ImageAssets.rankingFireworksRight,
    //           width: 60.w,
    //           height: 100.w,
    //           fit: BoxFit.cover,
    //         ),
    //       ),
    //       Positioned(
    //         right: 0,
    //         left: 0,
    //         top: 80.w,
    //         child: Center(
    //           child: Image.asset(
    //             ImageAssets.rankingBase,
    //             width: double.infinity,
    //             height: 67.w,
    //             fit: BoxFit.cover,
    //           ),
    //         ),
    //       ),
    //       Positioned(
    //         top: 0,
    //         left: 0,
    //         right: 0,
    //         child: _RankingTime(),
    //       ),
    //       Positioned(
    //         right: 0,
    //         left: 0,
    //         top: 30.w,
    //         child: Center(
    //           child: GestureDetector(
    //             onTap: () {
    //               if (type == "label_charm".bhTR) {
    //                 BroadcasterDetailPage.to(UserInfoModel(
    //                   userId: item.userId,
    //                   avatar: item.avatar,
    //                   nickname: item.nickname,
    //                 ));
    //               }
    //             },
    //             child: Column(
    //               mainAxisSize: MainAxisSize.min,
    //               children: [
    //                 Stack(
    //                   alignment: Alignment.center,
    //                   children: [
    //                     MyExtendedNetworkImage(
    //                       url: item.avatar ?? "",
    //                       width: 50.w,
    //                       height: 50.w,
    //                       fit: BoxFit.cover,
    //                       shape: BoxShape.circle,
    //                     ),
    //                     Image.asset(
    //                       ImageAssets.rankingTop1,
    //                       width: 60.w,
    //                       height: 60.w,
    //                       fit: BoxFit.cover,
    //                     ),
    //                   ],
    //                 ),
    //                 Text(
    //                   item.nickname?.truncateThan(20) ?? "",
    //                   style: TextStyle(
    //                     fontSize: 8.sp,
    //                     color: Colors.black,
    //                     fontWeight: FontWeight.w600,
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildFirstPlace() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 8.w,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (index == 0 && items[0].userId != null) {
                BroadcasterDetailPage.to(UserInfoModel(
                  userId: items[0].userId,
                  avatar: items[0].avatar,
                  nickname: items[0].nickname,
                ));
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                MyExtendedNetworkImage(
                  url: items.first.avatar ?? "",
                  width: 35.w,
                  height: 35.w,
                  fit: BoxFit.cover,
                  shape: BoxShape.circle,
                ),
                Image.asset(ImageAssets.rankingAvatarTop1,
                    width: 54.w, height: 52.w),
              ],
            ),
          ),
          SizedBox(
            width: 63.5.w,
            height: 87.5.w,
            child: Stack(
              children: [
                Image.asset(ImageAssets.rankingTopBg1, fit: BoxFit.cover).bh,
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20.w,
                      ),
                      Text(
                        (items[0].nickname ?? "")
                            .truncateThan(10)
                            .fixAutoLines(),
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        "NO.1",
                        style: FontUtils.boldItalic(
                            color: Colors.black, size: 14.sp),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondPlace() {
    return Positioned(
      right: BHLanguageMar().isRightToLeft.value ? null : Get.width / 2 + 28.w,
      left: BHLanguageMar().isRightToLeft.value ? Get.width / 2 + 27.w : null,
      bottom: 8.w,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (index == 0 && items[1].userId != null) {
                BroadcasterDetailPage.to(UserInfoModel(
                  userId: items[1].userId,
                  avatar: items[1].avatar,
                  nickname: items[1].nickname,
                ));
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                MyExtendedNetworkImage(
                  url: items[1].avatar ?? "",
                  width: 24.w,
                  height: 24.w,
                  fit: BoxFit.cover,
                  shape: BoxShape.circle,
                ),
                Image.asset(ImageAssets.rankingAvatarTop2,
                    width: 35.w, height: 36.5.w),
              ],
            ),
          ),
          SizedBox(
            width: 57.w,
            height: 62.w,
            child: Stack(
              children: [
                Image.asset(ImageAssets.rankingTopBg2, fit: BoxFit.cover).bh,
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 15.w,
                      ),
                      Text(
                        (items[1].nickname ?? "")
                            .truncateThan(10)
                            .fixAutoLines(),
                        maxLines: 1,
                        style: TextStyle(
                          color: MyColor.highlightColor,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "NO.2",
                        style: FontUtils.boldItalic(
                            color: MyColor.highlightColor, size: 9.sp),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPlace() {
    return Positioned(
      left: BHLanguageMar().isRightToLeft.value ? null : Get.width / 2 + 28.w,
      right: BHLanguageMar().isRightToLeft.value ? Get.width / 2 + 26.w : null,
      bottom: 8.w,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (index == 0 && items[2].userId != null) {
                BroadcasterDetailPage.to(UserInfoModel(
                  userId: items[2].userId,
                  avatar: items[2].avatar,
                  nickname: items[2].nickname,
                ));
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                MyExtendedNetworkImage(
                  url: items[2].avatar ?? "",
                  width: 24.w,
                  height: 24.w,
                  fit: BoxFit.cover,
                  shape: BoxShape.circle,
                ),
                Image.asset(ImageAssets.rankingAvatarTop3,
                    width: 30.w, height: 33.w),
              ],
            ),
          ),
          SizedBox(
            width: 57.w,
            height: 62.w,
            child: Stack(
              children: [
                Image.asset(ImageAssets.rankingTopBg3, fit: BoxFit.cover).bh,
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 15.w,
                      ),
                      Text(
                        (items[2].nickname ?? "")
                            .truncateThan(10)
                            .fixAutoLines(),
                        maxLines: 1,
                        style: TextStyle(
                          color: MyColor.highlightColor,
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "NO.3",
                        style: FontUtils.boldItalic(
                            color: MyColor.highlightColor, size: 9.sp),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopCoupleWidget extends StatelessWidget {
  const TopCoupleWidget({Key? key, required this.items}) : super(key: key);

  final List<RankData> items;

  @override
  Widget build(BuildContext context) {
    if (items.length < 3) {
      while (items.length < 3) {
        items.add(RankData());
      }
    }

    return SizedBox(
      height: 145.w,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 第一名
          _buildFirstPlace(),
          // 第二名
          _buildSecondPlace(),
          // 第三名
          _buildThirdPlace(),

          Padding(
              padding: EdgeInsets.only(bottom: 8.w),
              child: Image.asset(
                ImageAssets.rankingTopBottom,
                width: double.infinity,
                height: 29.5.w,
                fit: BoxFit.cover,
              )),
          // Positioned(
          //   left: BHLanguageMar().isRightToLeft.value ? null : 0,
          //   right: BHLanguageMar().isRightToLeft.value ? 0 : null,
          //   bottom: 0,
          //   child: Container(
          //     height: 16.w,
          //     margin: EdgeInsets.only(left: 8.w),
          //     decoration: BoxDecoration(
          //       color: MyColor.grey4C,
          //       borderRadius: BorderRadius.circular(8.w),
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: itemTitles.map((e) {
          //         return Container(
          //           height: double.infinity,
          //           padding: EdgeInsets.symmetric(horizontal: 5.w),
          //           decoration: BoxDecoration(
          //             gradient: itemTitles[selectIndex] == e
          //                 ? MyLinearGradient.getGradient()
          //                 : null,
          //             borderRadius: BorderRadius.circular(8.w),
          //           ),
          //           child: Center(
          //             child: Text(
          //               e,
          //               style: FontUtils.boldItalic(
          //                 size: 9.w,
          //                 color: itemTitles[selectIndex] == e
          //                     ? MyColor.white
          //                     : MyColor.greyCE,
          //               ),
          //             ),
          //           ),
          //         );
          //       }).toList(),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
    //   SizedBox(
    //   height: 140.w,
    //   child: Stack(
    //     children: [
    //       Positioned(
    //         top: 5.w,
    //         left: 0,
    //         child: Image.asset(
    //           ImageAssets.rankingFireworksLeft,
    //           width: 60.w,
    //           height: 100.w,
    //           fit: BoxFit.cover,
    //         ),
    //       ),
    //       Positioned(
    //         top: 15.w,
    //         right: 0,
    //         child: Image.asset(
    //           ImageAssets.rankingFireworksRight,
    //           width: 60.w,
    //           height: 100.w,
    //           fit: BoxFit.cover,
    //         ),
    //       ),
    //       Positioned(
    //         right: 0,
    //         left: 0,
    //         top: 80.w,
    //         child: Center(
    //           child: Image.asset(
    //             ImageAssets.rankingBase,
    //             width: double.infinity,
    //             height: 67.w,
    //             fit: BoxFit.cover,
    //           ),
    //         ),
    //       ),
    //       Positioned(
    //         top: 0,
    //         left: 0,
    //         right: 0,
    //         child: _RankingTime(),
    //       ),
    //       Positioned(
    //         right: 0,
    //         left: 0,
    //         top: 40.w,
    //         child: Container(
    //           alignment: Alignment.center,
    //           child: Column(
    //             mainAxisSize: MainAxisSize.min,
    //             children: [
    //               Stack(
    //                 children: [
    //                   Padding(
    //                     padding: EdgeInsets.only(left: 30.w),
    //                     child: Stack(
    //                       alignment: Alignment.center,
    //                       children: [
    //                         Padding(
    //                           padding: EdgeInsets.only(left: 5.w),
    //                           child: MyExtendedNetworkImage(
    //                             url: item.userModel?.avatar ?? "",
    //                             width: 40.w,
    //                             height: 40.w,
    //                             fit: BoxFit.cover,
    //                             shape: BoxShape.circle,
    //                           ),
    //                         ),
    //                         Image.asset(
    //                           ImageAssets.rankingTop1,
    //                           width: 50.w,
    //                           height: 50.w,
    //                           fit: BoxFit.cover,
    //                         ),
    //                       ],
    //                     ),
    //                   ),
    //                   Padding(
    //                     padding: EdgeInsets.only(right: 30.w),
    //                     child: GestureDetector(
    //                       onTap: () {
    //                         BroadcasterDetailPage.to(UserInfoModel(
    //                           userId: item.broadcastetModel?.userId,
    //                           avatar: item.broadcastetModel?.avatar,
    //                           nickname: item.broadcastetModel?.nickname,
    //                         ));
    //                       },
    //                       child: Stack(
    //                         alignment: Alignment.center,
    //                         children: [
    //                           Padding(
    //                             padding: EdgeInsets.only(left: 5.w),
    //                             child: MyExtendedNetworkImage(
    //                               url: item.broadcastetModel?.avatar ?? "",
    //                               width: 40.w,
    //                               height: 40.w,
    //                               fit: BoxFit.cover,
    //                               shape: BoxShape.circle,
    //                             ),
    //                           ),
    //                           Image.asset(
    //                             ImageAssets.rankingTop1,
    //                             width: 50.w,
    //                             height: 50.w,
    //                             fit: BoxFit.cover,
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.center,
    //                 mainAxisSize: MainAxisSize.min,
    //                 children: [
    //                   Text(
    //                     (item.broadcastetModel?.nickname?.truncateThan(10) ??
    //                             "")
    //                         .fixAutoLines(),
    //                     style: TextStyle(
    //                       fontSize: 8.sp,
    //                       color: MyColor.black,
    //                       fontWeight: FontWeight.w600,
    //                     ),
    //                   ),
    //                   //爱心
    //                   Text(
    //                     "❤️",
    //                     style: TextStyle(
    //                       fontSize: 8.sp,
    //                     ),
    //                   ),
    //                   Text(
    //                     (item.userModel?.nickname?.truncateThan(10) ?? "")
    //                         .fixAutoLines(),
    //                     style: TextStyle(
    //                       fontSize: 8.sp,
    //                       color: MyColor.black,
    //                       fontWeight: FontWeight.w600,
    //                     ),
    //                   )
    //                 ],
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _buildFirstPlace() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 8.w,
      child: Column(
        children: [
          Container(
            width: 55.w,
            height: 38.w,
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Stack(
                      children: [
                        MyExtendedNetworkImage(
                          url: items[0].userModel?.avatar ?? "",
                          width: 29.w,
                          height: 29.w,
                          fit: BoxFit.cover,
                          shape: BoxShape.circle,
                        ),
                        Image.asset(ImageAssets.rankCouple1AvatarBg,
                            width: 30.w, height: 30.w)
                      ],
                    )),
                Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (items[0].broadcastetModel?.userId != null) {
                          BroadcasterDetailPage.to(UserInfoModel(
                            userId: items[0].broadcastetModel?.userId,
                            avatar: items[0].broadcastetModel?.avatar,
                            nickname: items[0].broadcastetModel?.nickname,
                          ));
                        }
                      },
                      child: Container(
                        color: MyColor.transparent,
                        child: Stack(
                          children: [
                            MyExtendedNetworkImage(
                              url: items[0].broadcastetModel?.avatar ?? "",
                              width: 29.w,
                              height: 29.w,
                              fit: BoxFit.cover,
                              shape: BoxShape.circle,
                            ),
                            Image.asset(ImageAssets.rankCouple1AvatarBg,
                                width: 30.w, height: 30.w)
                          ],
                        ),
                      ),
                    )),
                Positioned(
                    left: 0,
                    top: 0,
                    child: Image.asset(ImageAssets.rankCouple1AvatarLeft,
                        width: 12.w, height: 13.w)),
                Positioned(
                    right: 0,
                    top: 0,
                    child: Image.asset(ImageAssets.rankCouple1AvatarRight,
                        width: 12.w, height: 13.w)),
                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image.asset(ImageAssets.rankCoupleLove,
                        width: 14.w, height: 15.5.w)),
              ],
            ),
          ),
          SizedBox(
            width: 63.5.w,
            height: 87.5.w,
            child: Stack(
              children: [
                Image.asset(
                  ImageAssets.rankingTopBg1,
                  fit: BoxFit.cover,
                ).bh,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 20.w,
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                (items[0].broadcastetModel?.nickname ?? "--")
                                    .fixAutoLines(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 7.sp,
                                  color: MyColor.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Visibility(
                              visible: true,
                              child: Text(
                                "❤️",
                                style: TextStyle(
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                (items[0].userModel?.nickname ?? "--")
                                    .fixAutoLines(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 7.sp,
                                  color: MyColor.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        "NO.1",
                        style: FontUtils.boldItalic(
                            color: Colors.black, size: 14.sp),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondPlace() {
    return Positioned(
      right: BHLanguageMar().isRightToLeft.value ? null : Get.width / 2 + 28.w,
      left: BHLanguageMar().isRightToLeft.value ? Get.width / 2 + 27.w : null,
      bottom: 8.w,
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 28.w,
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Stack(
                      children: [
                        MyExtendedNetworkImage(
                          url: items[1].userModel?.avatar ?? "",
                          width: 21.w,
                          height: 21.w,
                          fit: BoxFit.cover,
                          shape: BoxShape.circle,
                        ),
                        Image.asset(ImageAssets.rankCouple2AvatarBg,
                            width: 22.w, height: 22.w)
                      ],
                    )),
                Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (items[1].broadcastetModel?.userId != null) {
                          BroadcasterDetailPage.to(UserInfoModel(
                            userId: items[1].broadcastetModel?.userId,
                            avatar: items[1].broadcastetModel?.avatar,
                            nickname: items[1].broadcastetModel?.nickname,
                          ));
                        }
                      },
                      child: Container(
                        color: MyColor.transparent,
                        child: Stack(
                          children: [
                            MyExtendedNetworkImage(
                              url: items[1].broadcastetModel?.avatar ?? "",
                              width: 21.w,
                              height: 21.w,
                              fit: BoxFit.cover,
                              shape: BoxShape.circle,
                            ),
                            Image.asset(ImageAssets.rankCouple2AvatarBg,
                                width: 22.w, height: 22.w)
                          ],
                        ),
                      ),
                    )),
                Positioned(
                    left: 0,
                    top: 0,
                    child: Image.asset(ImageAssets.rankCouple2AvatarLeft,
                        width: 9.w, height: 10.w)),
                Positioned(
                    right: 0,
                    top: 0,
                    child: Image.asset(ImageAssets.rankCouple2AvatarRight,
                        width: 9.w, height: 10.w)),
                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image.asset(ImageAssets.rankCoupleLove,
                        width: 12.w, height: 11.w)),
              ],
            ),
          ),
          SizedBox(
            width: 57.w,
            height: 62.w,
            child: Stack(
              children: [
                Image.asset(ImageAssets.rankingTopBg2, fit: BoxFit.cover).bh,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 15.w,
                      ),
                  Directionality(
                    textDirection: TextDirection.ltr,child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          (items[1].broadcastetModel?.nickname ?? "--")
                              .fixAutoLines(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.sp,
                            color: MyColor.highlightColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: true,
                        child: Text(
                          "❤️",
                          style: TextStyle(
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          (items[1].userModel?.nickname ?? "--")
                              .fixAutoLines(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.sp,
                            color: MyColor.highlightColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),),
                      Text(
                        "NO.2",
                        style: FontUtils.boldItalic(
                            color: MyColor.highlightColor, size: 9.sp),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThirdPlace() {
    return Positioned(
      left: BHLanguageMar().isRightToLeft.value ? null : Get.width / 2 + 28.w,
      right: BHLanguageMar().isRightToLeft.value ? Get.width / 2 + 26.w : null,
      bottom: 8.w,
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 27.w,
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Stack(
                      children: [
                        MyExtendedNetworkImage(
                          url: items[2].userModel?.avatar ?? "",
                          width: 21.w,
                          height: 21.w,
                          fit: BoxFit.cover,
                          shape: BoxShape.circle,
                        ),
                        Image.asset(ImageAssets.rankCouple3AvatarBg,
                            width: 22.w, height: 22.w)
                      ],
                    )),
                Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (items[2].broadcastetModel?.userId != null) {
                          BroadcasterDetailPage.to(UserInfoModel(
                            userId: items[2].broadcastetModel?.userId,
                            avatar: items[2].broadcastetModel?.avatar,
                            nickname: items[2].broadcastetModel?.nickname,
                          ));
                        }
                      },
                      child: Container(
                        color: MyColor.transparent,
                        child: Stack(
                          children: [
                            MyExtendedNetworkImage(
                              url: items[2].broadcastetModel?.avatar ?? "",
                              width: 21.w,
                              height: 21.w,
                              fit: BoxFit.cover,
                              shape: BoxShape.circle,
                            ),
                            Image.asset(ImageAssets.rankCouple3AvatarBg,
                                width: 22.w, height: 22.w)
                          ],
                        ),
                      ),
                    )),
                Positioned(
                    left: 0,
                    top: 0,
                    child: Image.asset(ImageAssets.rankCouple3AvatarLeft,
                        width: 9.w, height: 10.w)),
                Positioned(
                    right: 0,
                    top: 0,
                    child: Image.asset(ImageAssets.rankCouple3AvatarRight,
                        width: 9.w, height: 10.w)),
                Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Image.asset(ImageAssets.rankCoupleLove,
                        width: 12.w, height: 11.w)),
              ],
            ),
          ),
          SizedBox(
            width: 57.w,
            height: 62.w,
            child: Stack(
              children: [
                Image.asset(ImageAssets.rankingTopBg3, fit: BoxFit.cover).bh,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 15.w,
                      ),
                      Directionality(textDirection: TextDirection.ltr,child:Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        (items[2].broadcastetModel?.nickname ?? "--")
                            .fixAutoLines(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: MyColor.highlightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: true,
                      child: Text(
                        "❤️",
                        style: TextStyle(
                          fontSize: 7.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        (items[2].userModel?.nickname ?? "--")
                            .fixAutoLines(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: MyColor.highlightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )),
                      Text(
                        "NO.3",
                        style: FontUtils.boldItalic(
                            color: MyColor.highlightColor, size: 9.sp),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

