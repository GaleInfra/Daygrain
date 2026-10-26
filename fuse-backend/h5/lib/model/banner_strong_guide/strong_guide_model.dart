// To parse this JSON data, do
//
//     final strongGuideModel = strongGuideModelFromJson(jsonString);

import 'dart:convert';

class StrongGuideModel {
  String? pkgname;
  int? source;
  String? url;
  String? iosAppId;
  String? content;
  String? inPkgName;
  String? inIcon;
  int? rewardCoins;
  String? inviteCode;
  int? nativeRechargeRedirect;
  int? guideMode;

  StrongGuideModel({
    this.pkgname,
    this.source,
    this.url,
    this.iosAppId,
    this.content,
    this.inPkgName,
    this.inIcon,
    this.rewardCoins,
    this.inviteCode,
    this.nativeRechargeRedirect,
    this.guideMode,
  });

  StrongGuideModel copyWith({
    String? pkgname,
    int? source,
    String? url,
    String? iosAppId,
    String? content,
    String? inPkgName,
    String? inIcon,
    int? rewardCoins,
    String? inviteCode,
    int? nativeRechargeRedirect,
    int? guideMode,
  }) =>
      StrongGuideModel(
        pkgname: pkgname ?? this.pkgname,
        source: source ?? this.source,
        url: url ?? this.url,
        iosAppId: iosAppId ?? this.iosAppId,
        content: content ?? this.content,
        inPkgName: inPkgName ?? this.inPkgName,
        inIcon: inIcon ?? this.inIcon,
        rewardCoins: rewardCoins ?? this.rewardCoins,
        inviteCode: inviteCode ?? this.inviteCode,
        nativeRechargeRedirect:
            nativeRechargeRedirect ?? this.nativeRechargeRedirect,
        guideMode: guideMode ?? this.guideMode,
      );

  factory StrongGuideModel.fromRawJson(String str) =>
      StrongGuideModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory StrongGuideModel.fromJson(Map<String, dynamic> json) =>
      StrongGuideModel(
        pkgname: json["pkgname"],
        source: json["source"],
        url: json["url"],
        iosAppId: json["iosAppId"],
        content: json["content"],
        inPkgName: json["inPkgName"],
        inIcon: json["inIcon"],
        rewardCoins: json["rewardCoins"],
        inviteCode: json["inviteCode"],
        nativeRechargeRedirect: json["nativeRechargeRedirect"],
        guideMode: json["guideMode"],
      );

  Map<String, dynamic> toJson() => {
        "pkgname": pkgname,
        "source": source,
        "url": url,
        "iosAppId": iosAppId,
        "content": content,
        "inPkgName": inPkgName,
        "inIcon": inIcon,
        "rewardCoins": rewardCoins,
        "inviteCode": inviteCode,
        "nativeRechargeRedirect": nativeRechargeRedirect,
        "guideMode": guideMode,
      };
}
