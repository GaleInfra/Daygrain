import 'package:untitled1/language/bh_language_manager.dart';

/// 商品、活动促销、新用户促销都用这个模型
/// 有些字段是自己添加的
class CoinGoodsModel {
  CoinGoodsModel({
    this.activityName,
    this.activityPic,
    this.activitySmallPic,
    this.capableRechargeNum,
    this.code,
    this.discount,
    this.exchangeCoin,
    this.extraCoin,
    this.extraCoinPercent,
    this.goodsId,
    this.icon,
    this.invitationId,
    this.isPromotion,
    this.subType,
    this.localPaymentPriceRupee,
    this.localPayOriginalPrice,
    this.originalCode,
    this.originalPrice,
    this.originalPriceRupee,
    this.price,
    this.priceRupee,
    this.rechargeNum,
    this.remainMilliseconds,
    this.surplusMillisecond,
    this.tags,
    this.thirdpartyCoinPercent,
    this.type,
    this.validity,
    this.validityUnit,
    this.validDays,
    this.exchangeDays,
  });

  CoinGoodsModel.fromJson(dynamic json) {
    activityName = json['activityName'];
    activityPic = json['activityPic'];
    activitySmallPic = json['activitySmallPic'];
    capableRechargeNum = json['capableRechargeNum'];
    code = json['code'];
    discount = json['discount'];
    exchangeCoin = json['exchangeCoin'];
    extraCoin = json['extraCoin'];
    extraCoinPercent = json['extraCoinPercent'];
    goodsId = json['goodsId'];
    icon = json['icon'];
    invitationId = json['invitationId'];
    isPromotion = json['isPromotion'];
    subType = json['subType'];
    localPaymentPriceRupee = json['localPaymentPriceRupee'];
    localPayOriginalPrice = json['localPayOriginalPrice'];
    originalCode = json['originalCode'];
    originalPrice = json['originalPrice'];
    originalPriceRupee = json['originalPriceRupee'];
    price = json['price'];
    priceRupee = json['priceRupee'];
    rechargeNum = json['rechargeNum'];
    remainMilliseconds = json['remainMilliseconds'];
    surplusMillisecond = json['surplusMillisecond'];
    tags = json['tags'];
    thirdpartyCoinPercent = json['thirdpartyCoinPercent'];
    type = json['type'];
    validity = json['validity'];
    validityUnit = json['validityUnit'];
    validDays = _readNum(json['validDays']);
    exchangeDays = _readNum(json['exchangeDays']);
  }

  static num? _readNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  String? activityName;
  String? activityPic;
  String? activitySmallPic;
  num? capableRechargeNum;
  String? code;
  num? discount;
  num? exchangeCoin;
  num? extraCoin;
  num? extraCoinPercent;
  String? goodsId;
  String? icon;
  String? invitationId;
  bool? isPromotion;
  num? subType;
  num? localPaymentPriceRupee;
  num? localPayOriginalPrice;
  String? originalCode;
  num? originalPrice;
  num? originalPriceRupee;
  num? price;
  num? priceRupee;
  num? rechargeNum;
  dynamic remainMilliseconds;
  String? surplusMillisecond;
  String? tags;
  num? thirdpartyCoinPercent;
  String? type;
  num? validity;
  String? validityUnit;
  num? validDays;
  num? exchangeDays;

