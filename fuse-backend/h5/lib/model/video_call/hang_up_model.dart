class HangUpModel {
  HangUpModel({
    this.channelName,
    this.callCategory,
    this.callType,
    this.isQuickMatch,
    this.callMode,
    this.clientSessionId,
    this.fromUserId,
    this.toUserId,
    this.h5FromUserId,
    this.h5ToUserId,
    this.reason,
    this.command,
  });

  HangUpModel.fromJson(dynamic json) {
    channelName = json['channelName'];
    callCategory = json['callCategory'];
    callType = json['callType'];
    isQuickMatch = json['isQuickMatch'];
    callMode = json['callMode'];
    clientSessionId = json['clientSessionId'];
    fromUserId = json['fromUserId'];
    toUserId = json['toUserId'];
    h5FromUserId = json['h5FromUserId'];
    h5ToUserId = json['h5ToUserId'];
    reason = json['reason'];
    command = json['command'];
  }

  String? channelName;
  int? callCategory;
  int? callType;
  bool? isQuickMatch;
  String? callMode;
  String? clientSessionId;
  int? fromUserId;
  int? toUserId;
  String? h5FromUserId;
  String? h5ToUserId;
  int? reason;
  String? command;

  HangUpModel copyWith({
    String? channelName,
    int? callCategory,
    int? callType,
    bool? isQuickMatch,
    String? callMode,
    String? clientSessionId,
    int? fromUserId,
    int? toUserId,
    String? h5FromUserId,
    String? h5ToUserId,
    int? reason,
    String? command,
  }) =>
      HangUpModel(
        channelName: channelName ?? this.channelName,
        callCategory: callCategory ?? this.callCategory,
        callType: callType ?? this.callType,
        isQuickMatch: isQuickMatch ?? this.isQuickMatch,
        callMode: callMode ?? this.callMode,
        clientSessionId: clientSessionId ?? this.clientSessionId,
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        h5FromUserId: h5FromUserId ?? this.h5FromUserId,
        h5ToUserId: h5ToUserId ?? this.h5ToUserId,
        reason: reason ?? this.reason,
        command: command ?? this.command,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channelName'] = channelName;
    map['callCategory'] = callCategory;
    map['callType'] = callType;
    map['isQuickMatch'] = isQuickMatch;
    map['callMode'] = callMode;
    map['clientSessionId'] = clientSessionId;
    map['fromUserId'] = fromUserId;
    map['toUserId'] = toUserId;
    map['h5FromUserId'] = h5FromUserId;
    map['h5ToUserId'] = h5ToUserId;
    map['reason'] = reason;
    map['command'] = command;
    return map;
  }
}
