import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled1/base/get_base_controller.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/config/route.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/date_time_util.dart';
import 'package:untitled1/utils/toast.dart';
import 'package:untitled1/utils/upload_oss_util.dart';
import 'package:uuid/uuid.dart';

import '../../../model/skip_model.dart';

class ModifyInfoLogic extends GetBaseController {
  final appConfig = Get.find<AppConfigManager>();

  /// 头像文件
  Uint8List? avatarBytes;

  /// 名字输入框控制器
  final TextEditingController nameTEC = TextEditingController();

  /// 生日
  String birthday = "";

  /// 国家
  String country = "";

  // String countryName = "";

  /// 图片资源，会有两种格式，一种本地图片，一种网络图片
  /// 本地图片为修改时选择的图片
  final List<String> imageList = [];
  final Map<String, Uint8List> bytesList = {};

  /// 个签
  final TextEditingController aboutTEC = TextEditingController();

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    logHandle.initLog('profile_edit');
    //提前请求策略
    request.userOssPolicy(
      onSuccess: (data) {
        appConfig.ossPolicyModel = data;
      },
      onFail: (code, msg) {},
    );
  }

  @override
  void onReady() {
    nameTEC.text = appConfig.userInfo.nickname ?? "";
    birthday = appConfig.userInfo.birthday ?? DateTimeUtil.getDateTimeStr();
    country = appConfig.userInfo.country ?? "";
    imageList.addAll(appConfig.userInfo.mediaList?.where((element) => element.mediaType == "photo").map((e) => e.mediaUrl!).toList() ?? []);
    aboutTEC.text = appConfig.userInfo.about ?? "";
    update();
    super.onReady();
  }

  /// 选择头像
  void onSelectAvatar() async {
    await UploadUtil.uploadWeb(
      maxAssets: 1,
      onFileCall: (bytes) async {
        avatarBytes = bytes?.first;
        update();
        _onUpdateAvatar();
      },
    );
  }

  /// 修改生日
  void onModifyBirthday(BuildContext context) async {
    // Get.toNamed(RoutePath.selectCountryPage);

    DateTime? result = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(birthday),
      firstDate: DateTime(DateTime.now().year - 100),
      lastDate: DateTime(DateTime.now().year - 18),
    );
    if (result != null) {
      birthday = DateTimeUtil.getDateTimeStr(dateTime: result);
      update();
    }
  }

  void onSelectCountry() async {
    final result = await Get.toNamed(RoutePath.selectCountryPage, arguments: country);
    if (result != null) {
      country = result["name"] ?? country;
      // countryName = result.name; // 添加一个新属性存储国家名称
      update();
    }
  }

  /// 更改城市选择
  // void onSelectCountry(String countryCode) {
  //   country = countryCode;
  //   update();
  // }

  /// 选择图片
  void onSelectImage() async {
    List<String> names = [];
    await UploadUtil.uploadWeb(
      maxAssets: 4 - imageList.length,
      onFileCall: (bytes) {
        for (var i = 0; i < bytes!.length; i++) {
          names.add("img_${const Uuid().v1()}");
          bytesList[names[i]] = bytes[i];
        }
      },
    );
    if (names.isNotEmpty) {
      imageList.addAll(names);
      _onUpdateMedia();
    }
    update();
  }

  /// 删除图片
  void onDelImage(int index) async {
    imageList.removeAt(index);
    await _onUpdateMedia(isDelete: true);
    update();
  }

  /// 保存
  Future onSave() async {
    if (nameTEC.text.isEmpty) {
      Toast.showMsg("error_pleaseEnterName".bhTR);
      return;
    }
    try {
      Toast.showLoading(
        clickMaskDismiss: false,
        onDismiss: () {},
      );
      // 保存数据
      await _onUpdateInfo();
      // 更新头像
      // await _onUpdateAvatar(cancelToken);
      // 更新媒体资源
      // await _onUpdateMedia(cancelToken);
      appConfig.onGetInfo();
      Toast.dismiss();
      Toast.showMsg("status_editSuccessfully".bhTR);
      Get.back();
    } catch (e) {
      Toast.showMsg(e.toString());
      logger.e("修改个人资料错误===> ${e.toString()}");
    } finally {
      Toast.dismiss();
    }
  }

  /// 保存数据
  Future _onUpdateInfo() async {
    await request.userSaveUserInfo(
      nickName: nameTEC.text,
      birthday: birthday,
      country: country,
      about: aboutTEC.text,
      language: appConfig.userInfo.language ?? "",
      onSuccess: (data) {},
      onFail: (code, msg) {
        throw Exception(msg);
      },
    );
  }

  /// 更新头像
  Future _onUpdateAvatar() async {
    if (avatarBytes != null) {
      // 更新头像
      Toast.showLoading(
        clickMaskDismiss: false,
        isShowCloseBtn: true,
        onDismiss: () {},
      );
      try {
        await UploadUtil.uploadOSSWeb2(
          fileName: const Uuid().v1(),
          bytes: avatarBytes!,
          updateRequest: (model, cancelToken) async {
            Toast.dismiss();
            request.userUpdateAvatar(
              avatar: model?.filename ?? "",
              cancelToken: cancelToken,
              onSuccess: (data) {
                appConfig.saveUserInfo(
                  appConfig.userInfo.copyWith(
                    avatar: data.mediaPath,
                    avatarUrl: data.mediaUrl,
                    avatarThumbUrl: data.middleThumbUrl,
                  ),
                );
              },
              onFail: (code, msg) {
                //上传失败
                Toast.showMsg("Image upload failed".bhTR);
                throw Exception(msg);
              },
            );
          },
        );

        // await UploadUtil.uploadOSSWeb2(
        //   file: avatarFile!,
        //   updateRequest: (model, cancelToken) async {
        //     Toast.dismiss();
        //     request.userUpdateAvatar(
        //       avatar: model?.filename ?? "",
        //       cancelToken: cancelToken,
        //       onSuccess: (data) {
        //
        //         appConfig.saveUserInfo(
        //           appConfig.userInfo.copyWith(
        //             avatar: data.mediaPath,
        //             avatarUrl: data.mediaUrl,
        //             avatarThumbUrl: data.middleThumbUrl,
        //           ),
        //         );
        //       },
        //       onFail: (code, msg) {
        //
        //         //上传失败
        //         Toast.showMsg("Image upload failed".bhTR);
        //         throw Exception(msg);
        //       },
        //     );
        //   },
        // );
      } catch (e) {
        Toast.dismiss();
        Toast.showMsg("Image upload failed".bhTR);
      }
    }
  }

  /// 更新媒体资源
  Future _onUpdateMedia({bool isDelete = false}) async {
    final mediaList = <MediaList>[];
    mediaList.addAll(appConfig.userInfo.mediaList?.where((element) => element.mediaType == "photo").toList() ?? []);
    // 更新媒体数据
    if (!isDelete) {
      int index = 0;
      for (String path in imageList) {
        if (path.startsWith("img_") && bytesList[path] != null) {
          // 用户数据中不存在该路径，则添加
          Toast.showLoading(
            clickMaskDismiss: false,
            isShowCloseBtn: true,
            onDismiss: () {},
          );
          try {
            await UploadUtil.uploadOSSWeb2(
              fileName: path,
              bytes: bytesList[path]!,
              updateRequest: (model, cancelToken) async {
                await request.userUpdateMedia(
                    actionType: 1,
                    coins: 0,
                    deleteMediaId: "0",
                    mediaPath: model?.filename ?? "",
                    mediaType: "photo",
                    replaceMediaId: "0",
                    onSuccess: (data) {
                      // Toast.dismiss();
                      for (dynamic item in data) {
                        MediaList newModel = MediaList.fromJson(item);
                        if (model?.filename == newModel.mediaPath) {
                          imageList[index] = newModel.mediaUrl ?? "";
                        }
                      }
                      update();
                      appConfig.onGetInfo();
                    },
                    onFail: (code, msg) {
                      // Toast.dismiss();
                      imageList.removeAt(index);
                      Toast.showMsg("Image upload failed".bhTR);
                    });
              },
            );
          } catch (e) {
            Toast.dismiss();
            Toast.showMsg("Image upload failed".bhTR);
            throw Exception(e);
          }
        }
        index++;
      }
      Toast.dismiss();
    }

    // 删除媒体数据
    if (isDelete) {
      for (MediaList item in mediaList) {
        // 新的资源中不存在旧资源，说明被删掉了
        if (!imageList.any((element) => element == item.mediaUrl)) {
          try {
            Toast.showLoading(
              clickMaskDismiss: false,
              isShowCloseBtn: true,
              onDismiss: () {},
            );
            await request.userUpdateMedia(
                actionType: 3,
                coins: item.coins ?? 0,
                deleteMediaId: item.mediaId ?? "",
                mediaPath: item.mediaPath ?? "",
                mediaType: "photo",
                replaceMediaId: item.mediaId ?? "",
                onSuccess: (data) {
                  appConfig.onGetInfo();
                },
                onFail: (code, msg) {});
          } catch (e) {
            Toast.dismiss();
            throw Exception(e);
          }
        }
      }
      Toast.dismiss();
    }
  }
}
