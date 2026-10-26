import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/LogHandle.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/model/video_call/video_call_result_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/broadcaster/broadcaster_detail/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/date_time_util.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/dialog/confirm_dialog.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

import '../../../../res/my_color.dart';

/// create: 2023/5/11
/// desc: 视频通话 - 评价弹窗
class EvaluateDialog extends StatefulWidget {
  EvaluateDialog.show({
    super.key,
    required this.channelName,
    required this.userInfo,
    required this.resultModel,
  }) {
    this.logHandle.initLog('call_evaluation');
    DialogUtil.showDialog(
      keepSingle: true,
      alignment: Alignment.center,
      child: this,
      onDismiss: (){
        this.logHandle.onClose();
      }
    );
  }
  LogHandle logHandle = LogHandle();
  /// 频道号
  final String channelName;

  /// 主播数据
  final UserInfoModel userInfo;

  /// 通话结果数据
  final VideoCallResultModel resultModel;

  @override
  State<EvaluateDialog> createState() => _EvaluateDialogState();
}

class _EvaluateDialogState extends State<EvaluateDialog> {
  /// 当前为一级评分弹窗
  bool firstEvaluate = true;

  /// 评分
  int score = 10086;

  /// 选中标签
  List<String> tags = [];

  final _request = Get.find<RequestRepository>();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          child: DialogBgWidget(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(11.5.w),
                        topRight: Radius.circular(11.5.w),
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF51CAFF), Color(0xFF95FFE2)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Stack(children: [
                      Positioned(
                        top: 4.w,
                        right: BHLanguageMar().isRightToLeft.value ? null : 4.w,
                        left: BHLanguageMar().isRightToLeft.value ? 4.w : null,
                        child: GestureDetector(
                          onTap: () => DialogUtil.dismiss(),
                          child: Container(
                            width: 15.w,
                            height: 15.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7.5.w),
                              color: MyColor.black.withOpacity(0.4),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close,
                                color: MyColor.white,
                                weight: 0.8,
                                size: 10.w,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.w),
                        child: Row(
                          children: [
                            MyExtendedNetworkImage(
                              url: widget.userInfo.avatarUrl ?? "",
                              width: 36.w,
                              height: 36.w,
                              fit: BoxFit.cover,
                              shape: BoxShape.circle,
                            ),
                            MyGaps.hGaps5w,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (widget.userInfo.nickname ?? "").fixAutoLines(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF2C2B29),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8.sp,
                                    ),
                                  ),
                                  Text(
                                    "${"label_callDuration".bhTR}: ${DateTimeUtil.formatDurationEva( widget.resultModel.duration ?? 0)}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFF2C2B29),
                                      fontWeight: FontWeight.w400,
                                      fontSize: 7.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ]),
                  ),
                  MyGaps.vGaps5w,
                  Padding(
                    padding: EdgeInsets.only(left: BHLanguageMar().isRightToLeft.value ? 0 : 8.5.w, right: BHLanguageMar().isRightToLeft.value ? 8.5.w : 0),
                    child: Text(
                      "Look forward to your praise！".bhTR,
                      style: TextStyle(
                        color: MyColor.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 8.sp,
                      ),
                    ),
                  ),
                  _FirstEvaluate(
                    score: score,
                    onGiveUp: () async {
                      setState(() {
                        if(score == 1) return;
        
                        score = 1;
                        firstEvaluate = false;
                        tags.clear();
                      });
                    },
                    onUnGiveUp: () {
                      setState(() {
                        if(score == 0) return;
                        score = 0;
                        firstEvaluate = false;
                        tags.clear();
                      });
                    },
                  ),
                  Visibility(
                    visible: !firstEvaluate,
                    child: _SecondEvaluate(
                      score: score,
                      resultModel: widget.resultModel,
                      selectTags: tags,
                      onSelect: (tag) {
                        if (tags.contains(tag)) {
                          tags.removeWhere((element) => element == tag);
                        } else {
                          if (tags.length == 3) {
                            Toast.showMsg("info_chooseImpressionLimit".bhTR);
                            return;
                          }
                          tags.add(tag);
                        }
                        setState(() {});
                      },
                      onSubmit: _onEvaluateSubmit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 提交评价
  Future _onEvaluateSubmit() async {
    DialogUtil.dismiss();
    await _request.evaluateSubmit(
      channelName: widget.channelName,
      score: score,
      tags: tags,
      onSuccess: (data) {
        Toast.showMsg("tip_thanks_for_comment".bhTR);
      },
      onFail: (code, msg) {},
    );
  }
}

/// 一级评分内容
class _FirstEvaluate extends StatelessWidget {
  _FirstEvaluate({
    Key? key,
    required this.onGiveUp,
    required this.onUnGiveUp,
    required this.score,
  }) : super(key: key);

  /// 点赞
  final VoidCallback onGiveUp;

  /// 点踩
  final VoidCallback onUnGiveUp;

  final int score;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 13.w),
          child: GestureDetector(
            onTap: () {
              onGiveUp();
            },
            child: Image.asset(
              score == 1 ? ImageAssets.videoCallGiveUPSelect : ImageAssets.videoCallGiveUP,
              width: 36.w,
              height: 36.w,
            ),
          ),
        ),
        SizedBox(
          width: 43.w,
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 13.w),
          child: GestureDetector(
            onTap: () {
              onUnGiveUp();
            },
            child: 
            //旋转180度
            Transform.rotate(
              angle: pi,
              child: Image.asset(
                score == 0 ? ImageAssets.videoCallGiveUPSelect : ImageAssets.videoCallGiveUP,
                width: 36.w,
                height: 36.w,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 二级评分内容
class _SecondEvaluate extends StatelessWidget {
  const _SecondEvaluate({
    Key? key,
    required this.score,
    required this.resultModel,
    required this.selectTags,
    required this.onSelect,
    required this.onSubmit,
  }) : super(key: key);

  /// 评分
  final int score;

  /// 通话结果数据
  final VideoCallResultModel resultModel;

  /// 选中的标签
  final List<String> selectTags;

  /// 选中
  final Function(String tag) onSelect;

  /// 提交
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    List<String> tags = [];
    if (score == 0) {
      // 差评
      tags.addAll(resultModel.badTagList ?? []);
    } else {
      tags.addAll(resultModel.tagList ?? []);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyGaps.vGaps5w,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.5.w),
          child: Text(
            "label_impression".bhTR,
            style: TextStyle(
              color: MyColor.white,
              fontWeight: FontWeight.w500,
              fontSize: 8.sp,
            ),
          ),
        ),
        MyGaps.vGaps5w,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.5.w),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            alignment: WrapAlignment.start,
            spacing: 5.w,
            children: tags.map((e) {
              final isSelect = selectTags.contains(e);
              return GestureDetector(
                onTap: () => onSelect.call(e),
                child: Container(
                  margin: EdgeInsets.only(bottom: 5.w),
                  constraints: BoxConstraints(minHeight: 14.w),
                  padding:  const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.5.w),
                    gradient: isSelect
                        ? const LinearGradient(
                            colors: MyColor.btnGradientColors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                  ),
                  child: Container(
                    
                    key: ValueKey(e),
                    padding: EdgeInsets.symmetric(horizontal: 4.5.w, vertical: 3.w),
                    decoration: BoxDecoration(
                      color: isSelect ? Color(0xFF3B3B3B) : const Color(0xFF454442),
                      borderRadius: BorderRadius.circular(4.5.w),
                    ),
                    child: Text(
                      e.bhTR,
                      style: TextStyle(
                        color: isSelect ? Color(0xFF0AF4D7) : MyColor.white,
                        fontSize: 5.sp,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        MyGaps.vGaps5w,
        Container(
          // padding: EdgeInsets.only(left: .3.w, top: .5.w),
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            // color: MyColor.white,
            borderRadius: BorderRadius.circular(13.w),
          ),
          child: MyGradientButton(
            text: "action_next".bhTR,
            height: 24.w,
            borderRadius: BorderRadius.circular(13.w),
            gradientColor: selectTags.isNotEmpty ? MyColor.btnGradientColors : [MyColor.grey909090, MyColor.greyC0C0C0],
            onTap: selectTags.isEmpty ? null : onSubmit,
          ),
        ),
        MyGaps.vGaps10w,
      ],
    );
  }
}
