class BroadcasterModel {
  BroadcasterModel({
    this.about,
    this.activityTagUrl,
    this.age,
    this.analysisLanguage,
    this.applicableTags,
    this.avatar,
    this.avatarMiddleThumbUrl,
    this.middleThumbUrl,
    this.avatarThumbUrl,
    this.avatarMapPath,
    this.callCoins,
    this.country,
    this.followNum,
    this.gender,
    this.hobbies,
    this.isFriend,
    this.isMultiple,
    this.nickname,
    this.serviceEndTime,
    this.serviceStartTime,
    this.status,
    this.unit,
    this.userId,
    this.videoMapPaths,
    this.countryAndEmoji,
  });

  BroadcasterModel.fromJson(dynamic json) {
    about = json['about'];
    activityTagUrl = json['activityTagUrl'];
    age = json['age'];
    analysisLanguage = json['analysisLanguage'];
    applicableTags = json['applicableTags'] != null ? json['applicableTags'].cast<String>() : [];
    avatar = json['avatar'];
    avatarMiddleThumbUrl = json['avatarMiddleThumbUrl'];
    middleThumbUrl = json['middleThumbUrl'];
    avatarThumbUrl = json['avatarThumbUrl'];
    avatarMapPath = json['avatarMapPath'];
    callCoins = json['callCoins'];
    country = json['country'];
    followNum = json['followNum'];
    gender = json['gender'];
    hobbies = json['hobbies'] != null ? json['hobbies'].cast<String>() : [];
    isFriend = json['isFriend'];
    isMultiple = json['isMultiple'];
    nickname = json['nickname'];
    serviceEndTime = json['serviceEndTime'];
    serviceStartTime = json['serviceStartTime'];
    status = json['status'];
    unit = json['unit'];
    userId = json['userId'];
    videoMapPaths = json['videoMapPaths'] != null ? json['videoMapPaths'].cast<String>() : [];
    countryAndEmoji = json['countryAndEmoji'];
  }

  String? about;
  String? activityTagUrl;
  int? age;
  String? analysisLanguage;
  List<String>? applicableTags;
  String? avatar;
  String? avatarMiddleThumbUrl;
  String? middleThumbUrl;
  String? avatarThumbUrl;

  String get displayAvatar {
    if (avatarMiddleThumbUrl != null && avatarMiddleThumbUrl!.isNotEmpty) return avatarMiddleThumbUrl!;
    if (middleThumbUrl != null && middleThumbUrl!.isNotEmpty) return middleThumbUrl!;
    if (avatarThumbUrl != null && avatarThumbUrl!.isNotEmpty) return avatarThumbUrl!;
    return avatar ?? '';
  }
  String? avatarMapPath;
  int? callCoins;
  String? country;
  int? followNum;
  int? gender;
  List<String>? hobbies;
  bool? isFriend;
  bool? isMultiple;
  String? nickname;
  String? serviceEndTime;
  String? serviceStartTime;
  String? status;
  String? unit;
  String? userId;
  List<String>? videoMapPaths;
  String? countryAndEmoji;

  BroadcasterModel copyWith({
    String? about,
    String? activityTagUrl,
    int? age,
    String? analysisLanguage,
    List<String>? applicableTags,
    String? avatar,
    String? avatarMiddleThumbUrl,
    String? middleThumbUrl,
    String? avatarThumbUrl,
    String? avatarMapPath,
    int? callCoins,
    String? country,
    int? followNum,
    int? gender,
    List<String>? hobbies,
    bool? isFriend,
    bool? isMultiple,
    String? nickname,
    String? serviceEndTime,
    String? serviceStartTime,
    String? status,
    String? unit,
    String? userId,
    List<String>? videoMapPaths,
    String? countryAndEmoji,
  }) =>
      BroadcasterModel(
        about: about ?? this.about,
        activityTagUrl: activityTagUrl ?? this.activityTagUrl,
        age: age ?? this.age,
        analysisLanguage: analysisLanguage ?? this.analysisLanguage,
        applicableTags: applicableTags ?? this.applicableTags,
        avatar: avatar ?? this.avatar,
        avatarMiddleThumbUrl: avatarMiddleThumbUrl ?? this.avatarMiddleThumbUrl,
        middleThumbUrl: middleThumbUrl ?? this.middleThumbUrl,
        avatarThumbUrl: avatarThumbUrl ?? this.avatarThumbUrl,
        avatarMapPath: avatarMapPath ?? this.avatarMapPath,
        callCoins: callCoins ?? this.callCoins,
        country: country ?? this.country,
        followNum: followNum ?? this.followNum,
        gender: gender ?? this.gender,
        hobbies: hobbies ?? this.hobbies,
        isFriend: isFriend ?? this.isFriend,
        isMultiple: isMultiple ?? this.isMultiple,
        nickname: nickname ?? this.nickname,
        serviceEndTime: serviceEndTime ?? this.serviceEndTime,
        serviceStartTime: serviceStartTime ?? this.serviceStartTime,
        status: status ?? this.status,
        unit: unit ?? this.unit,
        userId: userId ?? this.userId,
        videoMapPaths: videoMapPaths ?? this.videoMapPaths,
        countryAndEmoji: countryAndEmoji ?? this.countryAndEmoji,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['about'] = about;
    map['activityTagUrl'] = activityTagUrl;
    map['age'] = age;
    map['analysisLanguage'] = analysisLanguage;
    map['applicableTags'] = applicableTags;
    map['avatar'] = avatar;
    map['avatarMiddleThumbUrl'] = avatarMiddleThumbUrl;
    map['middleThumbUrl'] = middleThumbUrl;
    map['avatarThumbUrl'] = avatarThumbUrl;
    map['avatarMapPath'] = avatarMapPath;
    map['callCoins'] = callCoins;
    map['country'] = country;
    map['followNum'] = followNum;
    map['gender'] = gender;
    map['hobbies'] = hobbies;
    map['isFriend'] = isFriend;
    map['isMultiple'] = isMultiple;
    map['nickname'] = nickname;
    map['serviceEndTime'] = serviceEndTime;
    map['serviceStartTime'] = serviceStartTime;
    map['status'] = status;
    map['unit'] = unit;
    map['userId'] = userId;
    map['videoMapPaths'] = videoMapPaths;
    map['countryAndEmoji'] = countryAndEmoji;
    return map;
  }
}
