import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:untitled1/base_manager.dart';

class SafetyUtils {
  //获取AppEncryKey
  static String getAppEncryKey() {
    //获取域名
    String host = BaseManager.instance.appInfo.baseUrl;
    final url = Uri.parse(host);
    if (url.host.isNotEmpty) {
      final domain = url.host;
      //判断是否大于等于32位字节
      if (domain.length >= 32) {
        return domain.substring(0, 32);
      } else {
        //不足32位，补全
        return domain.padRight(32, '0');
      }
    }
    return "";
  }

  // 加密
  static String encrypt(String plainText, String key) {
    final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.ecb));
    final decryted = encrypter.encrypt(plainText);
    return base64.encode(decryted.bytes);
  }

  static String decrypt(String encryptStr, String appEncryKey) {
    final iv = IV.fromUtf8(appEncryKey);
    //AES解密
    //encryptStr 移除 \r\n 字符
    encryptStr = encryptStr.replaceAll(RegExp(r"[\r\n]"), '');
    final encrypter = Encrypter(AES(Key.fromUtf8(appEncryKey), mode: AESMode.ecb, padding: 'PKCS7'));
    try {
      final decrytedList = base64Decode(encryptStr);
      final encrypted = Encrypted(decrytedList);
      final decryted = encrypter.decrypt(encrypted, iv: iv);
      return decryted;
    } catch (e) {
      return encryptStr;
    }
  }
}
