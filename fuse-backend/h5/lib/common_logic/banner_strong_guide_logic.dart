import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/banner_strong_guide/banner_info_model.dart';
import 'package:untitled1/model/banner_strong_guide/strong_guide_model.dart';
import 'package:untitled1/model/translate/translate_model.dart';
import 'package:untitled1/res/my_color.dart';
import 'package:untitled1/utils/toast.dart';

import '../net/request_repository.dart';
import '../translate/translate_manager.dart';
import 'app_config_manager.dart';

/// create: 2023/7/3
/// desc: Banner 和 导量管理
class BannerStrongGuideLogic extends GetxController {
  final _request = Get.find<RequestRepository>();

  final _appConfig = Get.find<AppConfigManager>();

  final _translate = Get.find<TranslateManager>();

  Worker? _languageWorker;

  /// banner列表
  final List<BannerInfoModel> bannerList = [];

  /// 导量数据
  final strongGuideModel = Rx<StrongGuideModel?>(null);

  /// 导量弹窗翻译原文与结果
  final List<TranslateModel> translateList = [];

  final List<TranslateModel> translateList2 = [];

  final List<TranslateModel> translateListItems = [];
  final List<TranslateModel> translateList3 = [];

  /// 显示翻译结果
  bool showTrans = false;

  // banner准备完成
  bool bannerReady = false;
  // 导量准备完成
  bool guideReady = false;

  @override
  void onInit() {
    super.onInit();
    // 监听语言包变化，自动重建导量文案，解决切换语言后红色导量弹窗不更新的问题
    _languageWorker = ever(BHLanguageMar().langMap, (_) {
      if (strongGuideModel.value != null) {
        _buildGuideTexts(strongGuideModel.value!);
        // 切换语言后，清空翻译结果并关闭翻译展示
        for (var item in translateList) {
          item.result = null;
        }
        for (var item in translateList2) {
          item.result = null;
        }
        for (var item in translateListItems) {
          item.result = null;
        }
        for (var item in translateList3) {
          item.result = null;
        }
        showTrans = false;
        update();
      }
    });
  }

  @override
  void onClose() {
    _languageWorker?.dispose();
    super.onClose();
  }

  Future onInitData() {
    bannerReady = false;
    guideReady = false;
    if (_appConfig.isReviewPkg.value) {
      // 审核模式不显示banner，直接拦截
      bannerReady = true;
      guideReady = true;
      return Future.value();
    }
    showTrans = false;
    var list = <Future>[];
    list.add(_onGetBanner());
    if (_appConfig.strategyModel?.isSwitchStrongGuide ?? false) {
      list.add(onGetStrongGuide());
    } else {
      guideReady = true;
    }
    return Future.wait(list);
  }

  /// 获取banner
  Future<void> _onGetBanner() async {
    await _request.bannerInfo(
      onSuccess: (data) {
        bannerReady = true;
        bannerList.clear();
        bannerList.addAll(data);
        _appConfig.homeThirdInUrl.value = '';
        for (var element in bannerList) {
          if (element.bizType == "1") {
            _appConfig.homeThirdInUrl.value = element.jumpUrl ?? '';
            if (element.type == 1) {
              _appConfig.homeThirdInIsOut.value = false;
            } else {
              _appConfig.homeThirdInIsOut.value = true;
            }
          }
        }
        update();
      },
      onFail: (int code, String msg) {},
    );
  }

  /// 获取导量数据
  Future<void> onGetStrongGuide() async {
    await _request.strongGuideConfig(
      onSuccess: (data) {
        guideReady = true;
        strongGuideModel.value = data;
        _buildGuideTexts(data);
        update();
      },
      onFail: (code, msg) {},
    );
  }

