class PickUpModel {
  PickUpModel({
    this.channelName,
    this.callCategory,
    this.clientSessionId,
    this.chooseVideoSdk,
    this.rtcToken,
    this.fromUserId,
    this.toUserId,
    this.h5FromUserId,
    this.h5ToUserId,
    this.isFree,
    this.broadcasterCallNotice,
    this.broadcasterCallDesc,
    this.broadcasterCallDescColourCode,
    this.isGreenMode,
    this.callFreeSeconds,
    this.levelPowerMessageConfig,
    this.command,
  });

  PickUpModel.fromJson(dynamic json) {
    channelName = json['channelName'];
    callCategory = json['callCategory'];
    clientSessionId = json['clientSessionId'];
    chooseVideoSdk = json['chooseVideoSdk'];
    rtcToken = json['rtcToken'];
    fromUserId = json['fromUserId'];
    toUserId = json['toUserId'];
    h5FromUserId = json['h5FromUserId'];
    h5ToUserId = json['h5ToUserId'];
    isFree = json['isFree'];
    broadcasterCallNotice = json['broadcasterCallNotice'];
    broadcasterCallDesc = json['broadcasterCallDesc'];
    broadcasterCallDescColourCode = json['broadcasterCallDescColourCode'];
    isGreenMode = json['isGreenMode'];
    callFreeSeconds = json['callFreeSeconds'];
    levelPowerMessageConfig = json['levelPowerMessageConfig'] != null ? LevelPowerMessageConfig.fromJson(json['levelPowerMessageConfig']) : null;
    command = json['command'];
  }

  String? channelName;
  int? callCategory;
  String? clientSessionId;
  int? chooseVideoSdk;
  String? rtcToken;
  int? fromUserId;
  int? toUserId;
  String? h5FromUserId;
  String? h5ToUserId;
  bool? isFree;
  String? broadcasterCallNotice;
  String? broadcasterCallDesc;
  String? broadcasterCallDescColourCode;
  bool? isGreenMode;
  int? callFreeSeconds;
  LevelPowerMessageConfig? levelPowerMessageConfig;
  String? command;

  PickUpModel copyWith({
    String? channelName,
    int? callCategory,
    String? clientSessionId,
    int? chooseVideoSdk,
    String? rtcToken,
    int? fromUserId,
    int? toUserId,
    String? h5FromUserId,
    String? h5ToUserId,
    bool? isFree,
    String? broadcasterCallNotice,
    String? broadcasterCallDesc,
    String? broadcasterCallDescColourCode,
    bool? isGreenMode,
    int? callFreeSeconds,
    LevelPowerMessageConfig? levelPowerMessageConfig,
    String? command,
  }) =>
      PickUpModel(
        channelName: channelName ?? this.channelName,
        callCategory: callCategory ?? this.callCategory,
        clientSessionId: clientSessionId ?? this.clientSessionId,
        chooseVideoSdk: chooseVideoSdk ?? this.chooseVideoSdk,
        rtcToken: rtcToken ?? this.rtcToken,
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        h5FromUserId: h5FromUserId ?? this.h5FromUserId,
        h5ToUserId: h5ToUserId ?? this.h5ToUserId,
        isFree: isFree ?? this.isFree,
        broadcasterCallNotice: broadcasterCallNotice ?? this.broadcasterCallNotice,
        broadcasterCallDesc: broadcasterCallDesc ?? this.broadcasterCallDesc,
        broadcasterCallDescColourCode: broadcasterCallDescColourCode ?? this.broadcasterCallDescColourCode,
        isGreenMode: isGreenMode ?? this.isGreenMode,
        callFreeSeconds: callFreeSeconds ?? this.callFreeSeconds,
        levelPowerMessageConfig: levelPowerMessageConfig ?? this.levelPowerMessageConfig,
        command: command ?? this.command,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channelName'] = channelName;
    map['callCategory'] = callCategory;
    map['clientSessionId'] = clientSessionId;
    map['chooseVideoSdk'] = chooseVideoSdk;
    map['rtcToken'] = rtcToken;
    map['fromUserId'] = fromUserId;
    map['toUserId'] = toUserId;
    map['h5FromUserId'] = h5FromUserId;
    map['h5ToUserId'] = h5ToUserId;
    map['isFree'] = isFree;
    map['broadcasterCallNotice'] = broadcasterCallNotice;
    map['broadcasterCallDesc'] = broadcasterCallDesc;
    map['broadcasterCallDescColourCode'] = broadcasterCallDescColourCode;
    map['isGreenMode'] = isGreenMode;
    map['callFreeSeconds'] = callFreeSeconds;
    if (levelPowerMessageConfig != null) {
      map['levelPowerMessageConfig'] = levelPowerMessageConfig?.toJson();
    }
    map['command'] = command;
    return map;
  }
}

class LevelPowerMessageConfig {
  LevelPowerMessageConfig({
    this.isOpen,
  });

  LevelPowerMessageConfig.fromJson(dynamic json) {
    isOpen = json['isOpen'];
  }

  bool? isOpen;

  LevelPowerMessageConfig copyWith({
    bool? isOpen,
  }) =>
      LevelPowerMessageConfig(
        isOpen: isOpen ?? this.isOpen,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isOpen'] = isOpen;
    return map;
  }
}