  CoinGoodsModel copyWith({
    String? activityName,
    String? activityPic,
    String? activitySmallPic,
    num? capableRechargeNum,
    String? code,
    num? discount,
    num? exchangeCoin,
    num? extraCoin,
    num? extraCoinPercent,
    String? goodsId,
    String? icon,
    String? invitationId,
    bool? isPromotion,
    num? subType,
    num? localPaymentPriceRupee,
    num? localPayOriginalPrice,
    String? originalCode,
    num? originalPrice,
    num? originalPriceRupee,
    num? price,
    num? priceRupee,
    num? rechargeNum,
    dynamic remainMilliseconds,
    String? surplusMillisecond,
    String? tags,
    num? thirdpartyCoinPercent,
    String? type,
    num? validity,
    String? validityUnit,
    num? validDays,
    num? exchangeDays,
  }) =>
      CoinGoodsModel(
        activityName: activityName ?? this.activityName,
        activityPic: activityPic ?? this.activityPic,
        activitySmallPic: activitySmallPic ?? this.activitySmallPic,
        capableRechargeNum: capableRechargeNum ?? this.capableRechargeNum,
        code: code ?? this.code,
        discount: discount ?? this.discount,
        exchangeCoin: exchangeCoin ?? this.exchangeCoin,
        extraCoin: extraCoin ?? this.extraCoin,
        extraCoinPercent: extraCoinPercent ?? this.extraCoinPercent,
        goodsId: goodsId ?? this.goodsId,
        icon: icon ?? this.icon,
        invitationId: invitationId ?? this.invitationId,
        isPromotion: isPromotion ?? this.isPromotion,
        subType: subType ?? this.subType,
        localPaymentPriceRupee: localPaymentPriceRupee ?? this.localPaymentPriceRupee,
        localPayOriginalPrice: localPayOriginalPrice ?? this.localPayOriginalPrice,
        originalCode: originalCode ?? this.originalCode,
        originalPrice: originalPrice ?? this.originalPrice,
        originalPriceRupee: originalPriceRupee ?? this.originalPriceRupee,
        price: price ?? this.price,
        priceRupee: priceRupee ?? this.priceRupee,
        rechargeNum: rechargeNum ?? this.rechargeNum,
        remainMilliseconds: remainMilliseconds ?? this.remainMilliseconds,
        surplusMillisecond: surplusMillisecond ?? this.surplusMillisecond,
        tags: tags ?? this.tags,
        thirdpartyCoinPercent: thirdpartyCoinPercent ?? this.thirdpartyCoinPercent,
        type: type ?? this.type,
        validity: validity ?? this.validity,
        validityUnit: validityUnit ?? this.validityUnit,
        validDays: validDays ?? this.validDays,
        exchangeDays: exchangeDays ?? this.exchangeDays,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['activityName'] = activityName;
    map['activityPic'] = activityPic;
    map['activitySmallPic'] = activitySmallPic;
    map['capableRechargeNum'] = capableRechargeNum;
    map['code'] = code;
    map['discount'] = discount;
    map['exchangeCoin'] = exchangeCoin;
    map['extraCoin'] = extraCoin;
    map['extraCoinPercent'] = extraCoinPercent;
    map['goodsId'] = goodsId;
    map['icon'] = icon;
    map['invitationId'] = invitationId;
    map['isPromotion'] = isPromotion;
    map['subType'] = subType;
    map['localPaymentPriceRupee'] = localPaymentPriceRupee;
    map['localPayOriginalPrice'] = localPayOriginalPrice;
    map['originalCode'] = originalCode;
    map['originalPrice'] = originalPrice;
    map['originalPriceRupee'] = originalPriceRupee;
    map['price'] = price;
    map['priceRupee'] = priceRupee;
    map['rechargeNum'] = rechargeNum;
    map['remainMilliseconds'] = remainMilliseconds;
    map['surplusMillisecond'] = surplusMillisecond;
    map['tags'] = tags;
    map['thirdpartyCoinPercent'] = thirdpartyCoinPercent;
    map['type'] = type;
    map['validity'] = validity;
    map['validityUnit'] = validityUnit;
    map['validDays'] = validDays;
    map['exchangeDays'] = exchangeDays;
    return map;
  }

  /// 会员档：validity 非空、validDays>0、exchangeDays>0 任一成立。
  bool get isVipTerm {
    if (validity != null) return true;
    if (validDays != null && validDays! > 0) return true;
    if (exchangeDays != null && exchangeDays! > 0) return true;
    return false;
  }

  //get方法获取当前商品 validity 和  validityUnit 组合
  String getDisplyValidity() {
    if (validityUnit?.toLowerCase().contains("lifetime") ?? false) {
      return validityUnit?.bhTR ?? "";
    } else {
      return "$validity ${validityUnit?.bhTR}";
    }
    
  }
}
