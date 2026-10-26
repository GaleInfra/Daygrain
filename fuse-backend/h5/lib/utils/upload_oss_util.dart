import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:untitled1/utils/web_anchored_image_picker.dart';

import 'package:dio/dio.dart';
import 'package:get/get.dart' as get_x;
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/common_logic/app_config_manager.dart';
import 'package:untitled1/js/rc_manager_js.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/model/mine/user_oss_policy_model.dart';
import 'package:untitled1/net/request_repository.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/js_utils.dart';
import 'package:uuid/uuid.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../model/mine/upload_oss_model.dart';
import '../res/my_color.dart';
import 'permission_util.dart';
import 'toast.dart';
import 'dart:html' as html;
import 'dart:math' as math;

/// create: 2023/5/12
/// desc: 上传资源工具
class UploadUtil {
  /// 选择图片
  /// [maxAssets] 最大选择资源数
  static Future upload({
    int maxAssets = 1,
    List<AssetEntity>? selectedAssets,
    Function(List<AssetEntity>? result)? onAssetCall,
    Function(List<File>? result)? onFileCall,
  }) async {
    bool permissionResult = await requestPhoto();
    if (!permissionResult) {
      return;
    }
    try {
      final List<AssetEntity>? result = await AssetPicker.pickAssets(
        get_x.Get.context!,
        pickerConfig: AssetPickerConfig(
          selectedAssets: selectedAssets,
          maxAssets: maxAssets,
          requestType: RequestType.image,
          themeColor: MyColor.themeColor1E2440,
        ),
      );
      if (result == null || result.isEmpty) {
        return;
      }
      List<File> files = [];
      for (var item in result) {
        File? file = await item.file;
        files.add(file!);
      }
      onAssetCall?.call(result);
      onFileCall?.call(files);
    } catch (e) {
      logger.e("选择图片错误===> ${e.toString()}");
    }
  }

  /// 压缩图片到指定尺寸
  // static Future<Uint8List> _compressImageWeb(Uint8List imageData) async {
  //   try {
  //     if (imageData.length < 200 * 1024) { // 小于200KB不压缩
  //       return imageData;
  //     }
  //     var kkss = imageData.length / 1024;
  //     print("压缩后1");
  //     // 解码图像
  //     img.Image originalImage = img.decodeImage(imageData)!;
  //     print("压缩后2");
  //     // 计算宽高比
  //     double widthRatio = get_x.Get.width / originalImage.width;
  //     double heightRatio = get_x.Get.height / originalImage.height;
  //
  //     // 选择较小的比例，保持图像纵横比
  //     double ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio;
  //     int newWidth = (originalImage.width * ratio).round();
  //     int newHeight = (originalImage.height * ratio).round();
  //
  //     // 调整大小
  //     img.Image resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);
  //     print("压缩后3");
  //     // 将调整后的图像编码为 PNG 或 JPEG 格式
  //     Uint8List compressedData = img.encodePng(resizedImage); // 选择 JPEG 格式并设置质量
  //     var kksss2 = compressedData.length / 1024;
  //     print("压缩后$kkss -- $kksss2");
  //     return compressedData;
  //   }catch (e) {
  //     return imageData;
  //   }
  //
  // }
  //

