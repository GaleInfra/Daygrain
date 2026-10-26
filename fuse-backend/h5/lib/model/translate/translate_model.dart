import 'dart:convert';

import 'package:flutter/material.dart';

/// 翻译原文与结果
class TranslateModel {
  String? content;
  String? result;

  /// 是否翻译
  bool translate;

  TextStyle? textStyle;

  TranslateModel({
    this.content,
    this.result,
    this.translate = true,
    this.textStyle,
  });

  TranslateModel copyWith({
    String? content,
    String? result,
    bool? translate,
    TextStyle? textStyle,
  }) =>
      TranslateModel(
        content: content ?? this.content,
        result: result ?? this.result,
        translate: translate ?? this.translate,
        textStyle: textStyle ?? this.textStyle,
      );

  factory TranslateModel.fromRawJson(String str) => TranslateModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory TranslateModel.fromJson(Map<String, dynamic> json) => TranslateModel(
        content: json["content"],
        result: json["result"],
        translate: json['translate'],
      );

  Map<String, dynamic> toJson() => {
        "content": content,
        "result": result,
        "translate": translate,
      };
}
