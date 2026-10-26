import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';


const uuid =  Uuid();

/// 创建多行 JSON
String prettyJson(dynamic message) {
  try {
    var finalMessage = message is String ? jsonDecode(message) : message;
    if (message is FormData) {
      finalMessage = <String, dynamic>{}
        ..addEntries(message.fields)
        ..addEntries(message.files);
    }
    if (finalMessage is Map || finalMessage is Iterable) {
      var spaces = ' ' * 4;
      var encoder = JsonEncoder.withIndent(spaces, (msg) => msg.toString());
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  } catch (e) {
    return message.toString();
  }
}

/// 计算字符串的MD5哈希值。
String MD5(String input) {
  var bytes = utf8.encode(input);
  var digest = md5.convert(bytes);
  return digest.toString();
}

var logger = Logger(filter: MyFilter());

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return false;
    }
    return true;
  }
}