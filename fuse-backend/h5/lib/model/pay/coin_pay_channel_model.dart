class CoinPayChannelModel {
  CoinPayChannelModel({
    this.channelList,
    this.extra,
  });

  CoinPayChannelModel.fromJson(dynamic json) {
    if (json['channelList'] != null) {
      channelList = [];
      json['channelList'].forEach((v) {
        channelList?.add(ChannelList.fromJson(v));
      });
    }
    extra = json['extra'] != null ? ChannelExtra.fromJson(json['extra']) : null;
  }

  List<ChannelList>? channelList;
  ChannelExtra? extra;

  CoinPayChannelModel copyWith({
    List<ChannelList>? channelList,
    ChannelExtra? extra,
  }) =>
      CoinPayChannelModel(
        channelList: channelList ?? this.channelList,
        extra: extra ?? this.extra,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (channelList != null) {
      map['channelList'] = channelList?.map((v) => v.toJson()).toList();
    }
    if (extra != null) {
      map['extra'] = extra?.toJson();
    }
    return map;
  }
}

class ChannelExtra {
  ChannelExtra({
    this.chooseChannel,
    this.isShowTppPopout,
    this.tppJumpUrl,
    this.tppPicUrl,
    this.tppPopoutContent,
    this.tppPopoutType,
  });

  ChannelExtra.fromJson(dynamic json) {
    chooseChannel = json['chooseChannel'];
    isShowTppPopout = json['isShowTppPopout'];
    tppJumpUrl = json['tppJumpUrl'];
    tppPicUrl = json['tppPicUrl'];
    tppPopoutContent = json['tppPopoutContent'] != null ? json['tppPopoutContent'].cast<String>() : [];
    tppPopoutType = json['tppPopoutType'];
  }

  String? chooseChannel;
  bool? isShowTppPopout;
  String? tppJumpUrl;
  String? tppPicUrl;
  List<String>? tppPopoutContent;
  int? tppPopoutType;

  ChannelExtra copyWith({
    String? chooseChannel,
    bool? isShowTppPopout,
    String? tppJumpUrl,
    String? tppPicUrl,
    List<String>? tppPopoutContent,
    int? tppPopoutType,
  }) =>
      ChannelExtra(
        chooseChannel: chooseChannel ?? this.chooseChannel,
        isShowTppPopout: isShowTppPopout ?? this.isShowTppPopout,
        tppJumpUrl: tppJumpUrl ?? this.tppJumpUrl,
        tppPicUrl: tppPicUrl ?? this.tppPicUrl,
        tppPopoutContent: tppPopoutContent ?? this.tppPopoutContent,
        tppPopoutType: tppPopoutType ?? this.tppPopoutType,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['chooseChannel'] = chooseChannel;
    map['isShowTppPopout'] = isShowTppPopout;
    map['tppJumpUrl'] = tppJumpUrl;
    map['tppPicUrl'] = tppPicUrl;
    map['tppPopoutContent'] = tppPopoutContent;
    map['tppPopoutType'] = tppPopoutType;
    return map;
  }
}

/// Missing, blank, null, and non-numeric stay NaN. Explicit 0 stays 0.
double readJumpType(dynamic value) {
  if (value == null) return double.nan;
  if (value is bool) return double.nan;
  if (value is num) {
    if (value.isNaN || value.isInfinite) return double.nan;
    return value.toDouble();
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return double.nan;
    final parsed = num.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return double.nan;
    return parsed.toDouble();
  }
  return double.nan;
}

/// Persist a channel jumpType without turning a missing value into 0.
int? storedJumpType(dynamic value) {
  final jump = readJumpType(value);
  if (jump.isNaN) return null;
  if (jump == 0) return 0;
  if (jump == jump.roundToDouble() && jump >= -2147483648 && jump <= 2147483647) {
    return jump.toInt();
  }
  return 1;
}

class ChannelList {
  ChannelList({
    this.iconUrl,
    this.itemType,
    this.jumpType,
    this.payChannel,
    this.presentCoinRatio,
    this.promotionPresentCoinRatio,
    this.recommendReason,
    this.title,
  });

  ChannelList.fromJson(dynamic json) {
    iconUrl = json['iconUrl'];
    itemType = json['itemType'];
    jumpType = storedJumpType(json['jumpType']);
    payChannel = json['payChannel'];
    presentCoinRatio = json['presentCoinRatio'];
    promotionPresentCoinRatio = json['promotionPresentCoinRatio'];
    recommendReason = json['recommendReason'];
    title = json['title'];
  }

  String? iconUrl;
  int? itemType;
  int? jumpType;
  String? payChannel;
  int? presentCoinRatio;
  int? promotionPresentCoinRatio;
  String? recommendReason;
  String? title;

  ChannelList copyWith({
    String? iconUrl,
    int? itemType,
    int? jumpType,
    String? payChannel,
    int? presentCoinRatio,
    int? promotionPresentCoinRatio,
    String? recommendReason,
    String? title,
  }) =>
      ChannelList(
        iconUrl: iconUrl ?? this.iconUrl,
        itemType: itemType ?? this.itemType,
        jumpType: jumpType ?? this.jumpType,
        payChannel: payChannel ?? this.payChannel,
        presentCoinRatio: presentCoinRatio ?? this.presentCoinRatio,
        promotionPresentCoinRatio: promotionPresentCoinRatio ?? this.promotionPresentCoinRatio,
        recommendReason: recommendReason ?? this.recommendReason,
        title: title ?? this.title,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['iconUrl'] = iconUrl;
    map['itemType'] = itemType;
    map['jumpType'] = jumpType;
    map['payChannel'] = payChannel;
    map['presentCoinRatio'] = presentCoinRatio;
    map['promotionPresentCoinRatio'] = promotionPresentCoinRatio;
    map['recommendReason'] = recommendReason;
    map['title'] = title;
    return map;
  }
}
