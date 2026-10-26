import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/robot/RobotModel.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/widget/my_gradient_text.dart';

class RobotAnswerCell extends StatelessWidget {
  final RobotCQModel model;
  final Function(AnswerEventHandleList) onAnswerTap;
  final Function(String) onTranslate;
  final Function(String) onExample;
  final Function() helpClick;
  final appConfig = Get.find<AppConfigManager>();

  RobotAnswerCell({
    super.key,
    required this.model,
    required this.onAnswerTap,
    required this.onTranslate,
    required this.onExample,
    required this.helpClick,
  });

  @override
  Widget build(BuildContext context) {
    final text = model.questionModel?.messageAnswer?.content ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8.w),
          Container(
            width: 27.w,
            height: 27.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xff515151),
            ),
            child: Image.asset(
              ImageAssets.customServiceIcon,
              width: 21.w,
              height: 21.w,
            ),
          ),
          SizedBox(width: 7.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff515151),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildRichText(text),
                      if (model.questionModel?.isViewExample == true)
                        buildExampleButton(),
                      buildHelpButtons(),
                      if (model.tranString != null) buildTranslation()
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                if (!appConfig.autoTranslate.value && model.tranString == null) buildTranslateButton()
              ]
            ),
          ),
          SizedBox(width: 21.w),
        ],
      ),
    );
  }

  Widget buildRichText(String text) {
    final textSpans = <TextSpan>[];
    var currentIndex = 0;

    model.questionModel?.messageAnswer?.answerEventHandleList
        ?.forEach((handleModel) {
      if (handleModel.matchStr != null) {
        final matchIndex = text.indexOf(handleModel.matchStr!, currentIndex);
        if (matchIndex != -1) {
          // Add text before match
          if (matchIndex > currentIndex) {
            textSpans.add(TextSpan(
              text: text.substring(currentIndex, matchIndex),
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.sp,
              ),
            ));
          }

          // Add clickable match
          textSpans.add(TextSpan(
            text: handleModel.matchStr,
            style: TextStyle(
              color: const Color(0xffEFF04E),
              fontSize: 7.sp,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onAnswerTap(handleModel),
          ));

          currentIndex = matchIndex + handleModel.matchStr!.length;
        }
      }
    });

    // Add remaining text
    if (currentIndex < text.length) {
      textSpans.add(TextSpan(
        text: text.substring(currentIndex),
        style: TextStyle(
          color: Colors.white,
          fontSize: 7.sp,
        ),
      ));
    }

    return Padding(
      padding: EdgeInsets.all(5.w),
      child: RichText(text: TextSpan(children: textSpans)),
    );
  }

  Widget buildExampleButton() {
    return GestureDetector(
      onTap: () => onExample(model.questionModel?.imageUrl ?? ''),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.5.h),
        child: Text(
          'VIEW EXAMPLE'.bhTR,
          style: TextStyle(
            color: const Color(0xffEFF04E),
            fontSize: 7.sp,
          ),
        ),
      ),
    );
  }

  Widget buildHelpButtons() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xff979797).withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HelpButton(
              isSelected: model.isHelp == true,
              text: 'Helpful'.bhTR,
              icon: model.isHelp == true ? ImageAssets.robotHelpSel : ImageAssets.robotHelpNor,
              onTap: () {
                if (model.isHelp == null) {

                  model.isHelp = true;

                  helpClick();
                }

              },
            ),
          ),
          Container(
            width: 1,
            height: 22.h,
            color: const Color(0xff979797).withOpacity(0.15),
          ),
          Expanded(
            child: _HelpButton(
              isSelected: model.isHelp == false,
              text: 'Unhelpful'.bhTR,
              icon: model.isHelp == false ? ImageAssets.robotNoHelpSel : ImageAssets.robotNoHelpNor,
              onTap: () {
                /* 处理点击 */
                if (model.isHelp == null) {

                  model.isHelp = false;
                  helpClick();
                }

              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTranslation() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          height: 1,
          color: const Color(0xff979797),
        ),
        Padding(
          padding: EdgeInsets.all(5.w),
          child: Text(
            model.tranString!,
            style: TextStyle(
              color: Colors.white,
              fontSize: 6.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTranslateButton() {
    return GestureDetector(
      onTap: () =>
          onTranslate(model.questionModel?.messageAnswer?.content ?? ''),
      child: Container(
        margin: EdgeInsets.only(left: 5.w, bottom: 2.5.h),
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

class _HelpButton extends StatelessWidget {
  final bool isSelected;
  final String text;
  final String icon;
  final VoidCallback onTap;

  const _HelpButton({
    required this.isSelected,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 22.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: 12.w,
              height: 12.w,
            ),
            SizedBox(width: 2.5.w),
            Text(
              text,
              style: TextStyle(
                color: MyColor.white,
                fontSize: 6.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