  /// 翻译/显示原文
  ///
  var isTransing = false;
  Future onTranslate() async {
    if (showTrans) {
      showTrans = false;
      update();
    } else {
      // 如果有需要翻译的文案还未翻译，则进行翻译，否则直接显示结果
      if (!translateList
              .where((element) => element.translate)
              .every((element) => element.result != null) ||
          !translateList2
              .where((element) => element.translate)
              .every((element) => element.result != null) ||
          !translateList3
              .where((element) => element.translate)
              .every((element) => element.result != null) ||
          !translateListItems
              .where((element) => element.translate)
              .every((element) => element.result != null)) {
        Toast.showLoading(isShowCloseBtn: true,clickMaskDismiss: false, backDismiss: false);
        isTransing = true;
        update();
        for (var item in translateList) {
          if (item.translate) {
            await _translate.trans(
              content: item.content!,
              onSuccess: (data) {
                int index = translateList
                    .indexWhere((element) => element.content == item.content);
                translateList[index].result = data;
                isTransing = false;
                update();
              },
              onFail: (msg) {
                // 翻译失败
                // Toast.dismiss();
                Toast.showMsg("Translation_failed".bhTR);
                isTransing = false;
                update();
              },
            );
          }
        }
        for (var item in translateList2) {
          if (item.translate) {
            await _translate.trans(
              content: item.content!,
              onSuccess: (data) {
                int index = translateList2
                    .indexWhere((element) => element.content == item.content);
                translateList2[index].result = data;
                isTransing = false;
                update();
              },
              onFail: (msg) {
                // 翻译失败
                // Toast.dismiss();
                Toast.showMsg("Translation_failed".bhTR);
                isTransing = false;
                update();
              },
            );
          }
        }
        for (var item in translateList3) {
          if (item.translate) {
            await _translate.trans(
              content: item.content!,
              onSuccess: (data) {
                int index = translateList3
                    .indexWhere((element) => element.content == item.content);
                translateList3[index].result = data;
                isTransing = false;
                update();
              },
              onFail: (msg) {
                // 翻译失败
                // Toast.dismiss();
                Toast.showMsg("Translation_failed".bhTR);
                isTransing = false;
                update();
              },
            );
          }
        }
        for (var item in translateListItems) {
          if (item.translate) {
            await _translate.trans(
              content: item.content!,
              onSuccess: (data) {
                int index = translateListItems
                    .indexWhere((element) => element.content == item.content);
                translateListItems[index].result = data;
                isTransing = false;
                update();
              },
              onFail: (msg) {
                // 翻译失败
                // Toast.dismiss();
                Toast.showMsg("Translation_failed".bhTR);
                isTransing = false;
                update();
              },
            );
          }
        }

        Toast.dismiss();
      }
      showTrans = true;
      update();
    }
  }

  //清空翻译数据
  void onClearTranslate() {
    for (var item in translateList) {
      item.result = null;
    }
    for (var item in translateList2) {
      item.result = null;
    }
    for (var item in translateListItems) {
      item.result = null;
    }
    for (var item in translateList3) {
      item.result = null;
    }
    showTrans = false;
    update();
  }

  void onCopy() {
    //复制邀请码到剪切板
    Clipboard.setData(
        ClipboardData(text: "Your invitation code is:"+(strongGuideModel.value?.inviteCode ?? "")));
    Toast.showMsg("status_copySuccessfully".bhTR);
  }
}

