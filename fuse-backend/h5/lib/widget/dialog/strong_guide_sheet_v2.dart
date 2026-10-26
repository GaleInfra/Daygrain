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
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:untitled1/generated/assets.dart';

import '../../base_manager.dart';
import '../../utils/launch_util.dart';
import '../../utils/device_util.dart';

/// create: 2023/7/3
/// desc: 导量底部弹窗 V2
class StrongGuideSheetV2 extends StatelessWidget {
  StrongGuideSheetV2({Key? key}) : super(key: key);

  static Future show(BuildContext? bindWidget) async {
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
        child: StrongGuideSheetV2(),
        tag: _tag,
      );
      Future(() async {
        try {
          final request = Get.find<RequestRepository>();
          final eventData = <String, dynamic>{
            "event": "strong_guide_open",
            "page": "StrongGuideSheetV2",
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
          logger.i("StrongGuideSheetV2 弹窗打开上报异常: $e");
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

  static const String _tag = "StrongGuideSheetV2";

  final logic = Get.find<BannerStrongGuideLogic>();

  final appConfig = Get.find<AppConfigManager>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 30.w;
    return GetBuilder<BannerStrongGuideLogic>(
      builder: (logic) {
        if (logic.strongGuideModel.value?.guideMode == 3) {
          // 红色弹窗：翻译过程中保持内容显示
          return customMadeGuide(context);
        } else {
          // 白色弹窗：翻译过程中保留原弹窗，不切换为加载指示器
          return defaultGuide(width);
        }
      },
    );
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

  Container customMadeGuide(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      decoration: const BoxDecoration(), // 添加空的 decoration 以支持 clipBehavior
      clipBehavior: Clip.hardEdge, // 添加溢出裁剪属性
      child: Stack(
        children: [
          // 视频背景
          _VideoBackgroundWidget(),
          // 蒙层
          Positioned.fill(
            child: Image.asset(
              ImageAssets.huise,
              fit: BoxFit.cover,
            ),
          ),
          // 内容层
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // 头部导航栏：关闭按钮(左) + 标题(中) + 客服按钮(右)
              Padding(
                padding: EdgeInsets.only(
                  top: 1.5.w + (DeviceUtil().statusBarHeight ?? 0),
                  left: BHLanguageMar().isRightToLeft.value ? 10.w : 10.w,
                  right: BHLanguageMar().isRightToLeft.value ? 10.w : 10.w,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 左边关闭按钮
                    GestureDetector(
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
                    // 中间标题
                    Expanded(
                      child: Center(
                        child: Text(
                          "We Find A New App".bhTR,
                          style: TextStyle(
                            color: MyColor.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // 右边客服按钮
                    GestureDetector(
                      onTap: help,
                      child: Container(
                        width: 16.w,
                        height: 16.w,
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          ImageAssets.customServiceIcon,
                          width: 16.w,
                          height: 16.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: EdgeInsets.only(left: 17.w, right: 17.w),
                          child: GetBuilder<BannerStrongGuideLogic>(
                            builder: (logic) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // 顶部文字："1200+ sluty women are online waiting for you. Start connecting Now !"
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "1200+ sluty women ".bhTR,
                                          style: TextStyle(
                                            color: const Color(0xFFFFD700), // 黄色
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "are online".bhTR,
                                          style: TextStyle(
                                            color: MyColor.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.top,
                                          child: Container(
                                            width: 6.w,
                                            height: 6.w,
                                            margin: EdgeInsets.only(left: 2.w, bottom: 0.w),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        TextSpan(
                                          text: " waiting for you. Start connecting Now !".bhTR,
                                          style: TextStyle(
                                            color: MyColor.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MyGaps.vGaps15w,
                                  // "You will also get:" 标题
                                  Text(
                                    "You will also get:".bhTR,
                                    style: TextStyle(
                                      color: MyColor.white,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  MyGaps.vGaps10w,
                                  // 权益列表
                                  _buildBenefitItem(
                                    ImageAssets.videoIcon,
                                    "HD Video Calls".bhTR,
                                  ),
                                  MyGaps.vGaps4w,
                                  _buildBenefitItem(
                                    ImageAssets.eight,
                                    "18+ Photo and videos".bhTR,
                                  ),
                                  MyGaps.vGaps4w,
                                  _buildBenefitItem(
                                    ImageAssets.coinsIcon,
                                    "${logic.strongGuideModel.value?.rewardCoins ?? 0} ${"label_free".bhTR} ${"Coins".bhTR}",
                                  ),
                                  MyGaps.vGaps4w,
                                  _buildBenefitItem(
                                    ImageAssets.list,
                                    "Exclusive offer".bhTR,
                                  ),
                                  MyGaps.vGaps15w,
                                  // 下载按钮
                                  Center(
                                    child: MyGradientButton(
                                      text: "Download Now".bhTR,
                                      height: 29.w,
                                      width: 140.w,
                                      borderRadius: BorderRadius.circular(15.w),
                                      gradientColor: const [
                                        Color(0xFF8B00FF), // 紫色
                                        Color(0xFFFF1493), // 粉色
                                      ],
                                      onTap: onJump,
                                    ),
                                  ),
                                  MyGaps.vGaps8w,
                                  // 邀请码模块
                                  if (logic.strongGuideModel.value?.inviteCode != null &&
                                      logic.strongGuideModel.value!.inviteCode!.isNotEmpty)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Invitation Code: ".bhTR,
                                          style: TextStyle(
                                            color: MyColor.white,
                                            fontSize: 8.sp,
                                          ),
                                        ),
                                        Text(
                                          logic.strongGuideModel.value!.inviteCode!,
                                          style: TextStyle(
                                            color: const Color(0xFF6BE2FF), // 浅蓝色
                                            fontSize: 8.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        MyGaps.hGaps5w,
                                        GestureDetector(
                                          onTap: logic.onCopy,
                                          child: Icon(
                                            Icons.copy,
                                            size: 12.w,
                                            color: MyColor.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  MyGaps.vGaps5w,
                                  SizedBox(height: DeviceUtil().bottomSafe),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text) {
    return Row(
      children: [
        Image.asset(
          icon,
          width: 15.w,
          height: 15.w,
          fit: BoxFit.contain,
        ),
        MyGaps.hGaps5w,
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: MyColor.white,
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

/// 视频背景组件
class _VideoBackgroundWidget extends StatefulWidget {
  @override
  State<_VideoBackgroundWidget> createState() => _VideoBackgroundWidgetState();
}

class _VideoBackgroundWidgetState extends State<_VideoBackgroundWidget> {
  late VideoPlayerController videoController;
  ChewieController? chewieController;
  final isPlaying = false.obs;

  @override
  void initState() {
    super.initState();
    // 初始化视频控制器
    videoController = VideoPlayerController.asset('assets/audio/newguide.mp4');
    videoController.setLooping(true);
    
    // 添加监听器来监听视频状态变化
    videoController.addListener(() {
      if (videoController.value.isInitialized) {
        if (chewieController == null) {
          chewieController = ChewieController(
            videoPlayerController: videoController,
            autoPlay: true,
            looping: true,
            showControls: false,
            aspectRatio: videoController.value.aspectRatio,
          );
          if (!videoController.value.isPlaying) {
            videoController.seekTo(Duration.zero);
            videoController.play();
            isPlaying.value = true;
            setState(() {});
          }
        }
      }
    });
    
    // 异步初始化视频
    videoController.initialize().then((value) {
      logger.i("视频初始化完成: ${videoController.value.isInitialized}");
    }).catchError((e) {
      logger.i("视频初始化失败: $e");
    });
  }

  @override
  void dispose() {
    videoController.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // 预加载图（始终显示在底层，作为背景）
        Positioned.fill(
          child: Image.asset(
            Assets.newguide,
            key: const ValueKey('preload_image'),
            fit: BoxFit.cover,
            width: screenSize.width,
            height: screenSize.height,
            errorBuilder: (context, error, stackTrace) {
              logger.i("预加载图加载失败: $error, 路径: ${Assets.newguide}");
              // 如果预加载图加载失败，显示原来的红色渐变背景
              return Container(
                decoration: BoxDecoration(
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
                  ),
                ),
              );
            },
          ),
        ),
        // 视频播放器（加载完成后显示，替换预加载图）
        Positioned.fill(
          child: Obx(
            () => Offstage(
              offstage: !(isPlaying.value && chewieController != null),
              child: chewieController != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: videoController.value.isInitialized
                            ? videoController.value.size.width
                            : screenSize.width,
                        height: videoController.value.isInitialized
                            ? videoController.value.size.height
                            : screenSize.height,
                        child: Chewie(controller: chewieController!),
                      ),
                    )
                  : Container(),
            ),
          ),
        ),
      ],
    );
  }
}

