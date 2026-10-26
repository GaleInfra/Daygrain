import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

import 'logic.dart';

/// 修改个人资料
class ModifyInfoPage extends StatelessWidget {
  final logic = Get.find<ModifyInfoLogic>();
  final codeList = [
    "AF",
    "AX",
    "AL",
    "DZ",
    "AS",
    "AD",
    "AO",
    "AI",
    "AQ",
    "AG",
    "AR",
    "AM",
    "AW",
    "AU",
    "AT",
    "AZ",
    "BS",
    "BH",
    "BD",
    "BB",
    "BY",
    "BE",
    "BZ",
    "BJ",
    "BM",
    "BT",
    "BO",
    "BQ",
    "BA",
    "BW",
    "BV",
    "BR",
    "IO",
    "BN",
    "BG",
    "BF",
    "BI",
    "CV",
    "KH",
    "CM",
    "CA",
    "KY",
    "CF",
    "TD",
    "CL",
    "CX",
    "CC",
    "CO",
    "KM",
    "CG",
    "CD",
    "CK",
    "CR",
    "CI",
    "HR",
    "CU",
    "CW",
    "CY",
    "CZ",
    "DK",
    "DJ",
    "DM",
    "DO",
    "EC",
    "EG",
    "SV",
    "GQ",
    "ER",
    "EE",
    "SZ",
    "ET",
    "FK",
    "FO",
    "FJ",
    "FI",
    "FR",
    "GF",
    "PF",
    "TF",
    "GA",
    "GM",
    "GE",
    "DE",
    "GH",
    "GI",
    "GR",
    "GL",
    "GD",
    "GP",
    "GU",
    "GT",
    "GG",
    "GN",
    "GW",
    "GY",
    "HT",
    "HM",
    "VA",
    "HN",
    "HK",
    "HU",
    "IS",
    "IN",
    "ID",
    "IR",
    "IQ",
    "IE",
    "IM",
    "IL",
    "IT",
    "JM",
    "JP",
    "JE",
    "JO",
    "KZ",
    "KE",
    "KI",
    "KP",
    "KR",
    "KW",
    "KG",
    "LA",
    "LV",
    "LB",
    "LS",
    "LR",
    "LY",
    "LI",
    "LT",
    "LU",
    "MO",
    "MG",
    "MW",
    "MY",
    "MV",
    "ML",
    "MT",
    "MH",
    "MQ",
    "MR",
    "MU",
    "YT",
    "MX",
    "FM",
    "MD",
    "MC",
    "MN",
    "ME",
    "MS",
    "MA",
    "MZ",
    "MM",
    "NA",
    "NR",
    "NP",
    "NL",
    "NC",
    "NZ",
    "NI",
    "NE",
    "NG",
    "NU",
    "NF",
    "MK",
    "MP",
    "NO",
    "OM",
    "PK",
    "PW",
    "PS",
    "PA",
    "PG",
    "PY",
    "PE",
    "PH",
    "PN",
    "PL",
    "PT",
    "PR",
    "QA",
    "RE",
    "RO",
    "RU",
    "RW",
    "BL",
    "SH",
    "KN",
    "LC",
    "MF",
    "PM",
    "VC",
    "WS",
    "SM",
    "ST",
    "SA",
    "SN",
    "RS",
    "SC",
    "SL",
    "SG",
    "SX",
    "SK",
    "SI",
    "SB",
    "SO",
    "ZA",
    "GS",
    "SS",
    "ES",
    "LK",
    "SD",
    "SR",
    "SJ",
    "SE",
    "CH",
    "SY",
    "TW",
    "TJ",
    "TZ",
    "TH",
    "TL",
    "TG",
    "TK",
    "TO",
    "TT",
    "TN",
    "TR",
    "TM",
    "TC",
    "TV",
    "UG",
    "UA",
    "AE",
    "GB",
    "US",
    "UM",
    "UY",
    "UZ",
    "VU",
    "VE",
    "VN",
    "VG",
    "VI",
    "WF",
    "EH",
    "YE",
    "ZM",
    "ZW"
  ];
  ModifyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Scaffold(
        appBar: DefaultAppBar(
          title: "action_editProfile".bhTR,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const _AvatarWidget(),
              const _ImageGrid(),
              _Item(
                title: "label_nickname".bhTR,
                showArrow: true,
                child: TextField(
                  controller: logic.nameTEC,
                  textAlign: TextAlign.end,
                  maxLength: 30,
                  style: TextStyle(
                    color: MyColor.white,
                    fontSize: 7.sp,
                  ),
                  cursorColor: MyColor.white,
                  decoration: InputDecoration(
                    hintText: "label_nickname".bhTR,
                    counterText: "",
                    hintStyle: TextStyle(
                      color: MyColor.white,
                      fontSize: 7.sp,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 6.w),
                    enabledBorder:
                        const OutlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder:
                        const OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              _Item(
                title: "label_dateOfBirth".bhTR,
                showArrow: true,
                child: GestureDetector(
                  onTap: () => logic.onModifyBirthday(context),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.w),
                    child: Align(
                      alignment: BHLanguageMar().isRightToLeft.value
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: GetBuilder<ModifyInfoLogic>(
                        builder: (logic) {
                          return Text(
                            logic.birthday,
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 7.sp,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => logic.onSelectCountry(),
                child: _Item(
                  title: "label_country".bhTR,
                  showArrow: true,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.w),
                    child: Align(
                      alignment: BHLanguageMar().isRightToLeft.value
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: GetBuilder<ModifyInfoLogic>(
                        builder: (logic) {
                          return Text(
                            logic.country,
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 7.sp,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Text(
                        "Introduction：".bhTR,
                        style: TextStyle(
                          color: MyColor.white,
                          fontSize: 8.sp,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 74.w,
                        child: Theme(
                          data: ThemeData(
                            primaryColor: MyColor.white,
                          ),
                          child: TextField(
                            controller: logic.aboutTEC,
                            // maxLength: 300,
                            maxLines: null,
                            minLines: null,
                            expands: true,
                            textAlign: TextAlign.start,
                            textAlignVertical: TextAlignVertical.top,
                            cursorColor: MyColor.white,
                            style: TextStyle(
                              color: MyColor.white,
                              fontSize: 6.sp,
                            ),
                            decoration: InputDecoration(
                              hintText: "Type in here...".bhTR,
                              hintStyle: TextStyle(
                                color: const Color.fromARGB(255, 182, 182, 182)
                                    .withOpacity(.57),
                                fontSize: 6.sp,
                              ),
                              helperStyle:
                                  const TextStyle(color: MyColor.white),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 6.w),
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: MyColor.grey727),
                                borderRadius: BorderRadius.circular(10.w),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: MyColor.grey727),
                                borderRadius: BorderRadius.circular(10.w),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              MyGaps.vGaps10w,
              Container(
                // padding: EdgeInsets.only(left: .3.w, top: .5.w),
                margin: EdgeInsets.symmetric(horizontal: 9.w),
                child: MyGradientButton(
                  width: 119.w,
                  text: "action_submit".bhTR,
                  style: TextStyle(
                    color: MyColor.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  onTap: () => logic.onSave(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 头像区域
class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppConfigManager>(
      builder: (appConfig) {
        return GetBuilder<ModifyInfoLogic>(
          builder: (logic) {
            return Container(
              margin: EdgeInsets.only(top: 10.w),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => logic.onSelectAvatar(),
                child: Stack(
                  children: [
                    if (logic.avatarBytes != null)
                      Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                          image:
                              AssetImage(ImageAssets.avtarBorder), // 替换为你的图片路径
                          fit: BoxFit.cover, // 根据需求选择合适的 fit 属性
                        )),
                        child: ClipOval(
                          child: Image.memory(
                            logic.avatarBytes!,
                            fit: BoxFit.cover,
                            width: 46.w,
                            height: 46.w,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.w),
                            image: const DecorationImage(
                              image: AssetImage(ImageAssets.avtarBorder), // 替换为你的图片路径
                              fit: BoxFit.cover, // 根据需求选择合适的 fit 属性
                            )),
                        child: MyExtendedNetworkImage(
                          url: appConfig.userInfo.avatarUrl ?? "",
                          width: 46.w,
                          height: 46.w,
                          shape: BoxShape.circle,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Visibility(
                      visible: (appConfig.userInfo.isVip ?? false),
                      child: Image.asset(
                        ImageAssets.settingAvatarVip,
                        width: 48.w,
                        height: 48.w,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 6.w,
                      child: Container(
                        width: 13.w,
                        height: 13.w,
                        decoration: BoxDecoration(
                          color: MyColor.black.withOpacity(.37),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          ImageAssets.settingAvatarUpdate,
                          width: 8.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.title,
    required this.child,
    this.showArrow = false,
  }) : super(key: key);

  final String title;

  final Widget child;

  /// 显示箭头
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.w,
      margin: EdgeInsets.only(left: 8.w, right: 8.w, bottom: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: const Color(0xFF26203A),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Row(
        children: [
          Center(
            child: Text(
              title,
              style: TextStyle(
                color: MyColor.grey6F6E6C,
                fontSize: 7.sp,
              ),
            ),
          ),
          MyGaps.hGaps5w,
          Expanded(
            child: child,
          ),
          Visibility(
            visible: showArrow,
            child: Padding(
              padding: EdgeInsets.only(
                  left: BHLanguageMar().isRightToLeft.value ? 0 : 5.w,
                  right: BHLanguageMar().isRightToLeft.value ? 5.w : 0),
              child: Image.asset(
                ImageAssets.mineModify,
                width: 5.w,
                height: 5.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 图片区
class _ImageGrid extends StatelessWidget {
  const _ImageGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ModifyInfoLogic>(
      builder: (logic) {
        return GridView.builder(
          itemCount:
              logic.imageList.length >= 4 ? 4 : logic.imageList.length + 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(9.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 5.w,
            crossAxisSpacing: 5.w,
            childAspectRatio: 1,
          ),
          itemBuilder: (ctx, index) {
            return _GridItem(
              isAdd: index == logic.imageList.length,
              path:
                  index == logic.imageList.length ? "" : logic.imageList[index],
              onAdd: () => logic.onSelectImage(),
              onDel: () => logic.onDelImage(index),
              logic: logic,
            );
          },
        );
      },
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
    Key? key,
    this.isAdd = false,
    required this.path,
    required this.onAdd,
    required this.onDel,
    required this.logic,
  }) : super(key: key);

  final bool isAdd;

  final String path;

  final VoidCallback onAdd;

  /// 删除
  final VoidCallback onDel;

  final ModifyInfoLogic logic;

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      onTap: onAdd,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF26203A),
          borderRadius: BorderRadius.circular(7.5.w),
        ),
        child: Image.asset(
          ImageAssets.avatarAdd,
          width: 16.w,
        ),
      ),
    );
    if (!isAdd) {
      if (path.startsWith("http")) {
        child = MyExtendedNetworkImage(
          url: path,
          borderRadius: BorderRadius.circular(5.w),
          width: 50.w,
          height: 50.w,
          fit: BoxFit.cover,
          shape: BoxShape.rectangle,
        );
      } else {
        child = ClipRRect(
          borderRadius: BorderRadius.circular(5.w),
          child: (path.startsWith("img_") && logic.bytesList[path] != null)
              ? Image.memory(
                  logic.bytesList[path]!,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(path),
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                ),
        );
      }

      child = Stack(
        children: [
          child,
          Positioned(
            top: 2.w,
            right: 2.w,
            child: GestureDetector(
              onTap: onDel,
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: MyColor.black.withOpacity(.37),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: MyColor.white,
                  size: 6.w,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return child;
  }
}
