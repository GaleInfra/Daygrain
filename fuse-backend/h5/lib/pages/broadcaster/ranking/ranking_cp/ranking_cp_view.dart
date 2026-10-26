import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/ranking/rank_cp_model.dart';
import 'package:untitled1/utils/font_utils.dart';

import '../../../../model/user/user_info_model.dart';
import '../../../../res/image_assets.dart';
import '../../../../res/my_color.dart';
import '../../../../res/my_gaps.dart';
import '../../../../widget/image/my_extended_network_image.dart';
import '../../../../widget/status/page_status_widget.dart';
import '../../broadcaster_detail/view.dart';
import 'ranking_cp_logic.dart';

import 'package:intl/intl.dart' as intl;

/// create: 2024/3/27
/// desc: CP榜
class RankCpView extends StatelessWidget {
  RankCpView({super.key,required this.onDataBack});
  final Function(List<RankData>) onDataBack;
  final RankingCpLogic logic = Get.put(RankingCpLogic());
  @override
  Widget build(BuildContext context) {
    logic.onDataBack = onDataBack;
    return GetBuilder<RankingCpLogic>(builder: (logic) {

      final list = (logic.cpModel?.rankData?.isEmpty ?? true)
          ? <RankData>[]
          : logic.cpModel!.rankData!;

      for (int i = 0;i < 3;i++) {
        if (list.isNotEmpty) {
          list.removeAt(0);
        }
      }

      return PageStatusWidget(
        logic: logic,
        onRefresh: logic.onGetCpList,
        onRetry: logic.onGetCpList,
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (ctx, innerBoxIsScrolled) {
                List<RankData> items = [];
                if (logic.cpModel?.rankData?.isNotEmpty ?? false) {
                  items = logic.cpModel!.rankData!;
                }
                return [
                  SliverToBoxAdapter(
                    child: Container(),
                  ),
                ];
              },
              body: Container(
                color: MyColor.appBackground2,
                padding: EdgeInsets.only(top: 5.w),
                child: ListView.separated(
                  itemCount: list.length,
                  padding: EdgeInsets.only(
                      right: 10.w, left: 10.w, top: 9.w, bottom: 55.w),
                  separatorBuilder: (ctx, index) => MyGaps.vGaps5w,
                  itemBuilder: (ctx, index) {
                    return _Item(
                      index: index,
                      item: list[index],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 10.w,
              right: 0,
              left: 0,
              child: _bottom(),
            ),
          ],
        ),
      );
    });
  }

  Widget _bottom() {
    RankData rankData = RankData();
    var list = logic.cpModel?.rankData
            ?.where((element) =>
                element.userModel?.userId ==
                Get.find<AppConfigManager>().userInfo.userId)
            .toList() ??
        [];
    if (list.isNotEmpty) {
      // 如果排行中有自己的数据，则筛除消费最多的
      list.sort((a, b) => (b.sort ?? 0).compareTo((a.sort ?? 0)));
      rankData = list.first;
    }
    String sort = "${rankData.sort ?? "50+"}";
    return Container(
      width: double.infinity,
      height: 38.5.w,
      margin: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        gradient:  LinearGradient(
            colors: MyColor.messageBGs,
            begin: BHLanguageMar().isRightToLeft.value ? Alignment.centerLeft : Alignment.centerRight,
            end: BHLanguageMar().isRightToLeft.value ? Alignment.centerRight : Alignment.centerLeft
        ),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 8.w,),
          Text(
            sort,
            textDirection: TextDirection.ltr,
            style: FontUtils.sansSemiBold(
              color: MyColor.black,
              size: 12.sp,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 15.w),
                      child: Center(
                        child: MyExtendedNetworkImage(
                          url: Get.find<AppConfigManager>()
                                  .userInfo
                                  .avatarThumbUrl ??
                              "",
                          width: 25.w,
                          height: 25.w,
                          // startReload: false,
                          fit: BoxFit.cover,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: true,
                      child: Padding(
                        padding: EdgeInsets.only(right: 15.w),
                        child: GestureDetector(
                          onTap: () {
                            if (rankData.broadcastetModel == null) {
                              return;
                            }
                            BroadcasterDetailPage.to(UserInfoModel(
                              userId: rankData.broadcastetModel?.userId,
                              avatar: rankData.broadcastetModel?.avatar,
                              nickname: rankData.broadcastetModel?.nickname,
                            ));
                          },
                          child: Center(
                            child: MyExtendedNetworkImage(
                              url: rankData.broadcastetModel?.avatar ?? "",
                              width: 25.w,
                              height: 25.w,
                              // startReload: false,
                              fit: BoxFit.cover,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                MyGaps.hGaps5w,
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          (rankData.broadcastetModel?.nickname ?? "--")
                              .fixAutoLines(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.sp,
                            color: MyColor.black,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: true,
                        child: Text(
                          "❤️",
                          style: TextStyle(
                            fontSize: 7.sp,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          (Get.find<AppConfigManager>().userInfo.nickname ?? "--")
                              .fixAutoLines(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7.sp,
                            color: MyColor.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.index,
    required this.item,
  }) : super(key: key);

  final int index;

  final RankData item;

  @override
  Widget build(BuildContext context) {
    bool currentUser = false;
    if (Get.find<AppConfigManager>().userInfo.userId ==
        item.userModel?.userId) {
      currentUser = true;
    }
    return Container(
      decoration: BoxDecoration(
        color: currentUser ? null : MyColor.blank25,
        gradient: currentUser ? LinearGradient(
            colors: const [Color(0x334095FF), Color(0x33A2E5FF)],
            begin: BHLanguageMar().isRightToLeft.value ? Alignment.centerLeft : Alignment.centerRight,
            end: BHLanguageMar().isRightToLeft.value ? Alignment.centerRight : Alignment.centerLeft
        ) : null,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  (index + 4).toString().padLeft(2, '0'),
                  style: FontUtils.sansSemiBold(
                    color: MyColor.grey85,
                    size: 12.sp,
                  ),
                ),
              )
          ],
        ),
        horizontalTitleGap: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 15.w),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: MyExtendedNetworkImage(
                          url: item.userModel?.avatar ?? "",
                          width: 25.w,
                          height: 25.w,
                          // startReload: false,
                          fit: BoxFit.cover,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Center(
                        child: Visibility(
                          visible: false,
                          child: Image.asset(
                            index == 0
                                ? ImageAssets.rankingTop2
                                : ImageAssets.rankingTop3,
                            width: 27.w,
                            height: 27.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 15.w),
                  child: GestureDetector(
                    onTap: () {
                      BroadcasterDetailPage.to(UserInfoModel(
                        userId: item.broadcastetModel?.userId,
                        avatar: item.broadcastetModel?.avatar,
                        nickname: item.broadcastetModel?.nickname,
                      ));
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: MyExtendedNetworkImage(
                            url: item.broadcastetModel?.avatar ?? "",
                            width: 25.w,
                            height: 25.w,
                            // startReload: false,
                            fit: BoxFit.cover,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Center(
                          child: Visibility(
                            visible: false,
                            child: Image.asset(
                              index == 0
                                  ? ImageAssets.rankingTop2
                                  : ImageAssets.rankingTop3,
                              width: 27.w,
                              height: 27.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            MyGaps.hGaps5w,
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: BHLanguageMar().isRightToLeft.value
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        (item.broadcastetModel?.nickname ?? "").fixAutoLines(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: MyColor.white,
                        ),
                      ),
                    ),
                    Text(
                      "❤️",
                      style: TextStyle(
                        fontSize: 7.sp,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        (item.userModel?.nickname ?? "").fixAutoLines(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: MyColor.white,
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
    );
  }
}



/// 顶部时间
class _RankingTime extends StatelessWidget {
  _RankingTime({Key? key}) : super(key: key);

  final formatter = intl.DateFormat('MMMM', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: MyColor.white.withOpacity(.3),
          borderRadius: BorderRadius.circular(9.w),
        ),
        child: Text(
          "Rank of ${formatter.format(DateTime.now())}",
          style: TextStyle(
            fontSize: 6.sp,
            color: MyColor.white,
          ),
        ),
      ),
    );
  }
}
