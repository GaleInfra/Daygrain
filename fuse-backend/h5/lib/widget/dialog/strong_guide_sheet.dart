import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/common_logic/banner_strong_guide_logic.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/translate/translate_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/res/my_gaps.dart';
import 'package:untitled1/utils/dialog_util.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/package_info_util.dart';
import 'package:untitled1/widget/button/my_button.dart';
import 'package:untitled1/widget/button/my_gradient_button.dart';
import 'package:untitled1/widget/image/my_extended_network_image.dart';

import '../../base_manager.dart';
import '../../utils/launch_util.dart';

/// create: 2023/7/3
/// desc: 导量底部弹窗
class StrongGuideSheet extends StatelessWidget {
  StrongGuideSheet({Key? key}) : super(key: key);

  static Future show(BuildContext? bindWidget) {
    final strongGuideModel = Get.find<BannerStrongGuideLogic>().strongGuideModel.value;
    if (!Get.find<AppConfigManager>().isReviewPkg.value && (Get.find<AppConfigManager>().strategyModel?.isSwitchStrongGuide ?? false) && strongGuideModel != null) {
      // 非审核模式下 && 已打开导量配置 && 导量数据不为空 可弹
      // 先显示弹窗，再异步上报，避免显示延迟
      final future = DialogUtil.showDialog(
        alignment: strongGuideModel.guideMode == 3 ? Alignment.center : Alignment.bottomCenter,
        bindPage: false,
        bindWidget: bindWidget,
        clickMaskDismiss: true,
        backDismiss: true,
        child: StrongGuideSheet(),
        tag: _tag,
      );
      Future(() async {
        try {
          final request = Get.find<RequestRepository>();
          final eventData = <String, dynamic>{
            "event": "strong_guide_open",
            "page": "StrongGuideSheet",
            "subPage": strongGuideModel.inPkgName ?? "",
            "tm": DateTime.now().millisecondsSinceEpoch,
          };
          await request.logEvent(data: eventData);
          getReqRepo()?.log(
            event: "show",
            page: "strong_guide_bigBag",
            subPage: "open",
          );
        } catch (e) {
          logger.i("StrongGuideSheet 弹窗打开上报异常: $e");
        }
      });
      return future;
    } else {
      if (strongGuideModel == null && !Get.find<AppConfigManager>().isReviewPkg.value) {
        Get.find<BannerStrongGuideLogic>().onGetStrongGuide();
      } else if (Get.find<AppConfigManager>().strategyModel?.isSwitchStrongGuide == null) {
        //刷新策略
        Get.find<AppConfigManager>().onGetStrategy();
      }
    }
    return Future.value();
  }

  static void dismiss() {
    DialogUtil.dismiss(tag: _tag);
  }

  //帮助
  static void help() {
    dismiss();
    // 打开客服中心
    MessageChatPage.to(
      UserInfoModel(userId: Get.find<AppConfigManager>().strategyModel?.userServiceAccountId),
    );
  }

  static const String _tag = "StrongGuideSheet";

  final logic = Get.find<BannerStrongGuideLogic>();

