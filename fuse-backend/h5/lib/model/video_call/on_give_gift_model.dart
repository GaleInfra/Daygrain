class OnGiveGiftModel {
  OnGiveGiftModel({
    this.channelName,
    this.giftCode,
    this.num,
    this.fromUserId,
    this.toUserId,
    this.h5FromUserId,
    this.h5ToUserId,
    this.extraContent,
    this.command,
  });

  OnGiveGiftModel.fromJson(dynamic json) {
    channelName = json['channelName'];
    giftCode = json['giftCode'];
    num = json['num'];
    fromUserId = json['fromUserId'];
    toUserId = json['toUserId'];
    h5FromUserId = json['h5FromUserId'];
    h5ToUserId = json['h5ToUserId'];
    extraContent = json['extraContent'];
    command = json['command'];
  }

  String? channelName;
  String? giftCode;
  int? num;
  int? fromUserId;
  int? toUserId;
  String? h5FromUserId;
  String? h5ToUserId;
  String? extraContent;
  String? command;

  OnGiveGiftModel copyWith({
    String? channelName,
    String? giftCode,
    int? num,
    int? fromUserId,
    int? toUserId,
    String? h5FromUserId,
    String? h5ToUserId,
    String? extraContent,
    String? command,
  }) =>
      OnGiveGiftModel(
        channelName: channelName ?? this.channelName,
        giftCode: giftCode ?? this.giftCode,
        num: num ?? this.num,
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        h5FromUserId: h5FromUserId ?? this.h5FromUserId,
        h5ToUserId: h5ToUserId ?? this.h5ToUserId,
        extraContent: extraContent ?? this.extraContent,
        command: command ?? this.command,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channelName'] = channelName;
    map['giftCode'] = giftCode;
    map['num'] = num;
    map['fromUserId'] = fromUserId;
    map['toUserId'] = toUserId;
    map['h5FromUserId'] = h5FromUserId;
    map['h5ToUserId'] = h5ToUserId;
    map['extraContent'] = extraContent;
    map['command'] = command;
    return map;
  }
}
