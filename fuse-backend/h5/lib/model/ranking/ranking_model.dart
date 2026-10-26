/// avatar : "string"
/// avatarMapPath : "string"
/// broadcasterId : 0
/// broadcasterName : "string"
/// broadcasterOnlineTime : 0
/// guildId : 0
/// guildName : "string"
/// nickname : "string"
/// sort : 0
/// totalIncomeCoins : 0
/// userId : ""

class RankingModel {
  RankingModel({
    this.avatar,
    this.avatarMapPath,
    this.broadcasterId,
    this.broadcasterName,
    this.broadcasterOnlineTime,
    this.guildId,
    this.guildName,
    this.nickname,
    this.sort,
    this.totalIncomeCoins,
    this.userId,
  });

  RankingModel.fromJson(dynamic json) {
    avatar = json['avatar'];
    avatarMapPath = json['avatarMapPath'];
    broadcasterId = json['broadcasterId'];
    broadcasterName = json['broadcasterName'];
    broadcasterOnlineTime = json['broadcasterOnlineTime'];
    guildId = json['guildId'];
    guildName = json['guildName'];
    nickname = json['nickname'];
    sort = json['sort'];
    totalIncomeCoins = json['totalIncomeCoins'];
    userId = json['userId'];
  }

  String? avatar;
  String? avatarMapPath;
  int? broadcasterId;
  String? broadcasterName;
  int? broadcasterOnlineTime;
  int? guildId;
  String? guildName;
  String? nickname;
  int? sort;
  int? totalIncomeCoins;
  String? userId;

  RankingModel copyWith({
    String? avatar,
    String? avatarMapPath,
    int? broadcasterId,
    String? broadcasterName,
    int? broadcasterOnlineTime,
    int? guildId,
    String? guildName,
    String? nickname,
    int? sort,
    int? totalIncomeCoins,
    String? userId,
  }) =>
      RankingModel(
        avatar: avatar ?? this.avatar,
        avatarMapPath: avatarMapPath ?? this.avatarMapPath,
        broadcasterId: broadcasterId ?? this.broadcasterId,
        broadcasterName: broadcasterName ?? this.broadcasterName,
        broadcasterOnlineTime: broadcasterOnlineTime ?? this.broadcasterOnlineTime,
        guildId: guildId ?? this.guildId,
        guildName: guildName ?? this.guildName,
        nickname: nickname ?? this.nickname,
        sort: sort ?? this.sort,
        totalIncomeCoins: totalIncomeCoins ?? this.totalIncomeCoins,
        userId: userId ?? this.userId,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['avatar'] = avatar;
    map['avatarMapPath'] = avatarMapPath;
    map['broadcasterId'] = broadcasterId;
    map['broadcasterName'] = broadcasterName;
    map['broadcasterOnlineTime'] = broadcasterOnlineTime;
    map['guildId'] = guildId;
    map['guildName'] = guildName;
    map['nickname'] = nickname;
    map['sort'] = sort;
    map['totalIncomeCoins'] = totalIncomeCoins;
    map['userId'] = userId;
    return map;
  }
}
