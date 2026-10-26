import 'on_call_model.dart' as oncall;

class CreateChannelModel {
  CreateChannelModel({
    this.channelName,
    this.callCategory,
    this.clientSessionId,
    this.fromUserId,
    this.toUserId,
    this.h5FromUserId,
    this.h5ToUserId,
    this.unitPrice,
    this.rtcToken,
    this.gender,
    this.age,
    this.userType,
    this.level,
    this.country,
    this.nickname,
    this.avatar,
    this.avatarThumbUrl,
    this.isFriend,
    this.isVip,
    this.isFree,
    this.broadcasterCallNotice,
    this.broadcasterCallDesc,
    this.broadcasterCallDescColourCode,
    this.broadcasterUnitPrice,
    this.chooseVideoSdk,
    this.callFreeSeconds,
    this.isGreenMode,
    this.levelPowerMessageConfig,
    this.command,
  });

  CreateChannelModel.fromJson(dynamic json) {
    channelName = json['channelNamesb'];
    callCategory = json['bscallCategorybo'];
    clientSessionId = json['clientSessionIdubsbon'];
    fromUserId = json['ubsbonfromUserId'];
    toUserId = json['toUserIdbsbo'];
    h5FromUserId = json['h5FromUserId'];
    h5ToUserId = json['h5ToUserId'];
    unitPrice = json['bonunitPriceubs'];
    rtcToken = json['bsrtcTokenbo'];
    gender = json['genderbs'];
    age = json['ageubsbon'];
    userType = json['userTypeubsbon'];
    level = json['levelbs'];
    country = json['bscountrybo'];
    nickname = json['ubsbonnickname'];
    avatar = json['ubsavatarbon'];
    avatarThumbUrl = json['sbavatarThumbUrl'];
    isFriend = json['bsisFriendbo'];
    isVip = json['bsisVip'];
    isFree = json['sisFreeb'];
    broadcasterCallNotice = json['broadcasterCallNoticebobs'];
    broadcasterCallDesc = json['broadcasterCallDesc'];
    broadcasterCallDescColourCode = json['broadcasterCallDescColourCode'];
    broadcasterUnitPrice = json['broadcasterUnitPrice'];
    chooseVideoSdk = json['chooseVideoSdkbobs'];
    callFreeSeconds = json['bocallFreeSecondsbs'];
    isGreenMode = json['isGreenModebonubs'];
    levelPowerMessageConfig = json['bonubslevelPowerMessageConfig'] != null
        ? LevelPowerMessageConfig.fromJson(
            json['bonubslevelPowerMessageConfig'])
        : null;
    command = json['command'];
  }

  String? channelName;
  int? callCategory;
  String? clientSessionId;
  dynamic fromUserId;
  dynamic toUserId;
  String? h5FromUserId;
  String? h5ToUserId;
  int? unitPrice;
  String? rtcToken;
  int? gender;
  int? age;
  int? userType;
  int? level;
  String? country;
  String? nickname;
  String? avatar;
  String? avatarThumbUrl;
  bool? isFriend;
  bool? isVip;
  bool? isFree;
  String? broadcasterCallNotice;
  String? broadcasterCallDesc;
  String? broadcasterCallDescColourCode;
  int? broadcasterUnitPrice;
  int? chooseVideoSdk;
  int? callFreeSeconds;
  bool? isGreenMode;
  LevelPowerMessageConfig? levelPowerMessageConfig;
  String? command;

