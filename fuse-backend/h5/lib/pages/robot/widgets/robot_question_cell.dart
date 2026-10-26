import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/robot/RobotModel.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/widget/my_gradient_text.dart';

class RobotQuestionCell extends StatelessWidget {
  final RobotCQModel model;
  final Function(FaqInfoList) onQuestionTap;
  final Function(String) onTranslate;

  final appConfig = Get.find<AppConfigManager>();
   RobotQuestionCell({super.key,
    required this.model,
    required this.onQuestionTap,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8.w),
          Container(
            width: 27.w,
            height: 27.w,
            alignment: Alignment.center,
            decoration:  BoxDecoration(
              shape: BoxShape.circle,
              color: MyColor.otherMessageBG,
            ),
            child: Image.asset(
              ImageAssets.customServiceIcon,
              width: 20.w,
              height: 20.w,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: MyColor.otherMessageBG,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.faqModel?.content ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7.sp,
                        ),
                      ),
                      ...buildQuestionList(),
                      if (model.tranString != null) buildTranslation(),

                    ],
                  ),
                ),
                if (!appConfig.autoTranslate.value && model.tranString == null)
                  buildTranslateButton(),
              ],
            ),
          ),
          SizedBox(width: 24.w),
        ],
      ),
    );
  }

  List<Widget> buildQuestionList() {
    return model.faqModel?.faqInfoList?.map((question) {
      return GestureDetector(
        onTap: () => onQuestionTap(question),
        child: Container(
          margin: EdgeInsets.only(top: 5.h),
          child: Text(
            question.question ?? '',
            style: TextStyle(
              color: const Color(0xffEFF04E),
              fontSize: 7.sp,
            ),
          ),
        ),
      );
    }).toList() ?? [];
  }

  Widget buildTranslation() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 5.h),
          height: 1,
          color: const Color(0xff7C7C7C).withOpacity(0.5),
        ),
        Text(
          model.tranString!,
          style: TextStyle(
            color: Colors.white,
            fontSize: 6.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildTranslateButton() {
    return GestureDetector(

      onTap: () {
        var content = model.faqModel?.content ?? '';
        for (var element in model.faqModel?.faqInfoList ?? []) {
          content = "$content\n" + element.question ?? '';
        }

        onTranslate(content);
      },


      child: Container(
        margin: EdgeInsets.only(top: 2.5.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              model.isTraning == 1
                  ? ImageAssets.messageTranslateReload
                  : ImageAssets.messageTranslate,
              width: 8.w,
              height: 8.w,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 3.w),
            MyGradientText(
              colors: const [
                MyColor.highlightColor,
                MyColor.highlightColor,
              ],
              text: model.isTraning == 1
                  ? "Translating".bhTR
                  : "action_clickToTranslate".bhTR,
              style: const TextStyle(
                color: MyColor.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 