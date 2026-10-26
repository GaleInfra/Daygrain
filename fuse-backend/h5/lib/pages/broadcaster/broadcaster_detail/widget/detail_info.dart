
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/extension/my_extension.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/online_status_widget.dart';

import '../logic.dart';

/// create: 2023/4/25
/// desc: 主播个人信息
class DetailInfo extends StatelessWidget {
  DetailInfo({
    Key? key,
    required this.tagUserId,
  }) : super(key: key);

  final String tagUserId;

  final appConfig = Get.find<AppConfigManager>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 7.5.w, right: 7.5.w, bottom: 9.w),
      child: GetBuilder<BroadcasterDetailLogic>(
        tag: tagUserId,
        builder: (logic) {
          var countryText = logic.userInfo?.country ?? "";
          if (appConfig.nameByEmoji.containsKey(countryText)) {
            countryText = "${appConfig.nameByEmoji[countryText]}$countryText";
          } else if (appConfig.codeByEmoji.containsKey(countryText)) {
            countryText = "${appConfig.codeByEmoji[countryText]}$countryText";
          }

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Obx(() => Visibility(
                            visible: !appConfig.isReviewPkg.value,
                            child: OnlineStatusWidget(
                              width: 6.w,
                              height: 6.w,
                              status: logic.onlineStatus.value,
                            ),
                          )),
                      Obx(() => Visibility(
                            visible: !appConfig.isReviewPkg.value,
                            child: MyGaps.hGaps3w,
                          )),
                      Expanded(
                        child: Text(
                          (logic.userInfo?.nickname ?? "").fixAutoLines(),
                          textDirection: TextDirection.ltr,
                          textAlign: BHLanguageMar().isRightToLeft.value
                              ? TextAlign.right
                              : TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      MyGaps.hGaps50w,
                    ],
                  ),
                  MyGaps.vGaps3w,
                  Row(
                    children: [
                      Visibility(
                        visible: !appConfig.isReviewPkg.value,
                        child: SizedBox(
                          width: 7.w,
                        ),
                      ),
                      Expanded(
                          child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              countryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MyColor.white,
                                fontSize: 7.5.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          Text(
                            " | ",
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 7.5.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            "${logic.userInfo?.age}",
                            maxLines: 1,
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 7.5.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ))
                      // AgeCountryRowWidget(
                      //   age: "${logic.userInfo?.age ?? 0}",
                      //   country: (logic.userInfo?.country ?? ""),
                      //   countryMaxLength: 20,
                      // )
                    ],
                  ),
                  Visibility(
                    visible: logic.userInfo?.about?.isNotEmpty ?? false,
                    child: MyGaps.vGaps3w,
                  ),
                  Visibility(
                    visible: logic.userInfo?.about?.isNotEmpty ?? false,
                    child: AutoSizeText(
                      logic.userInfo?.about?.trimRight() ?? "",
                      style: TextStyle(
                        color: MyColor.gray7c,
                        fontSize: 6.sp,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              
            ],
          );
        },
      ),
    );
  }
}
