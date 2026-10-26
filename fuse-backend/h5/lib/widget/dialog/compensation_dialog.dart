import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';

// 用于判断异常补偿弹窗是否存在
bool kCompensationShowing = false;

Future showCompensationDialog(String text) {
  kCompensationShowing = true;
  return SmartDialog.show(
    tag: "CompensationDialog",
    bindPage: false,
    keepSingle: true,
    permanent: true,
    clickMaskDismiss: true,
    backDismiss: true,
    onDismiss: () {
      kCompensationShowing = false;
    },
    builder: (ctx) => _CompensationDialog(text: text),
  );
}

Future dismissCompensationDialog() async {
  await SmartDialog.dismiss(tag: "CompensationDialog", force: true);
  kCompensationShowing = false;
}

/// create: 2024/1/12
/// desc: 异常通话补偿
class _CompensationDialog extends StatefulWidget {
  const _CompensationDialog({
    required this.text,
  });

  final String text;

  @override
  State<_CompensationDialog> createState() => _CompensationDialogState();
}

class _CompensationDialogState extends State<_CompensationDialog> {
  String firstPart = ''; // 前半部分
  String numberPart = ""; // 数字
  String secondPart = ""; // 后半部分

  @override
  void initState() {
    RegExp regExp = RegExp(r'(\D+)(\d+)(\D+)'); // 定义一个匹配字符串中的数字的正则表达式
    RegExpMatch? match = regExp.firstMatch(widget.text); // 在原始字符串中查找第一个匹配的数字

    if (match != null) {
      firstPart = match.group(1) ?? ""; // 获取第一部分
      numberPart = match.group(2) ?? ""; // 获取数字部分
      secondPart = match.group(3) ?? ""; // 获取第三部分
      setState(() {});
    }
    //字符串拆分成数组
    List<String> list = "tip_call_compensation".bhTR.split("####");
    if (list.length == 2) {
      firstPart = list[0];
      secondPart = list[1];
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 13.w),
        decoration: BoxDecoration(
          color: MyColor.grey373634,
          borderRadius: BorderRadius.circular(16.w),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32.w,
              alignment: Alignment.center,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  MyColor.btnGradientColors2[4],
                  MyColor.btnGradientColors2[3],
                ]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.w),
                  topRight: Radius.circular(16.w),
                ),
              ),
              child: Text(
                "label_compensation".bhTR,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: MyColor.otherMessageBG,
                  fontWeight: FontWeight.bold,
                  fontFamily: "GillSans-BoldItalic",
                ),
              ),
            ),
            MyGaps.vGaps5w,
            Image.asset(
              ImageAssets.coinsStore1,
              width: 47.w,
              height: 47.w,
            ),
            MyGaps.vGaps5w,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "$firstPart$numberPart ",
                  style: TextStyle(
                    fontSize: 7.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                  children: [
                    WidgetSpan(
                      child: Image.asset(
                        ImageAssets.broadcasterDiamondSmall,
                        width: 9.w,
                        height: 7.w,
                      ),
                    ),
                    TextSpan(
                      text: secondPart,
                      style: TextStyle(
                        fontSize: 7.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            MyGaps.vGaps10w,
            MyGradientButton(
              width: 119.w,
              text: "action_gotIt".bhTR,
              onTap: () => dismissCompensationDialog(),
            ),
            MyGaps.vGaps12w,
          ],
        ),
      ),
    );
  }
}
