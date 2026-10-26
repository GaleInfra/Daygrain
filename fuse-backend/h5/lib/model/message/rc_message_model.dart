import 'package:untitled1/js/Model/JSConversation.dart';

/// create: 2023/5/18
/// desc: 封装融云消息，主要用于私聊页，包括了一层添加翻译后文本
class RCMessageModel {
  /// 消息本体
  late JSMessage message;
  //翻译状态 0 未翻译 1 翻译中 2 翻译完成 3 翻译失败
  TranslateStatus translateStatus = TranslateStatus.none;

  /// 翻译后文本
  String? translate;

  RCMessageModel({required this.message, this.translate});
}

//翻译状态枚举
enum TranslateStatus { none, translating, translateSuccess, translateFail }
