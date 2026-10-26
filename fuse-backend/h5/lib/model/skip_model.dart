class VoiceToTextConfig {
  VoiceToTextConfig({
    this.voiceToTextSwitch,
    this.voiceToTextUnitPrice,
  });

  VoiceToTextConfig.fromJson(dynamic json) {
    voiceToTextSwitch = json['voiceToTextSwitch'];
    voiceToTextUnitPrice = json['voiceToTextUnitPrice'];
  }

  bool? voiceToTextSwitch;
  int? voiceToTextUnitPrice;

  VoiceToTextConfig copyWith({
    bool? voiceToTextSwitch,
    int? voiceToTextUnitPrice,
  }) =>
      VoiceToTextConfig(
        voiceToTextSwitch: voiceToTextSwitch ?? this.voiceToTextSwitch,
        voiceToTextUnitPrice: voiceToTextUnitPrice ?? this.voiceToTextUnitPrice,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['voiceToTextSwitch'] = voiceToTextSwitch;
    map['voiceToTextUnitPrice'] = voiceToTextUnitPrice;
    return map;
  }
}

class UserInvitation {
  UserInvitation({
    this.popUpBottom,
    this.popUpContent,
    this.popUpTitle,
    this.shareContent,
    this.tipsContent,
    this.tipsTitle,
  });

  UserInvitation.fromJson(dynamic json) {
    popUpBottom = json['popUpBottom'];
    popUpContent = json['popUpContent'];
    popUpTitle = json['popUpTitle'];
    shareContent = json['shareContent'];
    tipsContent = json['tipsContent'];
    tipsTitle = json['tipsTitle'];
  }

  String? popUpBottom;
  String? popUpContent;
  String? popUpTitle;
  String? shareContent;
  String? tipsContent;
  String? tipsTitle;

  UserInvitation copyWith({
    String? popUpBottom,
    String? popUpContent,
    String? popUpTitle,
    String? shareContent,
    String? tipsContent,
    String? tipsTitle,
  }) =>
      UserInvitation(
        popUpBottom: popUpBottom ?? this.popUpBottom,
        popUpContent: popUpContent ?? this.popUpContent,
        popUpTitle: popUpTitle ?? this.popUpTitle,
        shareContent: shareContent ?? this.shareContent,
        tipsContent: tipsContent ?? this.tipsContent,
        tipsTitle: tipsTitle ?? this.tipsTitle,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['popUpBottom'] = popUpBottom;
    map['popUpContent'] = popUpContent;
    map['popUpTitle'] = popUpTitle;
    map['shareContent'] = shareContent;
    map['tipsContent'] = tipsContent;
    map['tipsTitle'] = tipsTitle;
    return map;
  }
}

class GenderMatchCoin {
  GenderMatchCoin({
    this.bothCoins,
    this.femaleCoins,
    this.goddessCoins,
    this.maleCoins,
    this.vipGoddessCoins,
  });

  GenderMatchCoin.fromJson(dynamic json) {
    bothCoins = json['bothCoins'];
    femaleCoins = json['femaleCoins'];
    goddessCoins = json['goddessCoins'];
    maleCoins = json['maleCoins'];
    vipGoddessCoins = json['vipGoddessCoins'];
  }

  int? bothCoins;
  int? femaleCoins;
  int? goddessCoins;
  int? maleCoins;
  int? vipGoddessCoins;

  /// 女神匹配单次消耗；VIP 优先 [vipGoddessCoins]，否则 [goddessCoins]。
  int goddessMatchCoins({bool hasEquity = false}) {
    if (hasEquity && vipGoddessCoins != null) {
      return vipGoddessCoins!;
    }
    return goddessCoins ?? 0;
  }

  GenderMatchCoin copyWith({
    int? bothCoins,
    int? femaleCoins,
    int? goddessCoins,
    int? maleCoins,
    int? vipGoddessCoins,
  }) =>
      GenderMatchCoin(
        bothCoins: bothCoins ?? this.bothCoins,
        femaleCoins: femaleCoins ?? this.femaleCoins,
        goddessCoins: goddessCoins ?? this.goddessCoins,
        maleCoins: maleCoins ?? this.maleCoins,
        vipGoddessCoins: vipGoddessCoins ?? this.vipGoddessCoins,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['bothCoins'] = bothCoins;
    map['femaleCoins'] = femaleCoins;
    map['goddessCoins'] = goddessCoins;
    map['maleCoins'] = maleCoins;
    map['vipGoddessCoins'] = vipGoddessCoins;
    return map;
  }
}

class FlashChatConfig {
  FlashChatConfig({
    this.isFreeCall,
    this.isSwitch,
    this.residueFreeCallTimes,
  });

  FlashChatConfig.fromJson(dynamic json) {
    isFreeCall = json['isFreeCall'];
    isSwitch = json['isSwitch'];
    residueFreeCallTimes = json['residueFreeCallTimes'];
  }

  bool? isFreeCall;
  bool? isSwitch;
  int? residueFreeCallTimes;

  FlashChatConfig copyWith({
    bool? isFreeCall,
    bool? isSwitch,
    int? residueFreeCallTimes,
  }) =>
      FlashChatConfig(
        isFreeCall: isFreeCall ?? this.isFreeCall,
        isSwitch: isSwitch ?? this.isSwitch,
        residueFreeCallTimes: residueFreeCallTimes ?? this.residueFreeCallTimes,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['isFreeCall'] = isFreeCall;
    map['isSwitch'] = isSwitch;
    map['residueFreeCallTimes'] = residueFreeCallTimes;
    return map;
  }
}

class ClubSubTags {
  ClubSubTags({
    this.about,
    this.code,
    this.name,
  });

  ClubSubTags.fromJson(dynamic json) {
    about = json['about'];
    code = json['code'];
    name = json['name'];
  }

