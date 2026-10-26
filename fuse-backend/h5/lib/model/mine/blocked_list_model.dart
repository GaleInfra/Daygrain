class BlockedListModel {
  BlockedListModel({
    this.nickName,
    this.avatar,
    this.age,
    this.registerCountry,
    this.broadcasterId,
    this.gender,
  });

  BlockedListModel.fromJson(dynamic json) {
    nickName = json['nickName'];
    avatar = json['avatar'];
    age = json['age'];
    registerCountry = json['registerCountry'];
    broadcasterId = json['broadcasterId'];
    gender = json['gender'];
  }

  String? nickName;
  String? avatar;
  int? age;
  String? registerCountry;
  String? broadcasterId;
  int? gender;

  BlockedListModel copyWith({
    String? nickName,
    String? avatar,
    int? age,
    String? registerCountry,
    String? broadcasterId,
    int? gender,
  }) =>
      BlockedListModel(
        nickName: nickName ?? this.nickName,
        avatar: avatar ?? this.avatar,
        age: age ?? this.age,
        registerCountry: registerCountry ?? this.registerCountry,
        broadcasterId: broadcasterId ?? this.broadcasterId,
        gender: gender ?? this.gender,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['nickName'] = nickName;
    map['avatar'] = avatar;
    map['age'] = age;
    map['registerCountry'] = registerCountry;
    map['broadcasterId'] = broadcasterId;
    map['gender'] = gender;
    return map;
  }
}
