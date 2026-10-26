import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/pages/video_call/video_call/logic.dart';
import 'package:untitled1/pages/video_call/video_call/widget/video_call_input_widget.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

import '../../../../model/video_call/on_chat_model.dart';

/// create: 2023/5/9
/// desc: 视频通话消息列表
class VideoCallMessageWidget extends StatefulWidget {
  const VideoCallMessageWidget({Key? key}) : super(key: key);

  @override
  State<VideoCallMessageWidget> createState() => _VideoCallMessageWidgetState();
}

class _VideoCallMessageWidgetState extends State<VideoCallMessageWidget> {
  final logic = Get.find<VideoCallLogic>();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: BHLanguageMar().isRightToLeft.value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
            width: MediaQuery.of(context).size.width * .8,
            height: MediaQuery.of(context).size.height / 2 - 50.w,
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.w),
            child: GetBuilder<VideoCallLogic>(
              builder: (logic) {
                return NotificationListener(
                  onNotification: (notification) {
                    // //是否点击
                    // if (notification is ScrollMetricsNotification) {
                    //   if (notification.metrics.atEdge) {
                    //     VideoCallInputWidget.myGlobalKey.currentState?.onCloseAll(unFocus: true);
                    //   }
                    // }
                    return true;
                  },
                  child: ListView.separated(
                    addAutomaticKeepAlives: false,
                    shrinkWrap: true,
                    cacheExtent: 300,
                    controller: logic.messageController,
                    physics: const ClampingScrollPhysics(),
                    reverse: true,
                    itemCount: logic.messageList.length,
                    separatorBuilder: (_, __) => MyGaps.vGaps10w,
                    itemBuilder: (ctx, index) {
                      bool me = logic.messageList[index].fromUserId == logic.userId;
                      OnChatModel item = logic.messageList[index];
                      return _Item(
                        avatar: me ? (logic.appConfig.userInfo.avatarUrl ?? "") : (logic.userInfo?.avatarUrl ?? ""),
                        message: item.content ?? "",
                        giftImage: item.giftImage,
                        translate: item.translate,
                      );
                    },
                  ),
                );
              },
            ),
          ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.avatar,
    required this.message,
    required this.giftImage,
    required this.translate,
  }) : super(key: key);

  final String avatar;

  final String message;

  /// 翻译内容
  final String? translate;

  /// 系统代替发送的礼物图片
  final String? giftImage;

  @override
  Widget build(BuildContext context) {
    String msg = message;
    if (giftImage != null) {
      msg = msg.substring(0, msg.indexOf("%#"));
      msg = msg.replaceAll("I send your a", "I send your a".bhTR);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(1.5.w),
          constraints: BoxConstraints(
             maxWidth: (MediaQuery.of(context).size.width * .8 ) - 20.w,
          ),
          decoration: BoxDecoration(
              color: MyColor.black.withOpacity(.2),
              borderRadius: BorderRadius.circular(10.w),
            ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyExtendedNetworkImage(
                url: avatar,
                width: 13.w,
                height: 13.w,
                shape: BoxShape.circle,
                fit: BoxFit.cover,
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.w),
                  child: Column(
                    // html 渲染器下 WidgetSpan 行高偶发撑开；译文用 Row，Column 按内容收缩。
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Container(
                              padding: translate != null
                                  ? EdgeInsets.only(bottom: 3.w)
                                  : null,
                              margin: translate != null
                                  ? EdgeInsets.only(bottom: 3.w)
                                  : null,
                              decoration: translate != null
                                  ? BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: MyColor.greyCECECE,
                                              width: .5.w)),
                                    )
                                  : null,
                              child: Text(
                                msg,
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 6.sp,
                                ),
                              ),
                            ),
                          ),
                          if (giftImage != null && giftImage!.isNotEmpty)
                            Image.asset(
                              giftImage!,
                              width: 12.w,
                              height: 12.w,
                            ),
                        ],
                      ),
                      if (translate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 3.w),
                              child: Icon(
                                Icons.check_circle,
                                color: MyColor.greyCECECE,
                                size: 6.sp,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                translate ?? "",
                                style: TextStyle(
                                  color: MyColor.greyCECECE,
                                  fontSize: 6.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
