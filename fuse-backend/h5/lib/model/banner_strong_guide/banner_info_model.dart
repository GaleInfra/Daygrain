import 'dart:convert';

class BannerInfoModel {
  int? type;
  String? pic;
  String? jumpUrl;
  String? bizType;
  List<int>? position;

  BannerInfoModel({
    this.type,
    this.pic,
    this.jumpUrl,
    this.bizType,
    this.position,
  });

  BannerInfoModel copyWith({
    int? type,
    String? pic,
    String? jumpUrl,
    String? bizType,
    List<int>? position,
  }) =>
      BannerInfoModel(
        type: type ?? this.type,
        pic: pic ?? this.pic,
        jumpUrl: jumpUrl ?? this.jumpUrl,
        bizType: bizType ?? this.bizType,
        position: position ?? this.position,
      );

  factory BannerInfoModel.fromRawJson(String str) => BannerInfoModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BannerInfoModel.fromJson(Map<String, dynamic> json) => BannerInfoModel(
    type: json["type"],
    pic: json["pic"],
    jumpUrl: json["jumpUrl"],
    bizType: json["bizType"],
    position: json["position"] == null ? [] : List<int>.from(json["position"]!.map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "pic": pic,
    "jumpUrl": jumpUrl,
    "bizType": bizType,
    "position": position == null ? [] : List<dynamic>.from(position!.map((x) => x)),
  };
}
