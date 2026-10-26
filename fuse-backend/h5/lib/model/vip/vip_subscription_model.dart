class VipSubscriptionModel {
  VipSubscriptionModel({
    this.goodsId,
    this.code,
    this.icon,
    this.discount,
    this.originalPrice,
    this.price,
    this.originalPriceRupee,
    this.priceRupee,
    this.localPaymentPriceRupee,
    this.localPayOriginalPrice,
    this.localPayPrice,
    this.exchangeCoin,
    this.validity,
    this.validityUnit,
  });

  VipSubscriptionModel.fromJson(dynamic json) {
    goodsId = json['goodsId'];
    code = json['code'];
    icon = json['icon'];
    discount = json['discount'];
    originalPrice = json['originalPrice'];
    price = json['price'];
    originalPriceRupee = json['originalPriceRupee'];
    priceRupee = json['priceRupee'];
    localPaymentPriceRupee = json['localPaymentPriceRupee'];
    localPayOriginalPrice = json['localPayOriginalPrice'];
    localPayPrice = json['localPayPrice'];
    exchangeCoin = json['exchangeCoin'];
    validity = json['validity'];
    validityUnit = json['validityUnit'];
  }

  String? goodsId;
  String? code;
  String? icon;
  num? discount;
  num? originalPrice;
  num? price;
  num? originalPriceRupee;
  num? priceRupee;
  num? localPaymentPriceRupee;
  num? localPayOriginalPrice;
  num? localPayPrice;
  num? exchangeCoin;
  num? validity;
  String? validityUnit;

  VipSubscriptionModel copyWith({
    String? goodsId,
    String? code,
    String? icon,
    num? discount,
    num? originalPrice,
    num? price,
    num? originalPriceRupee,
    num? priceRupee,
    num? localPaymentPriceRupee,
    num? localPayOriginalPrice,
    num? localPayPrice,
    num? exchangeCoin,
    num? validity,
    String? validityUnit,
  }) =>
      VipSubscriptionModel(
        goodsId: goodsId ?? this.goodsId,
        code: code ?? this.code,
        icon: icon ?? this.icon,
        discount: discount ?? this.discount,
        originalPrice: originalPrice ?? this.originalPrice,
        price: price ?? this.price,
        originalPriceRupee: originalPriceRupee ?? this.originalPriceRupee,
        priceRupee: priceRupee ?? this.priceRupee,
        localPaymentPriceRupee: localPaymentPriceRupee ?? this.localPaymentPriceRupee,
        localPayOriginalPrice: localPayOriginalPrice ?? this.localPayOriginalPrice,
        localPayPrice: localPayPrice ?? this.localPayPrice,
        exchangeCoin: exchangeCoin ?? this.exchangeCoin,
        validity: validity ?? this.validity,
        validityUnit: validityUnit ?? this.validityUnit,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['goodsId'] = goodsId;
    map['code'] = code;
    map['icon'] = icon;
    map['discount'] = discount;
    map['originalPrice'] = originalPrice;
    map['price'] = price;
    map['originalPriceRupee'] = originalPriceRupee;
    map['priceRupee'] = priceRupee;
    map['localPaymentPriceRupee'] = localPaymentPriceRupee;
    map['localPayOriginalPrice'] = localPayOriginalPrice;
    map['localPayPrice'] = localPayPrice;
    map['exchangeCoin'] = exchangeCoin;
    map['validity'] = validity;
    map['validityUnit'] = validityUnit;
    return map;
  }
}
