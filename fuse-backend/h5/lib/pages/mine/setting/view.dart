import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/dialog/privacy_mode_dialog.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';

import '../../../widget/app_bar/default_app_bar.dart';
import 'logic.dart';

/// 设置页
class SettingPage extends StatelessWidget {
  final logic = Get.find<SettingLogic>();
  final appConfig = Get.find<AppConfigManager>();

  SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Scaffold(
        key: logic.pageKay,
        appBar: DefaultAppBar(title: "title_settings".bhTR),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // // SizedBox(height: 18.w),
              // Center(
              //   child:ClipRRect(
              //     borderRadius: BorderRadius.circular(10.w),
              //     child:  Image.asset(
              //       ImageAssets.logo,
              //       width: 58.w,
              //       height: 58.w,
              //     ),
              //   ),
              // ),
              // MyGaps.vGaps5w,
              // Center(
              //   child: Text(
              //     Constant.appName,
              //     style: TextStyle(
              //       color: MyColor.white,
              //       fontSize: 9.sp,
              //       fontWeight: FontWeight.w700,
              //     ),
              //   ),
              // ),
              MyGaps.vGaps8w,
              GetBuilder<AppConfigManager>(
                builder: (appConfig) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
                    padding: EdgeInsets.all(6.w),
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF26203A),
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "ID: ${appConfig.userInfo.userId}",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: MyColor.btnGradientColors2,
                              ),
                              borderRadius: BorderRadius.circular(7.w),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.w,
                            ),
                            child: Text(
                              "action_Copy".bhTR,
                              style: TextStyle(
                                color: MyColor.white,
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          onTap: () => logic.onCopy(appConfig.userInfo.userId ?? ""),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // MyGaps.hLine,
              Obx(() {
                return _SwitchItem(
                  title: "label_autoTranslate".bhTR,
                  check: appConfig.autoTranslate.value,
                  onCheck: () => logic.onChangeAutoTranslate(),
                );
              }),
              // MyGaps.hLine,
              GetBuilder<AppConfigManager>(
                builder: (logic) {
                  return _SwitchItem(
                    title: "function_doNotDisturbMessage".bhTR,
                    check: logic.userInfo.isSwitchNotDisturbIm ?? false,
                    onCheck: () => logic.onSwitchDisturb(
                      bindWidget: context,
                      isSwitchNotDisturbIm: !(logic.userInfo.isSwitchNotDisturbIm ?? false),
                    ),
                  );
                },
              ),
              // MyGaps.hLine,
              GetBuilder<AppConfigManager>(
                builder: (logic) {
                  return _SwitchItem(
                    title: "function_doNotDisturbCall".bhTR,
                    check: logic.userInfo.isSwitchNotDisturbCall ?? false,
                    onCheck: () => logic.onSwitchDisturb(
                      bindWidget: context,
                      isSwitchNotDisturbCall: !(logic.userInfo.isSwitchNotDisturbCall ?? false),
                    ),
                  );
                },
              ),
              // MyGaps.hLine,
              buildSettingItem(
                title: "label_language".bhTR,
                value: BHLanguageMar().currentLangName,
                onTap: () => logic.onLanguageSelect(),
              ),
              
              buildSettingItem(
                title: "privacy_Modify".bhTR,
                value: "",
                onTap: () => showPrivacyModeDialog(context),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: Get.width - 68.w,
                child: MyGradientButton(
                  text: "action_logout".bhTR,
                  onTap: logic.onLogout,
                ),
              ),
              SizedBox(
                height: 3.w,
              ),
              InkWell(
                onTap: logic.onDelAccountFirstConfirm,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.w, horizontal: 10.w),
                  child: Text(
                    "action_deleteAccount".bhTR,
                    style: TextStyle(
                      color: const Color(0xFFFF5757),
                      fontSize: 8.sp,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w700,
                      decorationColor: const Color(0xFFFF5757),
                    ),
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

Widget buildSettingItem({required String title, required String value, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.translucent,
    child: Container(
      alignment: Alignment.centerLeft,
      width: double.infinity,
      margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
      padding: EdgeInsets.all(6.w),
      height: 32.w,
      decoration: BoxDecoration(
        color:const Color(0xFF26203A),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: MyColor.white,
                fontSize: 7.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          MyGaps.hGaps5w,
          Text(
            value,
            style: TextStyle(
              color: MyColor.white,
              fontSize: 7.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          MyGaps.hGaps5w,
          Icon(
            Icons.arrow_forward_ios,
            color: MyColor.white,
            size: 8.w,
          ),
        ],
      ),
    ),
  );
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    Key? key,
    required this.title,
    required this.check,
    required this.onCheck,
  }) : super(key: key);

  final String title;

  final bool check;

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      width: double.infinity,
      margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
      padding: EdgeInsets.all(6.w),
      height: 32.w,
      decoration: BoxDecoration(
        color:const Color(0xFF26203A),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: MyColor.white,
                fontSize: 7.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          MyGaps.hGaps5w,
          _Switch(
            check: check,
            onCheck: onCheck,
          ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    Key? key,
    required this.check,
    required this.onCheck,
  }) : super(key: key);

  final bool check;

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCheck,
      behavior: HitTestBehavior.translucent,
      child: Container(
        // padding: EdgeInsets.only(left: .3.w, top: .5.w),
        decoration: BoxDecoration(
          // color: MyColor.purpleEBB8FF,
          borderRadius: BorderRadius.circular(7.w),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28.w,
          height: 14.w,
          padding: EdgeInsets.all(1.w),
          alignment: check ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            // color: check ? Color(0xFF3EBDFC) : MyColor.grey696969,
            borderRadius: BorderRadius.circular(7.w),
            gradient: LinearGradient(
              colors: check ? MyColor.btnGradientColors2 : [MyColor.grey696969, MyColor.grey696969],
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 11.w,
            height: 11.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: MyColor.white,
              // gradient: LinearGradient(
              //   colors: check
              //       ? [MyColor.white, MyColor.white]
              //       : [MyColor.purpleC83DFF, MyColor.purple7815A0],
              // ),
            ),
          ),
        ),
      ),
    );
  }
}
