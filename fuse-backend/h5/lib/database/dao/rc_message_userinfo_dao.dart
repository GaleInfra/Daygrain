class RcMessageUserinfoDao {
  RcMessageUserinfoDao({
    this.userId,
    this.nickname,
    this.avatar,
  });

  RcMessageUserinfoDao.fromJson(dynamic json) {
    userId = json['userId'];
    nickname = json['nickname'];
    avatar = json['avatar'];
  }

  String? userId;
  String? nickname;
  String? avatar;

  RcMessageUserinfoDao copyWith({
    String? userId,
    String? nickname,
    String? avatar,
  }) =>
      RcMessageUserinfoDao(
        userId: userId ?? this.userId,
        nickname: nickname ?? this.nickname,
        avatar: avatar ?? this.avatar,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['userId'] = userId;
    map['nickname'] = nickname;
    map['avatar'] = avatar;
    return map;
  }
}
