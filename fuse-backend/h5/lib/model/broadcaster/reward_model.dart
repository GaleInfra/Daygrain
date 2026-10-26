import 'dart:convert';

class RewardModel {
  String? bottomDocument;
  int? coins;
  String? title;

  RewardModel({
    this.bottomDocument,
    this.coins,
    this.title,
  });

  RewardModel copyWith({
    String? bottomDocument,
    int? coins,
    String? title,
  }) =>
      RewardModel(
        bottomDocument: bottomDocument ?? this.bottomDocument,
        coins: coins ?? this.coins,
        title: title ?? this.title,
      );

  factory RewardModel.fromRawJson(String str) => RewardModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory RewardModel.fromJson(Map<String, dynamic> json) => RewardModel(
        bottomDocument: json["bottomDocument"],
        coins: json["coins"],
        title: json["title"],
      );

  Map<String, dynamic> toJson() => {
        "bottomDocument": bottomDocument,
        "coins": coins,
        "title": title,
      };
}
