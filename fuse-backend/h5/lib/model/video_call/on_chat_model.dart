class OnChatModel {
  OnChatModel({
    this.fromUserId,
    this.toUserId,
    this.content,
    this.timestamp,
    this.command,
    this.giftImage,
    this.translate,
  });

  OnChatModel.fromJson(dynamic json) {
    dynamic fromUserIdKey = json['fromUserId'];
    if (fromUserIdKey is String) {
      fromUserIdKey = fromUserIdKey;
    } else if (fromUserIdKey is num) {
      fromUserIdKey = BigInt.from(fromUserIdKey).toString();
    } else {
      fromUserIdKey = "0";
    }
    fromUserId = fromUserIdKey;
    dynamic toUserIdKey = json['toUserId'];
    if (toUserIdKey is String) {
      toUserIdKey = toUserIdKey;
    } else if (toUserIdKey is num) {
      toUserIdKey = BigInt.from(toUserIdKey).toString();
    } else {
      toUserIdKey = "0";
    }
    toUserId = toUserIdKey;
    content = json['content'];
    dynamic timestampKey = json['timestamp'];
    if (timestampKey is String) {
      timestampKey = int.tryParse(timestampKey) ?? 0;
    } else if (timestampKey is int) {
      timestampKey = timestampKey;
    } else {
      timestampKey = 0;
    }
    timestamp = timestampKey;
    command = json['command'];
    giftImage = json['giftImage'];
    translate = json['translate'];
  }

  String? fromUserId;
  String? toUserId;
  String? content;
  int? timestamp;
  String? command;

  /// 自己加的礼物图标
  String? giftImage;

  /// 自己加的翻译后内容
  String? translate;

  OnChatModel copyWith({
    String? fromUserId,
    String? toUserId,
    String? content,
    int? timestamp,
    String? command,
    String? giftImage,
    String? translate,
  }) =>
      OnChatModel(
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        command: command ?? this.command,
        giftImage: giftImage ?? this.giftImage,
        translate: translate ?? this.translate,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['fromUserId'] = fromUserId;
    map['toUserId'] = toUserId;
    map['content'] = content;
    map['timestamp'] = timestamp;
    map['command'] = command;
    map['giftImage'] = giftImage;
    map['translate'] = translate;
    return map;
  }

  bool getOperator(Object other) => other is OnChatModel && runtimeType == other.runtimeType && content == other.content && timestamp == other.timestamp;
}
