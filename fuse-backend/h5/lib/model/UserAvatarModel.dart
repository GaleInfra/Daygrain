class UserAvatarModel {
  String? userId;
  String? nickname;
  String? avatar;
  String? avatarUrl;

  UserAvatarModel({this.userId, this.nickname, this.avatar, this.avatarUrl});

  UserAvatarModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    nickname = json['nickname'];
    avatar = json['avatar'];
    avatarUrl = json['avatarUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['nickname'] = nickname;
    data['avatar'] = avatar;
    data['avatarUrl'] = avatarUrl;
    return data;
  }
}