  String? about;
  String? code;
  String? name;

  ClubSubTags copyWith({
    String? about,
    String? code,
    String? name,
  }) =>
      ClubSubTags(
        about: about ?? this.about,
        code: code ?? this.code,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['about'] = about;
    map['code'] = code;
    map['name'] = name;
    return map;
  }
}

class BroadcasterWallTagList {
  BroadcasterWallTagList({
    this.subTagList,
    this.tagName,
  });

  BroadcasterWallTagList.fromJson(dynamic json) {
    subTagList =
        json['subTagList'] != null ? json['subTagList'].cast<String>() : [];
    tagName = json['tagName'];
  }

  List<String>? subTagList;
  String? tagName;

  BroadcasterWallTagList copyWith({
    List<String>? subTagList,
    String? tagName,
  }) =>
      BroadcasterWallTagList(
        subTagList: subTagList ?? this.subTagList,
        tagName: tagName ?? this.tagName,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['subTagList'] = subTagList;
    map['tagName'] = tagName;
    return map;
  }
}

class TagDetails {
  TagDetails({
    this.tag,
    this.tagColor,
    this.tagTip,
  });

  TagDetails.fromJson(dynamic json) {
    tag = json['tag'];
    tagColor = json['tagColor'];
    tagTip = json['tagTip'];
  }

  String? tag;
  String? tagColor;
  String? tagTip;

  TagDetails copyWith({
    String? tag,
    String? tagColor,
    String? tagTip,
  }) =>
      TagDetails(
        tag: tag ?? this.tag,
        tagColor: tagColor ?? this.tagColor,
        tagTip: tagTip ?? this.tagTip,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ubsbontag'] = tag;
    map['tagColor'] = tagColor;
    map['tagTip'] = tagTip;
    return map;
  }
}

class MediaList {
  MediaList({
    this.coins,
    this.isLock,
    this.mediaId,
    this.mediaPath,
    this.mediaType,
    this.mediaUrl,
    this.middleThumbUrl,
    this.sort,
    this.thumbUrl,
    this.userId,
  });

  MediaList.fromJson(dynamic json) {
    coins = json['coins'];
    isLock = json['isLock'];
    mediaId = json['mediaId'];
    mediaPath = json['mediaPath'];
    mediaType = json['mediaType'];
    mediaUrl = json['mediaUrl'];
    middleThumbUrl = json['middleThumbUrl'];
    sort = json['sort'];
    thumbUrl = json['thumbUrl'];
    userId = json['userId'];
  }

  int? coins;
  bool? isLock;
  String? mediaId;
  String? mediaPath;
  String? mediaType;
  String? mediaUrl;
  String? middleThumbUrl;
  int? sort;
  String? thumbUrl;
  String? userId;

  MediaList copyWith({
    int? coins,
    bool? isLock,
    String? mediaId,
    String? mediaPath,
    String? mediaType,
    String? mediaUrl,
    String? middleThumbUrl,
    int? sort,
    String? thumbUrl,
    String? userId,
  }) =>
      MediaList(
        coins: coins ?? this.coins,
        isLock: isLock ?? this.isLock,
        mediaId: mediaId ?? this.mediaId,
        mediaPath: mediaPath ?? this.mediaPath,
        mediaType: mediaType ?? this.mediaType,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        middleThumbUrl: middleThumbUrl ?? this.middleThumbUrl,
        sort: sort ?? this.sort,
        thumbUrl: thumbUrl ?? this.thumbUrl,
        userId: userId ?? this.userId,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['coins'] = coins;
    map['isLock'] = isLock;
    map['mediaId'] = mediaId;
    map['mediaPath'] = mediaPath;
    map['mediaType'] = mediaType;
    map['mediaUrl'] = mediaUrl;
    map['middleThumbUrl'] = middleThumbUrl;
    map['sort'] = sort;
    map['thumbUrl'] = thumbUrl;
    map['userId'] = userId;
    return map;
  }
}

class UserLevelList {
  UserLevelList({
    this.level,
    this.rechargedCoins,
  });

  UserLevelList.fromJson(dynamic json) {
    level = json['level'];
    rechargedCoins = json['rechargedCoins'];
  }

  int? level;
  int? rechargedCoins;

  UserLevelList copyWith({
    int? level,
    int? rechargedCoins,
  }) =>
      UserLevelList(
        level: level ?? this.level,
        rechargedCoins: rechargedCoins ?? this.rechargedCoins,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['level'] = level;
    map['rechargedCoins'] = rechargedCoins;
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

class CustomListItem {
  CustomListItem({
    this.image,
    this.url,
  });

  CustomListItem.fromJson(dynamic json) {
    image = json['image'];
    url = json['url'];
  }

  String? image;
  String? url;

  CustomListItem copyWith({
    String? image,
    String? url,
  }) =>
      CustomListItem(
        image: image ?? this.image,
        url: url ?? this.url,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['image'] = image;
    map['url'] = url;
    return map;
  }
}

class CustomListModel {
  CustomListModel({
    this.num,
    this.show,
    this.content,
  });

  CustomListModel.fromJson(dynamic json) {
    num = json['num'];
    show = json['show'];
    if (json['content'] != null) {
      content = [];
      json['content'].forEach((v) {
        content?.add(CustomListItem.fromJson(v));
      });
    }
  }

  String? num;
  String? show;
  List<CustomListItem>? content;

  CustomListModel copyWith({
    String? num,
    String? show,
    List<CustomListItem>? content,
  }) =>
      CustomListModel(
        num: num ?? this.num,
        show: show ?? this.show,
        content: content ?? this.content,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['num'] = num;
    map['show'] = show;
    if (content != null) {
      map['content'] = content?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}