extension _BannerStrongGuideTextBuilder on BannerStrongGuideLogic {
  void _buildGuideTexts(StrongGuideModel data) {
    translateList.clear();
    translateList2.clear();
    translateList3.clear();
    translateListItems.clear();

    if (data.guideMode == 3) {
      // 红色导量弹窗文案（使用当前语言的本地多语言）
      if (data.content?.endsWith("${data.inPkgName}.") ?? false) {
        translateList.add(TranslateModel(
            content: data.content?.substring(
                0, data.content?.indexOf(data.inPkgName.toString()))));
        translateList.add(
          TranslateModel(
            content: "${data.inPkgName}.",
            translate: false,
            textStyle: const TextStyle(
              color: MyColor.orangeFFA766,
            ),
          ),
        );
      } else {
        translateList.add(TranslateModel(content: "strong_guide_main".bhTR.replaceAll("####", "${strongGuideModel.value?.inPkgName ?? ""}")));
      }

      translateList2.add(TranslateModel(
        content: "strong_guide_migration_text".bhTR +
            " ${strongGuideModel.value?.inPkgName ?? ""} " +
            "strong_guide_migration_text2".bhTR,
      ));
      translateList2.add(TranslateModel(content: "\n", translate: false));

      translateListItems.add(TranslateModel(
        content:
            "${strongGuideModel.value?.rewardCoins ?? "0"}\n" +
                "strong_guide_coins_gift".bhTR,
      ));
      translateListItems.add(TranslateModel(
        content: "strong_guide_exclusive".bhTR +
            "\n" +
            "strong_guide_offer".bhTR,
      ));

      translateListItems.add(TranslateModel(
        content: "VIP\n" + "strong_guide_vip_service".bhTR,
      ));

      translateList3.add(TranslateModel(content: "strong_guide_help_text".bhTR));
    } else {
      // 默认导量弹窗
      if (data.content?.endsWith("${data.inPkgName}.") ?? false) {
        translateList.add(TranslateModel(
            content: data.content?.substring(
                0, data.content?.indexOf(data.inPkgName.toString()))));
        translateList.add(
          TranslateModel(
            content: "${data.inPkgName}.",
            translate: false,
            textStyle: const TextStyle(
              color: MyColor.orangeFFA766,
            ),
          ),
        );
      } else {
        translateList.add(TranslateModel(content: data.content));
      }
      translateList.add(TranslateModel(content: "\n\n", translate: false));
      translateList.add(TranslateModel(content: "Your current coin balance ("));
      translateList.add(TranslateModel(
        content: "${_appConfig.userInfo.availableCoins ?? 0}",
        translate: false,
        textStyle: const TextStyle(
          color: MyColor.orangeFFA766,
        ),
      ));
      translateList.add(TranslateModel(
          content: " coins) will be kept in current application,and at "));
      translateList.add(TranslateModel(
        content: data.inPkgName,
        translate: false,
        textStyle: const TextStyle(
          color: MyColor.blue5876FF,
        ),
      ));
      translateList.add(TranslateModel(content: " you will get:"));
      translateList.add(TranslateModel(content: "\n", translate: false));
      translateList.add(TranslateModel(content: "* ", translate: false));
      translateList.add(TranslateModel(
        content: "${data.rewardCoins ?? 0}",
        translate: false,
        textStyle: const TextStyle(
          color: MyColor.redFF5E5E,
        ),
      ));
      translateList.add(TranslateModel(content: " coin rewards\n"));
      translateList.add(TranslateModel(content: "* First recharge discount\n"));
      translateList
          .add(TranslateModel(content: "* Account information synchronization\n"));
      translateList.add(TranslateModel(content: "* The same hot hostesses\n"));
      if (data.inviteCode != null && data.inviteCode!.isNotEmpty) {
        translateList.add(TranslateModel(content: "\n\n", translate: false));
        translateList
            .add(TranslateModel(content: "Fill in your invitation code: "));
        translateList.add(TranslateModel(
          content: data.inviteCode,
          translate: false,
          textStyle: const TextStyle(
            color: MyColor.blue6BE2FF,
          ),
        ));
        translateList.add(TranslateModel(
          content: " [action_copy]",
          translate: false,
          textStyle: const TextStyle(
            color: MyColor.blue6BE2FF,
          ),
        ));
        translateList.add(TranslateModel(content: " on the "));
        translateList.add(TranslateModel(
          content: data.inPkgName,
          translate: false,
          textStyle: const TextStyle(
            color: MyColor.blue6BE2FF,
          ),
        ));
        translateList.add(TranslateModel(
            content:
                " registration page, and all your personal information in the app will be synchronized."));
      }
    }
  }
}