  static Future<Uint8List> compressImageWeb(Uint8List imageData, {int quality = 50}) async {
    try {
      var maxWidth = get_x.Get.width;
      var maxHeight = get_x.Get.height;
      // 对于小图片，不进行压缩
      if (imageData.length < 200 * 1024) {
        return imageData;
      }
      // 创建Blob URL
      final blob = html.Blob([imageData]);
      final url = html.Url.createObjectUrl(blob);

      // 创建图片元素并加载图像
      final img = html.ImageElement();
      final completer = Completer<void>();
      img.onLoad.listen((event) => completer.complete());
      img.onError.listen((event) => completer.completeError('图片加载失败'));
      img.src = url;
      await completer.future;

      // 计算新尺寸
      int newWidth = img.naturalWidth ?? 0;
      int newHeight = img.naturalHeight ?? 0;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        // 计算宽高比
        final widthRatio = maxWidth / newWidth;
        final heightRatio = maxHeight / newHeight;

        // 选择较小的比例，保持图像纵横比
        final ratio = math.min(widthRatio, heightRatio);

        newWidth = (newWidth * ratio).round();
        newHeight = (newHeight * ratio).round();
      }
      //计算正方形头像尺寸
      final size = math.min(newWidth, newHeight);

      // 创建Canvas
      final canvas = html.CanvasElement(width: size, height: size);
      final ctx = canvas.context2D;

      // 绘制图像
      ctx.drawImageScaled(img, 0, 0, newWidth, newHeight);

      // 将Canvas内容转为Blob
      final completer2 = Completer<Uint8List>();
      final qualityValue = quality / 100; // 转换为0-1范围

      canvas.toBlob('image/jpeg', qualityValue).then((blob) {
        final reader = html.FileReader();
        reader.onLoadEnd.listen((event) {
          final result = reader.result as String;
          // 解析base64
          final bytes = base64Decode(result.split(',').last);
          completer2.complete(bytes);
                });
        reader.readAsDataUrl(blob);
      });

      // 释放资源
      html.Url.revokeObjectUrl(url);

      final result = await completer2.future;
      // Toast.showMsg("压缩后：${imageData.length / 1024}kb -- /${result.length / 1024}kb");
      return result.length < imageData.length ? result : imageData;
    } catch (e) {
      logger.e("浏览器压缩图片错误: ${e.toString()}");
      return imageData; // 压缩失败返回原图
    }
  }

  /// 选择图片
  /// [maxAssets] 最大选择资源数
  static Future uploadWeb({
    int maxAssets = 1,
    Function(List<Uint8List>? bytes)? onFileCall,
    bool compress = true, // 是否压缩
  }) async {
    try {
      if (BaseManager.instance.appInfo.sdkVersion.isNotEmpty) {
        final completer = Completer<List<Uint8List>>();

        JSRongCloudManager.selectImage(BHCallbackWeb(onSuccess: (u) async {
          List<Uint8List> bytesMaxList = [];
          if (u is String) {
            if (u.isNotEmpty) {
              Uint8List imageBytes = base64Decode(u);

              // 压缩图片
              if (compress) {
                imageBytes = await compressImageWeb(imageBytes);
              }

              bytesMaxList.add(imageBytes);
            }
          }
          completer.complete(bytesMaxList);
        }, onError: (data) {
          completer.complete([]);
        }).toJS());

        List<Uint8List> bytesMaxList = await completer.future;
        onFileCall?.call(bytesMaxList);
      } else {
        Uint8List? bytesMaxList = await WebAnchoredImagePicker.getImageAsBytes();
        if (bytesMaxList != null) {
          onFileCall?.call([bytesMaxList]);
          return;
        }
        onFileCall?.call([]);
      }
    } catch (e) {
      logger.e("选择图片错误===> ${e.toString()}");
      onFileCall?.call([]);
    }
  }

  /// 选择并上传资源到oss云
  /// [maxAssets] 最大选择资源数
  /// [updateRequest] 暴露数据给外部的更新接口，如更新头像接口，当外部的更新接口报错时请抛出异常，以便内部接收管理
  static Future selectAndUploadOSS({
    int maxAssets = 1,
    CancelToken? cancelToken,
    required UpdateRequest updateRequest,
  }) async {
    try {
      /// 头像文件
      // html.File? avatarFile;
      Uint8List? avatarBytes;
      await uploadWeb(
        maxAssets: 1,
        onFileCall: (bytes) async {
          // avatarFile = result?.first;
          avatarBytes = bytes?.first;
        },
      );
      if (avatarBytes == null) {
        return;
      }
      cancelToken ??= CancelToken();
      Toast.showLoading(onDismiss: () {
        cancelToken?.cancel('cancel request');
      });

// 更新头像
      await UploadUtil.uploadOSSWeb(
        imageBytes: avatarBytes!,
        cancelToken: cancelToken,
        updateRequest: updateRequest,
      );
    } catch (e) {
      logger.e("上传失败===> ${e.toString()}");
    } finally {
      Toast.dismiss();
    }
  }

  /// 上传资源到OSS云
  /// [filePath] 文件路径
  /// [updateRequest] 暴露数据给外部的更新接口，如更新头像接口，当外部的更新接口报错时请抛出异常，以便内部接收管理
  static Future uploadOSS({
    required String filePath,
    CancelToken? cancelToken,
    required UpdateRequest updateRequest,
  }) async {
    final request = get_x.Get.find<RequestRepository>();
    cancelToken ??= CancelToken();
    // oss权限数据
    UserOssPolicyModel? model;
    // 获取oss权限
    await request.userOssPolicy(
      cancelToken: cancelToken,
      onSuccess: (data) {
        model = data;
      },
      onFail: (code, msg) {
        Toast.showMsg("error_network".bhTR);
        throw Exception(msg);
      },
    );
    // 上传到oss后到数据
    UploadOssModel? uploadOssModel;
    // 上传到oss
    await request.uploadOSS(
      cancelToken: cancelToken,
      formData: FormData.fromMap({
        "ossaccessKeyId": model?.accessKeyId,
        "policy": model?.policy,
        "signature": model?.signature,
        "key": _getOSSKey(model?.dir, basename(filePath)),
        "callback": model?.callback,
        "file": MultipartFile.fromFileSync(filePath),
      }),
      url: model?.host ?? "",
      onSuccess: (data) async {
        uploadOssModel = data;
      },
      onFail: (code, msg) {
        Toast.showMsg("error_network".bhTR);
        throw Exception(msg);
      },
    );
    await updateRequest(uploadOssModel, cancelToken);
  }

  static Future uploadOSSWeb2({
    required String fileName,
    required Uint8List bytes,
    CancelToken? cancelToken,
    required UpdateRequest updateRequest,
  }) async {
    final request = get_x.Get.find<RequestRepository>();
    cancelToken ??= CancelToken();
    final appConfig = get_x.Get.find<AppConfigManager>();
    // oss权限数据
    UserOssPolicyModel? model;
    if (appConfig.ossPolicyModel != null) {
      model = appConfig.ossPolicyModel;
    } else {
      // 获取oss权限
      await request.userOssPolicy(
        cancelToken: cancelToken,
        onSuccess: (data) {
          model = data;
          appConfig.ossPolicyModel = model;
        },
        onFail: (code, msg) {
          Toast.showMsg("error_network".bhTR);
          throw Exception(msg);
        },
      );
    }

    // 上传到oss后到数据
    UploadOssModel? uploadOssModel;
    // 上传到oss
    await request.uploadOSS(
      cancelToken: cancelToken,
      formData: FormData.fromMap({
        "ossaccessKeyId": model?.accessKeyId,
        "policy": model?.policy,
        "signature": model?.signature,
        "key": _getOSSKey(model?.dir, fileName),
        "callback": model?.callback,
        "file": MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      }),
      url: model?.host ?? "",
      onSuccess: (data) async {
        uploadOssModel = data;
      },
      onFail: (code, msg) {
        Toast.showMsg("error_network".bhTR);
        throw Exception(msg);
      },
    );
    await updateRequest(uploadOssModel, cancelToken);
  }

  /// 上传资源到OSS云
  /// [filePath] 文件路径
  /// [updateRequest] 暴露数据给外部的更新接口，如更新头像接口，当外部的更新接口报错时请抛出异常，以便内部接收管理
  static Future uploadOSSWeb({
    required Uint8List imageBytes,
    CancelToken? cancelToken,
    required UpdateRequest updateRequest,
  }) async {
    final request = get_x.Get.find<RequestRepository>();
    cancelToken ??= CancelToken();
    // oss权限数据
    UserOssPolicyModel? model;
    final appConfig = get_x.Get.find<AppConfigManager>();
    if (appConfig.ossPolicyModel != null) {
      model = appConfig.ossPolicyModel;
    } else {
      // 获取oss权限
      await request.userOssPolicy(
        cancelToken: cancelToken,
        onSuccess: (data) {
          model = data;
        },
        onFail: (code, msg) {
          Toast.showMsg("error_network".bhTR);
          throw Exception(msg);
        },
      );
    }
    final fileName = const Uuid().v1();
    // 上传到oss后到数据
    UploadOssModel? uploadOssModel;
    // 上传到oss
    await request.uploadOSS(
      cancelToken: cancelToken,
      formData: FormData.fromMap({
        "ossaccessKeyId": model?.accessKeyId,
        "policy": model?.policy,
        "signature": model?.signature,
        "key": _getOSSKey(model?.dir, fileName),
        "callback": model?.callback,
        "file": MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
        ),
      }),
      url: model?.host ?? "",
      onSuccess: (data) async {
        uploadOssModel = data;
      },
      onFail: (code, msg) {
        Toast.showMsg("error_network".bhTR);
        throw Exception(msg);
      },
    );
    await updateRequest(uploadOssModel, cancelToken);
  }

  /// 获取文件保存路径
  static String _getOSSKey(String? dir, String? fileName) {
    if ((dir?.isEmpty ?? true) || (fileName?.isEmpty ?? true)) {
      return "";
    }
    int suffixIndex = fileName?.lastIndexOf(".") ?? -1;
    String fileType = suffixIndex > 0 ? fileName?.substring(suffixIndex) ?? "" : "";
    return "$dir${DateTime.now().millisecondsSinceEpoch}$fileType";
  }
}

typedef UpdateRequest = Future Function(UploadOssModel? model, CancelToken cancelToken);

typedef _ByteResult = FutureOr<List<int>>;

extension on html.File {
  Future<Uint8List> asBytes() async {
    final bytesFile = Completer<List<int>>();
    final reader = html.FileReader();
    reader.onLoad.listen(
      (_) {
        final result = reader.result;
        if (result is! _ByteResult?) {
          bytesFile.completeError('Result is not a byte result');
          return;
        }

        bytesFile.complete(result);
      },
    );
    reader.readAsArrayBuffer(this);
    return Uint8List.fromList(await bytesFile.future);
  }
}
