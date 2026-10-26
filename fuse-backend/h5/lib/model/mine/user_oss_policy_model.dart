class UserOssPolicyModel {
  UserOssPolicyModel({
    this.accessKeyId,
    this.policy,
    this.signature,
    this.expire,
    this.dir,
    this.host,
    this.callback,
  });

  UserOssPolicyModel.fromJson(dynamic json) {
    accessKeyId = json['accessKeyId'];
    policy = json['policy'];
    signature = json['signature'];
    expire = json['expire'];
    dir = json['dir'];
    host = json['host'];
    callback = json['callback'];
  }

  String? accessKeyId;
  String? policy;
  String? signature;
  String? expire;
  String? dir;
  String? host;
  String? callback;

  UserOssPolicyModel copyWith({
    String? accessKeyId,
    String? policy,
    String? signature,
    String? expire,
    String? dir,
    String? host,
    String? callback,
  }) =>
      UserOssPolicyModel(
        accessKeyId: accessKeyId ?? this.accessKeyId,
        policy: policy ?? this.policy,
        signature: signature ?? this.signature,
        expire: expire ?? this.expire,
        dir: dir ?? this.dir,
        host: host ?? this.host,
        callback: callback ?? this.callback,
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['accessKeyId'] = accessKeyId;
    map['policy'] = policy;
    map['signature'] = signature;
    map['expire'] = expire;
    map['dir'] = dir;
    map['host'] = host;
    map['callback'] = callback;
    return map;
  }
}
