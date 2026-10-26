import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/model/robot/RobotModel.dart';
import 'package:untitled1/model/user/user_info_model.dart';
import 'package:untitled1/pages/message/message_chat/view.dart';
import 'package:untitled1/pages/robot/view.dart';
import 'package:untitled1/pages/web_view/view.dart';
import 'package:untitled1/translate/translate_manager.dart';
import 'package:untitled1/utils/launch_util.dart';

class RobotLogic extends GetBaseController {
  final dataArray = <RobotCQModel>[].obs;
  final scrollController = ScrollController();
  var isFirst = true;
  var isBounds = false;
  final translate = Get.find<TranslateManager>();
  @override
  void onInit() {
    super.onInit();
    logHandle.initLog('customer_service');
    getRobotFAQ();
  }

  Future<void> getRobotFAQ() async {

    await request.robotFAQ(
      onSuccess: (faqData) {
        // if (isFirst) {
        //   isFirst = false;
        dataArray.clear();
          final model = RobotCQModel()
            ..type = 0
            ..faqModel = faqData;
          if(Get.find<AppConfigManager>().autoTranslate.value) {
            var content = model.faqModel?.content ?? '';
            for (var element in model.faqModel?.faqInfoList ?? []) {
              content = "$content\n" + element.question ?? '';
            }
            translateText(content, model);
          }
          dataArray.add(model);
        // }
      },
      onFail: onChangeError,
    );

  }

  void handleQuestionTap(FaqInfoList question) {
    if (isBounds) return;

    isBounds = true;
    Future.delayed(const Duration(seconds: 1), () => isBounds = false);

    if (question.type == 2) {
      handleTap(question.handleType ?? 0, question.toUrl ?? '');
    } else {
      final userModel = RobotCQModel()
        ..type = 2
        ..content = question.question?.replaceAll('*  ', '');
      dataArray.add(userModel);

      scrollToBottom();

      Future.delayed(const Duration(seconds: 1), () {
        final answerModel = RobotCQModel()
          ..type = 1
          ..questionModel = question;
        if(Get.find<AppConfigManager>().autoTranslate.value) {
          translateText(answerModel.questionModel?.messageAnswer?.content ?? '', answerModel);
        }
        dataArray.add(answerModel);
        scrollToBottom();
      });
    }
  }

  Future<void> translateText(String text, RobotCQModel model) async {
    if (model.isTraning == 1 || model.tranString != null) return;

    model.isTraning = 1;
    // dataArray.refresh();

    try {
      var translateText = translate.getCache(text) ?? "";

      if (translateText.isNotEmpty) {
        model.tranString = translateText;
        model.isTraning = 2;
        dataArray.refresh();
        return;
      }

      translate.trans(
        content: text,
        onSuccess: (result) {
          model.tranString = result;
          model.isTraning = 2;
          dataArray.refresh();
        },
        onFail: (msg) {
          model.isTraning = 0;
          dataArray.refresh();
        },
      );

    } catch (e) {
      model.isTraning = 0;
    }
    dataArray.refresh();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  void handleAnswerTap(AnswerEventHandleList answer) {
    if (isBounds) return;

    isBounds = true;
    Future.delayed(const Duration(seconds: 1), () => isBounds = false);

    // 处理点击事件
    handleTap(answer.handleType ?? 0, answer.toUrl ?? '');
  }

  void handleTap(int handleType, String toUrl) {
    switch (handleType) {
      case 1: // 打开网页
        MessageChatPage.to(
          UserInfoModel(
              userId: Get.find<AppConfigManager>()
                  .strategyModel
                  ?.userServiceAccountId),
        );
        break;
      case 2: // 打开应用内页面
        if (toUrl.isNotEmpty) {
          LaunchUtil.launchJump(url: toUrl);
        }
        break;
      case 3: // 复制文本
        if (toUrl.isNotEmpty) {
            var appConfig = Get.find<AppConfigManager>();
            dynamic tppOpenType = appConfig.getAppConfigByKey("tpp_open_type");
            if (tppOpenType?.toString() == "0") {
              WebViewPage.onJump(url: toUrl);
            } else {
              LaunchUtil.launchJump(url: toUrl);
            }
        }
        break;

      default:
        print('未处理的handleType: $handleType');
        break;
    }
  }

  void handleHelpClick() {
    dataArray.refresh();
  }
  void showImagePreview(String url) {
    if (url.isEmpty) return;

    // 使用自定义图片预览组件
    Get.to(() => FullScreenImagePreview(
      imageUrls: [url],
      initialIndex: 0,
      heroTag: url,
      onUserInfo: null,
      onlineStatus: null,
    ));
  }
}