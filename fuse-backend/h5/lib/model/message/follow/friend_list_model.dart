class FriendListModel {
  FriendListModel({
    this.userId,
    this.userType,
    this.nickname,
    this.avatar,
    this.avatarUrl,
    this.gender,
    this.birthday,
    this.age,
    this.language,
    this.country,
    this.about,
    this.isSpecialFollow,
    this.onlineStatus,
    this.level,
    this.isVip,
  });

  FriendListModel.fromJson(dynamic json) {
    userId = json['userId'];
    userType = json['userType'];
    nickname = json['nickname'];
    avatar = json['avatar'];
    avatarUrl = json['avatarUrl'];
    gender = json['gender'];
    birthday = json['birthday'];
    age = json['age'];
    language = json['language'];
    country = json['country'];
    about = json['about'];
    isSpecialFollow = json['isSpecialFollow'];
    onlineStatus = json['onlineStatus'];
    level = json['level'];
    isVip = json['isVip'];
  }

  String? userId;
  int? userType;
  String? nickname;
  String? avatar;
  String? avatarUrl;
  int? gender;
  String? birthday;
  int? age;
  String? language;
  String? country;
  String? about;
  bool? isSpecialFollow;
  String? onlineStatus;
  int? level;
  bool? isVip;

  FriendListModel copyWith({
    String? userId,
    int? userType,
    String? nickname,
    String? avatar,
    String? avatarUrl,
    int? gender,
    String? birthday,
    int? age,
    String? language,
    String? country,
    String? about,
    bool? isSpecialFollow,
    String? onlineStatus,
    int? level,
    bool? isVip,
  }) =>
      FriendListModel(
        userId: userId ?? this.userId,
        userType: userType ?? this.userType,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        gender: gender ?? this.gender,
        birthday: birthday ?? this.birthday,
        age: age ?? this.age,
        language: language ?? this.language,
        country: country ?? this.country,
        about: about ?? this.about,
        isSpecialFollow: isSpecialFollow ?? this.isSpecialFollow,
        onlineStatus: onlineStatus ?? this.onlineStatus,
        level: level ?? this.level,
        isVip: isVip ?? this.isVip,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userId'] = userId;
    map['userType'] = userType;
    map['nickname'] = nickname;
    map['avatar'] = avatar;
    map['avatarUrl'] = avatarUrl;
    map['gender'] = gender;
    map['birthday'] = birthday;
    map['age'] = age;
    map['language'] = language;
    map['country'] = country;
    map['about'] = about;
    map['isSpecialFollow'] = isSpecialFollow;
    map['onlineStatus'] = onlineStatus;
    map['level'] = level;
    map['isVip'] = isVip;
    return map;
  }
}
