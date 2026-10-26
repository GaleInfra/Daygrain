import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/ranking/ranking_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/font_utils.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';
import 'package:untitled1/widget/status/page_status_widget.dart';

import 'logic.dart';

class RankingChildComponent extends StatefulWidget {
  const RankingChildComponent({
    super.key,
    required this.type,
    required this.onDataBack
  });

  /// 主播排行 or 个人排行
  final String type;
  final Function(List<RankingModel>) onDataBack;

  @override
  State<RankingChildComponent> createState() => _RankingChildComponentState();
}

class _RankingChildComponentState extends State<RankingChildComponent> with AutomaticKeepAliveClientMixin {
  late RankingChildLogic logic;

  @override
  void initState() {
    logic = Get.put(RankingChildLogic(), tag: widget.type);
    logic.initType(widget.type);
    if (logic.list.isNotEmpty) {
      widget.onDataBack(logic.list);
    }
    logic.onDataBack = widget.onDataBack;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageStatusWidget(
      logic: logic,
      onRefresh: logic.onRefresh,
      onRetry: logic.onRefresh,
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (ctx, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Container(),
                ),
              ];
            },
            body: Container(
              color: MyColor.appBackground2,
              padding: EdgeInsets.only(top: 5.w),
              child: GetBuilder<RankingChildLogic>(
                tag: widget.type,
                builder: (logic) {
                  final list = List.from(
                      logic.list.isEmpty ? <RankingModel>[] : logic.list);
                  for (int i = 0;i < 3;i++) {
                    if (list.isNotEmpty) {
                      list.removeAt(0);
                    }
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    padding: EdgeInsets.only(
                        right: 10.w,
                        left: 10.w,
                        top: 9.w,
                        bottom: widget.type == logic.tagList[1] ? 55.w : 9.w),
                    separatorBuilder: (ctx, index) => MyGaps.vGaps5w,
                    itemBuilder: (ctx, index) {
                      RankingModel item = list[index];
                      return _Item(
                        index: index,
                        currentUser: item.userId == logic.userId &&
                            widget.type == logic.tagList[1],
                        item: list[index],
                        onTap: () {
                          if (widget.type == "label_charm".bhTR) {
                            BroadcasterDetailPage.to(UserInfoModel(
                              userId: item.userId,
                              avatar: item.avatar,
                              nickname: item.nickname,
                            ));
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _BottomBar(
            type: widget.type,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<RankingChildLogic>(tag: widget.type);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.index,
    required this.currentUser,
    required this.item,
    this.onTap,
  }) : super(key: key);

  final int index;

  /// 当前用户在排行榜中
  final bool currentUser;

  final RankingModel item;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: currentUser ? null : MyColor.blank25,
          gradient: currentUser ? LinearGradient(
              colors: [const Color(0xff4095FF).withOpacity(0.2),const Color(0xffA2E5FF).withOpacity(0.2)],
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
                padding: EdgeInsets.only(right: BHLanguageMar().isRightToLeft.value ? 0 : 7.w, left: BHLanguageMar().isRightToLeft.value ? 7.w : 0),
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
              SizedBox(
                width: 27.w,
                height: 27.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: MyExtendedNetworkImage(
                        url: item.avatar ?? "",
                        width: 25.w,
                        height: 25.w,
                        // startReload: false,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Center(
                      child: Visibility(
                        visible: false,
                        child: Image.asset(
                          index == 0 ? ImageAssets.rankingTop2 : ImageAssets.rankingTop3,
                          width: 27.w,
                          height: 27.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              MyGaps.hGaps5w,
              Expanded(
                child: Text(
                  (item.nickname ?? "").truncateThan(10).fixAutoLines(),
                  textDirection: TextDirection.ltr,
                  textAlign: BHLanguageMar().isRightToLeft.value ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.sp,
                    color: MyColor.white,
                    fontWeight: FontWeight.w400
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    Key? key,
    required this.type,
  }) : super(key: key);

  final String type;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10.w,
      right: 0,
      left: 0,
      child: GetBuilder<RankingChildLogic>(
        tag: type,
        builder: (logic) {
          int index = logic.list.indexWhere((element) => element.userId == logic.userId);
          return Visibility(
            visible: type == logic.tagList[1],
            child: Container(
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
              child: ListTile(
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${index == -1 ? "50+" : index + 1}",
                      textDirection: TextDirection.ltr,
                      style: FontUtils.sansSemiBold(
                        color: MyColor.black,
                        size: 12.sp,
                      ),
                    ),
                  ],
                ),
                title: Row(
                  children: [
                    MyExtendedNetworkImage(
                      url: logic.userAvatar,
                      width: 25.w,
                      height: 25.w,
                      // startReload: false,
                      shape: BoxShape.circle,
                    ),
                    MyGaps.hGaps10w,
                    Expanded(
                      child: Text(
                        logic.userNickname.fixAutoLines(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 7.sp,
                          color: MyColor.black,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