  CreateChannelModel copyWith({
    String? channelName,
    int? callCategory,
    String? clientSessionId,
    dynamic fromUserId,
    dynamic toUserId,
    String? h5FromUserId,
    String? h5ToUserId,
    int? unitPrice,
    String? rtcToken,
    int? gender,
    int? age,
    int? userType,
    int? level,
    String? country,
    String? nickname,
    String? avatar,
    String? avatarThumbUrl,
    bool? isFriend,
    bool? isVip,
    bool? isFree,
    String? broadcasterCallNotice,
    String? broadcasterCallDesc,
    String? broadcasterCallDescColourCode,
    int? broadcasterUnitPrice,
    int? chooseVideoSdk,
    int? callFreeSeconds,
    bool? isGreenMode,
    LevelPowerMessageConfig? levelPowerMessageConfig,
    String? command,
  }) =>
      CreateChannelModel(
        channelName: channelName ?? this.channelName,
        callCategory: callCategory ?? this.callCategory,
        clientSessionId: clientSessionId ?? this.clientSessionId,
        fromUserId: fromUserId ?? this.fromUserId,
        toUserId: toUserId ?? this.toUserId,
        h5FromUserId: h5FromUserId ?? this.h5FromUserId,
        h5ToUserId: h5ToUserId ?? this.h5ToUserId,
        unitPrice: unitPrice ?? this.unitPrice,
        rtcToken: rtcToken ?? this.rtcToken,
        gender: gender ?? this.gender,
        age: age ?? this.age,
        userType: userType ?? this.userType,
        level: level ?? this.level,
        country: country ?? this.country,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        avatarThumbUrl: avatarThumbUrl ?? this.avatarThumbUrl,
        isFriend: isFriend ?? this.isFriend,
        isVip: isVip ?? this.isVip,
        isFree: isFree ?? this.isFree,
        broadcasterCallNotice:
            broadcasterCallNotice ?? this.broadcasterCallNotice,
        broadcasterCallDesc: broadcasterCallDesc ?? this.broadcasterCallDesc,
        broadcasterCallDescColourCode:
            broadcasterCallDescColourCode ?? this.broadcasterCallDescColourCode,
        broadcasterUnitPrice: broadcasterUnitPrice ?? this.broadcasterUnitPrice,
        chooseVideoSdk: chooseVideoSdk ?? this.chooseVideoSdk,
        callFreeSeconds: callFreeSeconds ?? this.callFreeSeconds,
        isGreenMode: isGreenMode ?? this.isGreenMode,
        levelPowerMessageConfig:
            levelPowerMessageConfig ?? this.levelPowerMessageConfig,
        command: command ?? this.command,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channelNamesb'] = channelName;
    map['bscallCategorybo'] = callCategory;
    map['clientSessionIdubsbon'] = clientSessionId;
    map['ubsbonfromUserId'] = fromUserId;
    map['toUserIdbsbo'] = toUserId;
    map['h5FromUserId'] = h5FromUserId;
    map['h5ToUserId'] = h5ToUserId;
    map['bonunitPriceubs'] = unitPrice;
    map['bsrtcTokenbo'] = rtcToken;
    map['genderbs'] = gender;
    map['ageubsbon'] = age;
    map['userTypeubsbon'] = userType;
    map['levelbs'] = level;
    map['bscountrybo'] = country;
    map['ubsbonnickname'] = nickname;
    map['ubsavatarbon'] = avatar;
    map['sbavatarThumbUrl'] = avatarThumbUrl;
    map['bsisFriendbo'] = isFriend;
    map['bsisVip'] = isVip;
    map['sisFreeb'] = isFree;
    map['broadcasterCallNoticebobs'] = broadcasterCallNotice;
    map['broadcasterCallDesc'] = broadcasterCallDesc;
    map['broadcasterCallDescColourCode'] = broadcasterCallDescColourCode;
    map['broadcasterUnitPrice'] = broadcasterUnitPrice;
    map['chooseVideoSdkbobs'] = chooseVideoSdk;
    map['bocallFreeSecondsbs'] = callFreeSeconds;
    map['isGreenModebonubs'] = isGreenMode;
    if (levelPowerMessageConfig != null) {
      map['bonubslevelPowerMessageConfig'] = levelPowerMessageConfig?.toJson();
    }
    map['command'] = command;
    return map;
  }

  //CreateChannelModel 转 OnCallModel
  oncall.OnCallModel toOnCallModel() {
    return oncall.OnCallModel(
      channelName: channelName,
      callCategory: callCategory,
      clientSessionId: clientSessionId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      h5FromUserId: h5FromUserId,
      h5ToUserId: h5ToUserId,
      unitPrice: unitPrice,
      rtcToken: rtcToken,
      gender: gender,
      age: age,
      userType: userType,
      level: level,
      country: country,
      nickname: nickname,
      avatar: avatar,
      avatarThumbUrl: avatarThumbUrl,
      isFriend: isFriend,
      isVip: isVip,
      isFree: isFree,
      broadcasterCallNotice: broadcasterCallNotice,
      broadcasterCallDesc: broadcasterCallDesc,
      broadcasterCallDescColourCode: broadcasterCallDescColourCode,
      broadcasterUnitPrice: broadcasterUnitPrice,
      chooseVideoSdk: chooseVideoSdk,
      callFreeSeconds: callFreeSeconds,
      isGreenMode: isGreenMode,
      levelPowerMessageConfig: oncall.LevelPowerMessageConfig(
        isOpen: levelPowerMessageConfig?.isOpen,
      ),
      command: command,
    );
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
