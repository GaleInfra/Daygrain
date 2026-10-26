class VideoCallChannelCreateModel {
  VideoCallChannelCreateModel({
    this.channelName,
    this.fromUserId,
    this.toUserId,
    this.rtcToken,
    this.chooseVideoSdk,
    this.callFreeSeconds,
    this.broadcasterUserName,
    this.isGreenMode,
    this.levelPowerMessageConfig,
    this.unitPrice,
    this.discountedPrice,
    this.callCategory,
  });

  VideoCallChannelCreateModel.fromJson(dynamic json) {
    channelName = json['channelName'];
    fromUserId = json['fromUserId'];
    toUserId = json['toUserId'];
    rtcToken = json['rtcToken'];
    chooseVideoSdk = json['chooseVideoSdk'];
    callFreeSeconds = json['callFreeSeconds'];
    broadcasterUserName = json['broadcasterUserName'];
    isGreenMode = json['isGreenMode'];
    levelPowerMessageConfig = json['levelPowerMessageConfig'] != null ? LevelPowerMessageConfig.fromJson(json['levelPowerMessageConfig']) : null;
    unitPrice = json['unitPrice'];
    discountedPrice = json['discountedPrice'];
    callCategory = json['callCategory'];
  }

  String? channelName;
  String? fromUserId;
  String? toUserId;
  String? rtcToken;
  int? chooseVideoSdk;
  int? callFreeSeconds;
  String? broadcasterUserName;
  bool? isGreenMode;
  LevelPowerMessageConfig? levelPowerMessageConfig;
  int? unitPrice;
  int? discountedPrice;
  int? callCategory;

  VideoCallChannelCreateModel copyWith({
    String? channelName,
    String? fromUserId,
    String? toUserId,
    String? rtcToken,
    int? chooseVideoSdk,
    int? callFreeSeconds,
    String? broadcasterUserName,
    bool? isGreenMode,
    LevelPowerMessageConfig? levelPowerMessageConfig,
    int? unitPrice,
    int? discountedPrice,
    int? callCategory,
  }) =>
      VideoCallChannelCreateModel(
        channelName: channelName ?? this.channelName,
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        rtcToken: rtcToken ?? this.rtcToken,
        chooseVideoSdk: chooseVideoSdk ?? this.chooseVideoSdk,
        callFreeSeconds: callFreeSeconds ?? this.callFreeSeconds,
        broadcasterUserName: broadcasterUserName ?? this.broadcasterUserName,
        isGreenMode: isGreenMode ?? this.isGreenMode,
        levelPowerMessageConfig: levelPowerMessageConfig ?? this.levelPowerMessageConfig,
        unitPrice: unitPrice ?? this.unitPrice,
        discountedPrice: discountedPrice ?? this.discountedPrice,
        callCategory: callCategory ?? this.callCategory,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channelName'] = channelName;
    map['fromUserId'] = fromUserId;
    map['toUserId'] = toUserId;
    map['rtcToken'] = rtcToken;
    map['chooseVideoSdk'] = chooseVideoSdk;
    map['callFreeSeconds'] = callFreeSeconds;
    map['broadcasterUserName'] = broadcasterUserName;
    map['isGreenMode'] = isGreenMode;
    if (levelPowerMessageConfig != null) {
      map['levelPowerMessageConfig'] = levelPowerMessageConfig?.toJson();
    }
    map['unitPrice'] = unitPrice;
    map['discountedPrice'] = discountedPrice;
    map['callCategory'] = callCategory;
    return map;
  }
}

class LevelPowerMessageConfig {
  LevelPowerMessageConfig({
    this.isOpen,
    this.userId,
    this.broadcasterId,
  });

  LevelPowerMessageConfig.fromJson(dynamic json) {
    isOpen = json['isOpen'];
    userId = json['userId'];
    broadcasterId = json['broadcasterId'];
  }

  bool? isOpen;
  String? userId;
  String? broadcasterId;

  LevelPowerMessageConfig copyWith({
    bool? isOpen,
    String? userId,
    String? broadcasterId,
  }) =>
      LevelPowerMessageConfig(
        isOpen: isOpen ?? this.isOpen,
        userId: userId ?? this.userId,
        broadcasterId: broadcasterId ?? this.broadcasterId,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    map['userId'] = userId;
    map['broadcasterId'] = broadcasterId;
    return map;
  }
}
