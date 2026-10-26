import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/res/my_keys.dart';
import 'package:untitled1/utils/common_util.dart';
import 'package:untitled1/utils/sp_util.dart';
import 'dart:html' as html;

/// create: 2024/3/15
/// desc: 资源处理工具
class AssetsHandle {
  AssetsHandle._initial();
  static final AssetsHandle _instance = AssetsHandle._initial();
  static AssetsHandle get instance => _instance;

  Future _getPath()async {
    var documents = await getApplicationDocumentsDirectory();
    BaseManager.instance.assetsPrefix = "${documents.path}/";
  }

  Future<bool> handle()async {
    DateTime start = DateTime.now();
    debugPrint("== 开始处理资源 $start ===");
    await _getPath();
    if (SPUtil.getString(MyKeys.handleAssets).isNotEmpty) {
      logger.d("资源已处理");
      return true;
    }
    try {
      String password = _unlock(BaseManager.instance.appInfo.assetsPwdText ?? "", BaseManager.instance.appInfo.assetsPwdPwd ?? "");
      String path = _unlock(BaseManager.instance.appInfo.assetsPathText ?? "", BaseManager.instance.appInfo.assetsPathPwd ?? "");
      var files = await rootBundle.load(path);
      // 获取二进制内容
      Uint8List data = files.buffer.asUint8List().sublist(0);
      // 解压
      await _decode(data, password);
      // 当前已解压
      SPUtil.setString(MyKeys.handleAssets, "true");
      DateTime end = DateTime.now();
      debugPrint("=== 资源处理完成: ${end.difference(start).inMilliseconds}毫秒 ===");
      return true;
    } catch (e) {
      debugPrint("解压错误: $e");
      return false;
    }
  }

  Future _decode(Uint8List data, String pwd)async {
    final zipFile = ZipDecoder().decodeBytes(data, verify: true, password: pwd);
    // 解压文件到磁盘
    for (final file in zipFile) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File("${BaseManager.instance.assetsPrefix}$filename")
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('${BaseManager.instance.assetsPrefix}$filename').createSync(recursive: true);
      }
    }
  }

  // 用于资源解压解密
  String _unlock(String content, String keyStr) {
    var text = utf8.decode(base64.decode(content));
    final key = encrypt.Key.fromUtf8(keyStr);
    final iv = encrypt.IV.fromLength(keyStr.length);
    final tool = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypt64 = tool.decrypt64(text, iv: iv);
    var result = utf8.decode(base64.decode(decrypt64));
    return result;
  }

  //获取当前网页域名
  String getCurrentDomain() {
    return "https://${html.window.location.host}";
  }

  //获取资源域名
  String getAssetsDomain() {
    //如果是本地ip，则返回assets
    if (getCurrentDomain().contains("192.168")) {
      return "";
    }
    return "assets";
  }
  //被动资源域名
  String getPassiveAssetsDomain(String assets) {
    return "${getAssetsDomain()}/$assets";
  }
}