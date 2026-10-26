import '../skip_model.dart';

class UserLevelModel {
  UserLevelModel({
    this.level,
    this.rechargedCoins,
    this.needRechargeCoins,
    this.userLevelList,
  });

  UserLevelModel.fromJson(dynamic json) {
    level = json['level'];
    rechargedCoins = json['rechargedCoins'];
    needRechargeCoins = json['needRechargeCoins'];
    if (json['userLevelList'] != null) {
      userLevelList = [];
      json['userLevelList'].forEach((v) {
        userLevelList?.add(UserLevelList.fromJson(v));
      });
    }
  }

  int? level;
  int? rechargedCoins;
  int? needRechargeCoins;
  List<UserLevelList>? userLevelList;

  UserLevelModel copyWith({
    int? level,
    int? rechargedCoins,
    int? needRechargeCoins,
    List<UserLevelList>? userLevelList,
  }) =>
      UserLevelModel(
        level: level ?? this.level,
        rechargedCoins: rechargedCoins ?? this.rechargedCoins,
        needRechargeCoins: needRechargeCoins ?? this.needRechargeCoins,
        userLevelList: userLevelList ?? this.userLevelList,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['level'] = level;
    map['rechargedCoins'] = rechargedCoins;
    map['needRechargeCoins'] = needRechargeCoins;
    if (userLevelList != null) {
      map['userLevelList'] = userLevelList?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