  final appConfig = Get.find<AppConfigManager>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 30.w;
    return logic.strongGuideModel.value?.guideMode == 3 ? customMadeGuide(width) : defaultGuide(width);
  }

  Widget defaultGuide(double width) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.only(top: 8.w, right: 9.w, left: 9.w, bottom: 10.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.w)),
            color: MyColor.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      MyExtendedNetworkImage(
                        url: logic.strongGuideModel.value?.inIcon ?? "",
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(5.w),
                        width: 30.w,
                        height: 30.w,
                      ),
                      MyGaps.vGaps3w,
                      Text(
                        logic.strongGuideModel.value?.inPkgName ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MyColor.orangeFFA766,
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              MyGaps.vGaps8w,
              GetBuilder<BannerStrongGuideLogic>(builder: (logic) {
                return RichText(
                  text: TextSpan(
                    text: "",
                    children: [
                      for (var item in logic.translateList) ...{
                        TextSpan(
                          text: logic.showTrans && item.translate ? item.result : (item.content == " [action_copy]" ? " ${"action_copy".bhTR}" : item.content),
                          style: TextStyle(
                            color: item.textStyle?.color ?? const Color(0xFFCEC0C1),
                            fontSize: 7.sp,
                          ),
                          recognizer: item.content == " [action_copy]" ? (TapGestureRecognizer()..onTap = () => logic.onCopy()) : null,
                        ),
                      },
                    ],
                  ),
                );
              }),
              MyGaps.vGaps3w,
              GestureDetector(
                onTap: () => logic.onTranslate(),
                child: Row(
                  children: [
                    Image.asset(
                      "${BaseManager.instance.assetsPrefix}assets/images/icons/translate.webp",
                      width: 10.w,
                      height: 10.w,
                    ),
                    MyGaps.hGaps5w,
                    GetBuilder<BannerStrongGuideLogic>(builder: (logic) {
                      return Text(
                        logic.showTrans
                            ? "action_showOriginalText".bhTR
                            : logic.isTransing
                                ? "Translating".bhTR
                                : "action_clickToTranslate".bhTR,
                        style: TextStyle(
                          color: MyColor.greyB7B5BD,
                          fontSize: 6.sp,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              MyGaps.vGaps10w,
              MyGradientButton(
                text: "advantage_downloadForFreeCoins".bhTR,
                onTap: onJump,
              ),
              MyGaps.vGaps10w,
              Center(
                child: GestureDetector(
                  onTap: dismiss,
                  child: Text(
                    "action_nextTime".bhTR,
                    style: TextStyle(
                      color: MyColor.purpleA953FF,
                      fontSize: 8.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Container customMadeGuide(double width) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10.w)),
          color: const Color(0xFF250003),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF793920),
              Color(0xFF000000),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.2, 1.0],
          )),
      clipBehavior: Clip.hardEdge, // 添加溢出裁剪属性
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              //右上角关闭按钮
              Positioned(
                top: 1.5.w,
                right: BHLanguageMar().isRightToLeft.value ? null : 4.w,
                left: BHLanguageMar().isRightToLeft.value ? 5.w : null,
                child: GestureDetector(
                  onTap: dismiss,
                  child: Container(
                    width: 12.w,
                    height: 12.w,
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: MyColor.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 8.w,
                      color: MyColor.black,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    height: 7.5.w,
                  ),
                  Image.asset(
                    ImageAssets.strongGuideFiveStar,
                    width: 43.w,
                    height: 5.5.w,
                  ),
                  SizedBox(
                    height: 2.5.w,
                  ),
                  Row(
                    textDirection: TextDirection.ltr,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            textDirection: TextDirection.ltr,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                ImageAssets.strongGuideLeftWings,
                                width: 23.2.w,
                                height: 35.w,
                              ),
                              MyGaps.hGaps2w,
                              Container(
                                padding: EdgeInsets.all(1.w),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(10.w)),
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFEDCDAC),
                                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(Radius.circular(9.w)),
                                    color: const Color(0xFF000000),
                                  ),
                                  child: MyExtendedNetworkImage(
                                    url: logic.strongGuideModel.value?.inIcon ?? "",
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(5.w),
                                    width: 35.w,
                                    height: 35.w,
                                  ),
                                ),
                              ),
                              MyGaps.hGaps2w,
                              Image.asset(
                                ImageAssets.strongGuideRightWings,
                                width: 23.2.w,
                                height: 35.w,
                              ),
                            ],
                          ),
                          MyGaps.vGaps3w,
                          Stack(alignment: Alignment.center, children: [
                            Image.asset(
                              ImageAssets.strongGuideAppNameBg,
                              width: 72.w,
                              height: 11.5.w,
                            ),
                            SizedBox(
                              width: 72.w,
                              height: 11.5.w,
                              child: Center(
                                child: AutoSizeText(
                                  logic.strongGuideModel.value?.inPkgName ?? "",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDCB34F),
                                    fontSize: 8.w,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            )
                          ]),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(left: 10.w, right: 10.w),
            child: Column(
              children: [
                // MyGaps.vGaps8w,
                GetBuilder<BannerStrongGuideLogic>(builder: (logic) {
                  List<TranslateModel> translateList = List.from(logic.translateList);
                  List<TranslateModel> translateList2 = List.from(logic.translateList2);
                  List<TranslateModel> translateList3 = List.from(logic.translateList3);
                  List<TranslateModel> translateListItems = List.from(logic.translateListItems);
                  return Container(
                    // constraints: BoxConstraints(
                    //   maxHeight: Get.height*0.7,
                    // ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF4B061E),
                              borderRadius: BorderRadius.circular(8.w),
                            ),
                            constraints: BoxConstraints(
                              minHeight: 60.w,
                            ),
                            padding: EdgeInsets.all(4.5.w),
                            margin: EdgeInsets.only(bottom: 5.w, top: 5.w),
                            // height: 60.w, // 添加固定高度
                            child: RichText(
                              text: TextSpan(
                                text: "",
                                children: [
                                  for (var item in translateList) ...{
                                    TextSpan(
                                      text: logic.showTrans && item.translate ? item.result : item.content,
                                      style: TextStyle(
                                        color: item.textStyle?.color ?? const Color(0xFFCEC0C1),
                                        fontSize: 7.sp,
                                      ),
                                    ),
                                  },
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 14.w, // 设置一个固定高度，根据需要调整数值
                            margin: EdgeInsets.symmetric(vertical: 2.w),
                            child: Stack(
                              children: [
                                // 邀请码居中
                                Center(
                                  child: Text(
                                    logic.strongGuideModel.value?.inviteCode ?? "",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: MyColor.white,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                                // 复制按钮靠右
                                Positioned(
                                  right: 0,
                                  child: MyButton(
                                      text: "action_copy".bhTR,
                                      onTap: logic.onCopy,
                                      height: 14.w,
                                      padding: EdgeInsets.only(
                                          left: 4.w, right: 4.w),
                                      borderRadius: BorderRadius.circular(6.w),
                                      background: const Color(0xFFD6003C),
                                      textStyle: TextStyle(
                                        color: MyColor.white,
                                        fontSize: 7.sp,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 23.w, // 设置您需要的高度
                            alignment: Alignment.topLeft,
                            child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                text: "",
                                children: [
                                  for (var item in translateList2) ...{
                                    TextSpan(
                                      text: logic.showTrans && item.translate ? item.result : item.content,
                                      style: TextStyle(
                                        color: item.textStyle?.color ?? const Color(0xFFCEC0C1),
                                        fontSize: 7.sp,
                                      ),
                                    ),
                                  },
                                ],
                              ),
                            ),
                          ),
                          if (translateListItems.length >= 3)
                            Row(
                              children: [
                                //圆角白色半透明背景，中间显示图标，底部显示文字 宽 37.w 高44.w
                                _buildItem(
                                  ImageAssets.strongGuideItem1,
                                  (logic.showTrans && translateListItems.isNotEmpty && translateListItems[0].translate
                                          ? translateListItems[0].result
                                          : translateListItems[0].content) ??
                                      "",
                                ),
                                const Spacer(),
                                _buildItem(
                                    ImageAssets.strongGuideItem2,
                                    (logic.showTrans && translateListItems.isNotEmpty && translateListItems[1].translate
                                            ? translateListItems[1].result
                                            : translateListItems[1].content) ??
                                        ""),
                                const Spacer(),
                                _buildItem(
                                    ImageAssets.strongGuideItem3,
                                    (logic.showTrans && translateListItems.isNotEmpty && translateListItems[2].translate
                                            ? translateListItems[2].result
                                            : translateListItems[2].content) ??
                                        ""),
                              ],
                            ),
                          Container(
                            padding: EdgeInsets.only(top: 1.5.w),
                            child: RichText(
                              textAlign: TextAlign.start,
                              text: TextSpan(
                                text: "",
                                children: [
                                  for (var item in translateList3) ...{
                                    TextSpan(
                                      text: logic.showTrans && item.translate ? item.result : item.content,
                                      style: TextStyle(
                                        color: item.textStyle?.color ?? const Color(0xFFCEC0C1),
                                        fontSize: 7.sp,
                                      ),
                                    ),
                                  },
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
                MyGaps.vGaps3w,
                // GestureDetector(
                //   onTap: () => logic.onTranslate(),
                //   child: Row(
                //     children: [
                //       Image.asset(
                //         ImageAssets.newMessageTranslate,
                //         fit: BoxFit.cover,
                //         width: 10.w,
                //         height: 10.w,
                //       ),
                //       MyGaps.hGaps5w,
                //       GetBuilder<BannerStrongGuideLogic>(builder: (logic) {
                //         return Text(
                //           logic.showTrans
                //               ? "action_showOriginalText".bhTR
                //               : logic.isTransing
                //                   ? "Translating".bhTR
                //                   : "action_clickToTranslate".bhTR,
                //           style: TextStyle(
                //             color: const Color(0xFFFF6D76),
                //             fontSize: 8.sp,
                //           ),
                //         );
                //       }),
                //     ],
                //   ),
                // ),
                MyGaps.vGaps10w,
                Row(
                  children: [
                    //帮助按钮，圆角边框,红色边框背景和底色一样
                    MyButton(
                        text: "action_help".bhTR,
                        onTap: help,
                        height: 20.w,
                        borderRadius: BorderRadius.circular(10.w),
                        borderColor: const Color(0xFFFC5350),
                        borderWidth: 1.w,
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        background: MyColor.transparent,
                        textStyle: TextStyle(
                          color: const Color(0xFFFC5350),
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                        )),
                    MyGaps.hGaps7w,
                    Expanded(
                      child: MyGradientButton(
                        text: "Download".bhTR,
                        height: 20.w,
                        borderRadius: BorderRadius.circular(10.w),
                        gradientColor: const [
                          Color(0xFFFC5350),
                          Color(0xFF460645),
                        ],
                        onTap: onJump,
                      ),
                    ),
                    MyGaps.vGaps10w,
                  ],
                ),
                MyGaps.vGaps10w,
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildItem(String icon, String text) {
    return Container(
      width: 37.w,
      height: 44.w,
      margin: EdgeInsets.only(bottom: 3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF4B061E),
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(
            icon,
            width: 21.w,
            height: 21.w,
          ),
          Text(text, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: MyColor.white, fontSize: 7.sp, fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }

  void onJump() async {
    getReqRepo()?.log(
      event: "click",
      page: "strong_guide_bigBag",
      subPage: "click_download",
    );
    logic.onCopy();
    if (logic.strongGuideModel.value?.source == 0) {
      // todo 无商店服务没有测试
      // 跳转本包名的对应商店。（谷歌商店/苹果商店）
      LaunchUtil.launchAppStore(packageName: PackageInfoUtil().packageInfo.packageName);
    } else if (logic.strongGuideModel.value?.source == 1) {
      // todo 无商店服务没有测试
      // 跳转pkgName字段包名的对应商店。（谷歌商店/苹果商店）
      LaunchUtil.launchAppStore(packageName: logic.strongGuideModel.value!.pkgname!);
    } else if (logic.strongGuideModel.value?.source == 2) {
      // 打开外部浏览器下载url字段链接的apk包
      LaunchUtil.launchJump(url: logic.strongGuideModel.value!.url!);
    }
  }
}
