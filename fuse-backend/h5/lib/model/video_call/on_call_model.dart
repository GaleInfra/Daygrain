import 'package:untitled1/utils/bh_platform.dart';

class OnCallModel {
  OnCallModel({
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

  OnCallModel.fromJson(dynamic json) {
    channelName = json['channelName'];
    callCategory = json['callCategory'];
    clientSessionId = json['clientSessionId'];
    fromUserId = json['fromUserId'];
    toUserId = json['toUserId'];
    h5FromUserId = json['h5FromUserId'];
    h5ToUserId = json['h5ToUserId'];
    unitPrice = json['unitPrice'];
    rtcToken = json['rtcToken'];
    gender = json['gender'];
    age = json['age'];
    userType = json['userType'];
    level = json['level'];
    country = json['country'];
    nickname = json['nickname'];
    avatar = json['avatar'];
    avatarThumbUrl = json['avatarThumbUrl'];
    isFriend = json['isFriend'];
    isVip = json['isVip'];
    isFree = json['isFree'];
    broadcasterCallNotice = json['broadcasterCallNotice'];
    broadcasterCallDesc = json['broadcasterCallDesc'];
    broadcasterCallDescColourCode = json['broadcasterCallDescColourCode'];
    broadcasterUnitPrice = json['broadcasterUnitPrice'];
    chooseVideoSdk = json['chooseVideoSdk'];
    callFreeSeconds = json['callFreeSeconds'];
    isGreenMode = json['isGreenMode'];
    levelPowerMessageConfig = json['levelPowerMessageConfig'] != null ? LevelPowerMessageConfig.fromJson(json['levelPowerMessageConfig']) : null;
    command = json['command'];
  }

  get fromUserIdStr {
    return BHPlatform.isWeb ? h5FromUserId ?? fromUserId : fromUserId;
  }

  get toUserIdStr {
    return BHPlatform.isWeb ? h5ToUserId ?? toUserId : toUserId;
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

  OnCallModel copyWith({
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
      OnCallModel(
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
        broadcasterCallNotice: broadcasterCallNotice ?? this.broadcasterCallNotice,
        broadcasterCallDesc: broadcasterCallDesc ?? this.broadcasterCallDesc,
        broadcasterCallDescColourCode: broadcasterCallDescColourCode ?? this.broadcasterCallDescColourCode,
        broadcasterUnitPrice: broadcasterUnitPrice ?? this.broadcasterUnitPrice,
        chooseVideoSdk: chooseVideoSdk ?? this.chooseVideoSdk,
        callFreeSeconds: callFreeSeconds ?? this.callFreeSeconds,
        isGreenMode: isGreenMode ?? this.isGreenMode,
        levelPowerMessageConfig: levelPowerMessageConfig ?? this.levelPowerMessageConfig,
        command: command ?? this.command,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['channelName'] = channelName;
    map['callCategory'] = callCategory;
    map['clientSessionId'] = clientSessionId;
    map['fromUserId'] = fromUserId;
    map['toUserId'] = toUserId;
    map['h5FromUserId'] = h5FromUserId;
    map['h5ToUserId'] = h5ToUserId;
    map['unitPrice'] = unitPrice;
    map['rtcToken'] = rtcToken;
    map['gender'] = gender;
    map['age'] = age;
    map['userType'] = userType;
    map['level'] = level;
    map['country'] = country;
    map['nickname'] = nickname;
    map['avatar'] = avatar;
    map['avatarThumbUrl'] = avatarThumbUrl;
    map['isFriend'] = isFriend;
    map['isVip'] = isVip;
    map['isFree'] = isFree;
    map['broadcasterCallNotice'] = broadcasterCallNotice;
    map['broadcasterCallDesc'] = broadcasterCallDesc;
    map['broadcasterCallDescColourCode'] = broadcasterCallDescColourCode;
    map['broadcasterUnitPrice'] = broadcasterUnitPrice;
    map['chooseVideoSdk'] = chooseVideoSdk;
    map['callFreeSeconds'] = callFreeSeconds;
    map['isGreenMode'] = isGreenMode;
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
