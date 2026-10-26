import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/pages/robot/widgets/robot_answer_cell.dart';
import 'package:untitled1/pages/robot/widgets/robot_question_cell.dart';
import 'package:untitled1/pages/robot/widgets/robot_user_cell.dart';
import 'package:untitled1/res/image_assets.dart';
import 'package:untitled1/utils/device_util.dart';
import 'package:untitled1/widget/app_bar/default_app_bar.dart';
import 'package:untitled1/widget/gradient_backgrond_widget.dart';

import 'logic.dart';

class RobotPage extends GetView<RobotLogic> {

  const RobotPage({super.key});
  @override
  Widget build(BuildContext context) {
    return GradientBackgroundWidget(
      child: Scaffold(

        appBar: DefaultAppBar(title: "title_customerService".bhTR,action: [

          GestureDetector(
            onTap: (){
              MessageChatPage.to(
                UserInfoModel(
                    userId: Get.find<AppConfigManager>()
                        .strategyModel
                        ?.userServiceAccountId),
              );
            },
            child: Image.asset(ImageAssets.customServiceIcon,
              width: 12.w,
              height: 12.w,),
          ),
          SizedBox(width: 7.5.w,),
        ],),
        body: Column(
          children: [
            Expanded(
              child: Obx(
                    () => ListView.builder(
                  controller: controller.scrollController,
                  itemCount: controller.dataArray.length,
                  itemBuilder: (context, index) {
                    final model = controller.dataArray[index];


                    if (model.type == 0) {
                      return RobotQuestionCell(
                        model: model,
                        onQuestionTap: (question) =>
                            controller.handleQuestionTap(question),
                        onTranslate: (text) =>
                            controller.translateText(text, model),
                      );
                    } else if (model.type == 1) {
                      return RobotAnswerCell(
                        model: model,
                        onAnswerTap: (answer) =>
                            controller.handleAnswerTap(answer),
                        onTranslate: (text) =>
                            controller.translateText(text, model),
                        onExample: (url) =>
                            controller.showImagePreview(url),
                        helpClick: () =>
                            controller.handleHelpClick(),
                      );
                    } else {
                      return RobotUserCell(model: model);
                    }
                  },
                ),

              ),
            ),
          ],
        ),
      ),
    );
  }
}


// 自定义图片预览组件
class FullScreenImagePreview extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTag;
  final Function? onUserInfo;
  final Function? onlineStatus;

  const FullScreenImagePreview({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
    required this.heroTag,
    this.onUserInfo,
    this.onlineStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 图片预览
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(imageUrls[index]),
                initialScale: PhotoViewComputedScale.contained,
                heroAttributes: PhotoViewHeroAttributes(tag: '$heroTag$index'),
              );
            },
            itemCount: imageUrls.length,
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: PageController(initialPage: initialIndex),
          ),

          // 关闭按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 10 + (DeviceUtil().statusBarHeight ?? 0.0).toInt(),
            right: 10,
            child: IconButton(
              icon:const Icon(
                Icons.close,
                color: Colors.black,
                size: 30,
              ),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }
}