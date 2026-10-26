
class RobotCQModel {
  String? content;
  int? type; // 0: FAQ, 1: Answer, 2: User
  RobotModel? faqModel;
  FaqInfoList? questionModel;
  bool? isHelp;
  int? isTraning;
  String? tranString;
}

class RobotModel {
  String? content;
  List<FaqInfoList>? faqInfoList;



  RobotModel({this.content, this.faqInfoList});

  RobotModel.fromJson(Map<String, dynamic> json) {
    content = json['content'];
    if (json['faqInfoList'] != null) {
      faqInfoList = <FaqInfoList>[];
      json['faqInfoList'].forEach((v) {
        faqInfoList!.add(FaqInfoList.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['content'] = content;
    if (faqInfoList != null) {
      data['faqInfoList'] = faqInfoList!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FaqInfoList {
  int? code;
  int? handleType;
  String? imageUrl;
  bool? isViewExample;
  MessageAnswer? messageAnswer;
  String? question;
  String? toUrl;
  int? type;

  FaqInfoList(
      {this.code,
        this.handleType,
        this.imageUrl,
        this.isViewExample,
        this.messageAnswer,
        this.question,
        this.toUrl,
        this.type});

  FaqInfoList.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    handleType = json['handleType'];
    imageUrl = json['imageUrl'];
    isViewExample = json['isViewExample'];
    messageAnswer = json['messageAnswer'] != null
        ? MessageAnswer.fromJson(json['messageAnswer'])
        : null;
    question = json['question'];
    toUrl = json['toUrl'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['code'] = code;
    data['handleType'] = handleType;
    data['imageUrl'] = imageUrl;
    data['isViewExample'] = isViewExample;
    if (messageAnswer != null) {
      data['messageAnswer'] = messageAnswer!.toJson();
    }
    data['question'] = question;
    data['toUrl'] = toUrl;
    data['type'] = type;
    return data;
  }
}

class MessageAnswer {
  List<AnswerEventHandleList>? answerEventHandleList;
  String? content;

  MessageAnswer({this.answerEventHandleList, this.content});

  MessageAnswer.fromJson(Map<String, dynamic> json) {
    if (json['answerEventHandleList'] != null) {
      answerEventHandleList = <AnswerEventHandleList>[];
      json['answerEventHandleList'].forEach((v) {
        answerEventHandleList!.add(AnswerEventHandleList.fromJson(v));
      });
    }
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (answerEventHandleList != null) {
      data['answerEventHandleList'] =
          answerEventHandleList!.map((v) => v.toJson()).toList();
    }
    data['content'] = content;
    return data;
  }
}

class AnswerEventHandleList {
  int? handleType;
  String? matchStr;
  String? toUrl;

  AnswerEventHandleList({this.handleType, this.matchStr, this.toUrl});

  AnswerEventHandleList.fromJson(Map<String, dynamic> json) {
    handleType = json['handleType'];
    matchStr = json['matchStr'];
    toUrl = json['toUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['handleType'] = handleType;
    data['matchStr'] = matchStr;
    data['toUrl'] = toUrl;
    return data;
  }
}
