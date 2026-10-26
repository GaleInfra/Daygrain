
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/extension/get_extension.dart';
import 'package:untitled1/generated/assets.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/bh_platform.dart';
import 'package:untitled1/utils/dialog_util.dart';

import '../../res/my_gaps.dart';
import '../../widget/app_bar/default_app_bar.dart';
import '../../widget/dialog/confirm_dialog.dart';
import '../../widget/gradient_backgrond_widget.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> supportLanguages = List.from(BHLanguageMar.supportLangList);
    //获取当前选择的语言
    String currentLanguage = BHLanguageMar().currentLangFromApp;
    //将supportLanguages 内默认选中的语言放第一位
    int currentIndex = supportLanguages.indexOf(currentLanguage);
    if (currentIndex == -1) {
      supportLanguages.insert(0, currentLanguage);
    } else if (currentIndex != 0) {
      supportLanguages.remove(currentLanguage);
      supportLanguages.insert(0, currentLanguage);
    }

    return GradientBackgroundWidget(
        child: Scaffold(
      appBar: DefaultAppBar(title: "label_language".bhTR),
      body: Container(
          child: ListView.separated(
              itemBuilder: (context, index) {
                bool isSelect = (supportLanguages[index] == BHLanguageMar().currentLangFromApp);
                String localName = BHLanguageMar.fullNameLang[supportLanguages[index]] ?? "";
                String enName = BHLanguageMar().getLanguageName(supportLanguages[index]);
                return GestureDetector(
                  onTap: () {
                    if (supportLanguages[index] == BHLanguageMar().currentLangFromApp) {
                      return;
                    }
                    DialogUtil.showDialog(
                      bindPage: false,
                      // bindWidget: context,
                      child: ConfirmDialog(
                        title: "confirm_switchLanguage".bhTR,
                        onConfirm: () {
                          DialogUtil.dismiss();
                          BHLanguageMar().setLang(supportLanguages[index]);
                          BHLanguageMar().reLoadLang();
                          if (BHPlatform.isWeb) {
                            //刷新网页
                            Get.forceAppUpdate();
                            Get.goHome();
                          } else {
                            //刷新GetX
                            Get.forceAppUpdate();
                            Get.goHome();
                          }
                        },
                      ),
                    );
                  },
                  child: Container(
                    width: double.maxFinite,
                    
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF26203A),
                      borderRadius: BorderRadius.all(Radius.circular(8.w)),
                    ),
                    child: Row(
                      children: [
                        MyGaps.hGaps5w,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localName,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: MyColor.white,
                                  fontSize: 8.sp,
                                ),
                              ),
                              SizedBox(
                                height: 2.w,
                              ),
                              Text(
                                ("country_$enName").bhTR,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: MyColor.greyC6C5C6,
                                  fontSize: 6.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        MyGaps.hGaps5w,
                        SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: Center(
                            child: Image.asset(
                                isSelect
                                    ? Assets.iconsIcChecked
                                    : Assets.iconsIcUncheck,
                                width: 10.w,
                                height: 10.w),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(
                  height: 5.w,
                );
              },
              itemCount: supportLanguages.length)),
    ));
  }
}
