

import 'package:untitled1/utils/bh_platform.dart';

class OnIMTriggerCallModel {
  String? uniqueId;
  int? callCategory;
  int? fromUserId;
  int? toUserId;
  int? unitPrice;
  bool? isFree;
  String? h5FromUserId;
  String? h5ToUserId;
  String? uiTips;

  OnIMTriggerCallModel({
    this.uniqueId,
    this.callCategory,
    this.fromUserId,
    this.toUserId,
    this.unitPrice,
    this.isFree,
    this.h5FromUserId,
    this.h5ToUserId,
    this.uiTips,
  });

  OnIMTriggerCallModel.fromJson(dynamic json) {
    uniqueId = json['uniqueId'];
    callCategory = json['callCategory'];
    fromUserId = json['fromUserId'];
    toUserId = json['toUserId'];  
    unitPrice = json['unitPrice'];
    isFree = json['isFree'];
    h5FromUserId = json['h5FromUserId'];
    h5ToUserId = json['h5ToUserId'];
    uiTips = json['uiTips'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['uniqueId'] = uniqueId;
    data['callCategory'] = callCategory;
    data['fromUserId'] = fromUserId;
    data['toUserId'] = toUserId;
    data['unitPrice'] = unitPrice;
    data['isFree'] = isFree;
    data['h5FromUserId'] = h5FromUserId;
    data['h5ToUserId'] = h5ToUserId;
    data['uiTips'] = uiTips;
    return data;
  }

    get fromUserIdStr {
    return BHPlatform.isWeb ? h5FromUserId ?? fromUserId : fromUserId;
  }

  get toUserIdStr {
    return BHPlatform.isWeb ? h5ToUserId ?? toUserId : toUserId;
  }
}
