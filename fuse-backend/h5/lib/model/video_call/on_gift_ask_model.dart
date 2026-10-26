class OnGiftAskModel {
  OnGiftAskModel({
    this.fromUserId,
    this.content,
  });

  OnGiftAskModel.fromJson(dynamic json) {
    fromUserId = json['fromUserId'];
    content = json['content'] != null ? Content.fromJson(json['content']) : null;
  }

  String? fromUserId;
  Content? content;

  OnGiftAskModel copyWith({
    String? fromUserId,
    Content? content,
  }) =>
      OnGiftAskModel(
        fromUserId: fromUserId ?? this.fromUserId,
        content: content ?? this.content,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['fromUserId'] = fromUserId;
    if (content != null) {
      map['content'] = content?.toJson();
    }
    return map;
  }
}

class Content {
  Content({
    this.code,
    this.coinPrice,
    this.count,
    // this.giftDesc,
    // this.iconPath,
    // this.iconThumbPath,
    // this.name,
    this.sortNo,
    // this.uuid,
  });

  Content.fromJson(dynamic json) {
    code = json['code'];
    coinPrice = json['coinPrice'];
    count = json['count'];
    // giftDesc = json['giftDesc'];
    // iconPath = json['iconPath'];
    // iconThumbPath = json['iconThumbPath'];
    // name = json['name'];
    sortNo = json['sortNo'];
    // uuid = json['uuid'];
  }

  String? code;
  int? coinPrice;
  int? count;

  // String? giftDesc;
  // String? iconPath;
  // String? iconThumbPath;
  // String? name;
  int? sortNo;

  // String? uuid;

  Content copyWith({
    String? code,
    int? coinPrice,
    int? count,
    // String? giftDesc,
    // String? iconPath,
    // String? iconThumbPath,
    // String? name,
    int? sortNo,
    // String? uuid,
  }) =>
      Content(
        code: code ?? this.code,
        coinPrice: coinPrice ?? this.coinPrice,
        count: count ?? this.count,
        // giftDesc: giftDesc ?? this.giftDesc,
        // iconPath: iconPath ?? this.iconPath,
        // iconThumbPath: iconThumbPath ?? this.iconThumbPath,
        // name: name ?? this.name,
        sortNo: sortNo ?? this.sortNo,
        // uuid: uuid ?? this.uuid,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = code;
    map['coinPrice'] = coinPrice;
    map['count'] = count;
    // map['giftDesc'] = giftDesc;
    // map['iconPath'] = iconPath;
    // map['iconThumbPath'] = iconThumbPath;
    // map['name'] = name;
    map['sortNo'] = sortNo;
    // map['uuid'] = uuid;
    return map;
  }
}
