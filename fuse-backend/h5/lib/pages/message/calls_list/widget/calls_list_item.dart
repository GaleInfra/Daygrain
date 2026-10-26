
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/database/dao/video_call_dao.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/video_call_data.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../res/my_color.dart';
import '../../../../res/my_gaps.dart';
import '../../../../utils/date_time_util.dart';
import '../../../../widget/image/my_extended_network_image.dart';

/// create: 2023/4/27
/// desc: 通话列表item
class CallsListItem extends StatefulWidget {
  const CallsListItem({
    Key? key,
    required this.dao,
  }) : super(key: key);

  /// 本地通话记录
  final VideoCallDao dao;

  @override
  State<CallsListItem> createState() => _CallsListItemState();
}

class _CallsListItemState extends State<CallsListItem> {
  //状态
  // final userStatus = kOffline.obs;
  // StreamSubscription? _userStateEvent;

  @override
  void initState() {
    super.initState();
  }

  //监听显示隐藏
  void onVisibilityChanged(VisibilityInfo info) {
   
  }

  @override
  void dispose() {
    // removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey("calls_list_item_${widget.dao.id}"),
      onVisibilityChanged: onVisibilityChanged,
      child: GestureDetector(
        onTap: () => BroadcasterDetailPage.to(UserInfoModel(
          userId: widget.dao.userId,
          nickname: widget.dao.nickname,
          avatar: widget.dao.avatar,
        )),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 42.5.w,
              padding: EdgeInsets.only(left: 7.w ,right: 7.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: MyExtendedNetworkImage(
                      url: widget.dao.avatar ?? "",
                      width: 24.w,
                      height: 24.w,
                      fit: BoxFit.cover,
                      shape: BoxShape.circle,
                    ),
                  ),
                  MyGaps.hGaps5w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (widget.dao.nickname ?? "").fixAutoLines(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                        MyGaps.vGaps2w,
                        Row(
                          children: [
                            Text(
                              "${widget.dao.callType ?? ""} Call".bhTR,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    widget.dao.callType == VideoCallType.outgoing ||
                                            widget.dao.callType ==
                                                VideoCallType.incoming
                                        ? MyColor.grey7C7C7C
                                        : MyColor.pinkFE3E69,
                                fontSize: 8.sp,
                              ),
                            ),
                            MyGaps.hGaps5w,
                            // 添加匹配标识
                            if (widget.dao.isFromMatch == true)
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //       horizontal: 2.w, vertical: 1.w),
                              //   decoration: BoxDecoration(
                              //     color: Colors.blueAccent.withOpacity(0.3),
                              //     borderRadius: BorderRadius.circular(2.w),
                              //   ),
                              //   child: Text(
                              //     "匹配",
                              //     style: TextStyle(
                              //       color: Colors.white,
                              //       fontSize: 4.sp,
                              //     ),
                              //   ),
                              // ),
                              if (widget.dao.isFromMatch == true)
                                MyGaps.hGaps5w,
                            Visibility(
                              visible: widget.dao.duration != 0,
                              child: Text(
                                DateTimeUtil.formatDuration(Duration(
                                    milliseconds: widget.dao.duration ?? 0)),
                                style: TextStyle(
                                  color: MyColor.grey7C7C7C,
                                  fontSize: 8.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  MyGaps.hGaps5w,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateTimeUtil.timeFormat(widget.dao.endTime ?? 0),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 6.5.sp,
                        ),
                      ),
                      MyGaps.vGaps2w,
                      Image.asset(
                        widget.dao.callType == VideoCallType.outgoing ||
                                widget.dao.callType == VideoCallType.incoming
                            ? ImageAssets.iconCallTypeConnect
                            : ImageAssets.iconCallTypeReject,
                        width: 10.w,
                        height: 10.w,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
