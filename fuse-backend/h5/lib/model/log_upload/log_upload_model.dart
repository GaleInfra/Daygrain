/// data : [{"event":"Event Name","code":"123","uuid":"abc123","orderId":"Order123","durationTime":1000,"elapsedTime":500,"result":"Success","resultCode":200,"tm":1621479586524}]
/// log_type : "event"
/// subtype : "这里传对应的日志类型"
/// behavior : "event"
/// utm_source : ""
/// android_id : "xxx"
/// user_id : "xxx"
/// pkg : "对应包名"
/// ver : "版本号"
/// platform : "Android"
/// platform_ver : 29
/// model : "MI 8 SE"
/// lan_id : ""
/// sec_id : 30
/// sys_lan : "zh"
/// country : ""
/// is_in_bg : false
/// is_anchor : false
/// client_type : "common"
/// bizver : ""
/// tm : 1638881561116

class LogUploadModel {
  LogUploadModel({
    List<LogUploadData>? data,
    String? logType,
    String? subtype,
    String? behavior,
    String? utmSource,
    String? androidId,
    String? userId,
    String? pkg,
    String? ver,
    String? platform,
    num? platformVer,
    String? model,
    String? lanId,
    num? secId,
    String? sysLan,
    String? country,
    bool? isInBg,
    bool? isAnchor,
    String? clientType,
    String? bizver,
    num? tm,
  }) {
    _data = data;
    _logType = logType;
    _subtype = subtype;
    _behavior = behavior;
    _utmSource = utmSource;
    _androidId = androidId;
    _userId = userId;
    _pkg = pkg;
    _ver = ver;
    _platform = platform;
    _platformVer = platformVer;
    _model = model;
    _lanId = lanId;
    _secId = secId;
    _sysLan = sysLan;
    _country = country;
    _isInBg = isInBg;
    _isAnchor = isAnchor;
    _clientType = clientType;
    _bizver = bizver;
    _tm = tm;
  }

  LogUploadModel.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(LogUploadData.fromJson(v));
      });
    }
    _logType = json['log_type'];
    _subtype = json['subtype'];
    _behavior = json['behavior'];
    _utmSource = json['utm_source'];
    _androidId = json['android_id'];
    _userId = json['user_id'];
    _pkg = json['pkg'];
    _ver = json['ver'];
    _platform = json['platform'];
    _platformVer = json['platform_ver'];
    _model = json['model'];
    _lanId = json['lan_id'];
    _secId = json['sec_id'];
    _sysLan = json['sys_lan'];
    _country = json['country'];
    _isInBg = json['is_in_bg'];
    _isAnchor = json['is_anchor'];
    _clientType = json['client_type'];
    _bizver = json['bizver'];
    _tm = json['tm'];
  }
  List<LogUploadData>? _data;
  String? _logType;
  String? _subtype;
  String? _behavior;
  String? _utmSource;
  String? _androidId;
  String? _userId;
  String? _pkg;
  String? _ver;
  String? _platform;
  num? _platformVer;
  String? _model;
  String? _lanId;
  num? _secId;
  String? _sysLan;
  String? _country;
  bool? _isInBg;
  bool? _isAnchor;
  String? _clientType;
  String? _bizver;
  num? _tm;
  LogUploadModel copyWith({
    List<LogUploadData>? data,
    String? logType,
    String? subtype,
    String? behavior,
    String? utmSource,
    String? androidId,
    String? userId,
    String? pkg,
    String? ver,
    String? platform,
    num? platformVer,
    String? model,
    String? lanId,
    num? secId,
    String? sysLan,
    String? country,
    bool? isInBg,
    bool? isAnchor,
    String? clientType,
    String? bizver,
    num? tm,
  }) =>
      LogUploadModel(
        data: data ?? _data,
        logType: logType ?? _logType,
        subtype: subtype ?? _subtype,
        behavior: behavior ?? _behavior,
        utmSource: utmSource ?? _utmSource,
        androidId: androidId ?? _androidId,
        userId: userId ?? _userId,
        pkg: pkg ?? _pkg,
        ver: ver ?? _ver,
        platform: platform ?? _platform,
        platformVer: platformVer ?? _platformVer,
        model: model ?? _model,
        lanId: lanId ?? _lanId,
        secId: secId ?? _secId,
        sysLan: sysLan ?? _sysLan,
        country: country ?? _country,
        isInBg: isInBg ?? _isInBg,
        isAnchor: isAnchor ?? _isAnchor,
        clientType: clientType ?? _clientType,
        bizver: bizver ?? _bizver,
        tm: tm ?? _tm,
      );
  List<LogUploadData>? get data => _data;
  String? get logType => _logType;
  String? get subtype => _subtype;
  String? get behavior => _behavior;
  String? get utmSource => _utmSource;
  String? get androidId => _androidId;
  String? get userId => _userId;
  String? get pkg => _pkg;
  String? get ver => _ver;
  String? get platform => _platform;
  num? get platformVer => _platformVer;
  String? get model => _model;
  String? get lanId => _lanId;
  num? get secId => _secId;
  String? get sysLan => _sysLan;
  String? get country => _country;
  bool? get isInBg => _isInBg;
  bool? get isAnchor => _isAnchor;
  String? get clientType => _clientType;
  String? get bizver => _bizver;
  num? get tm => _tm;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    map['log_type'] = _logType;
    map['subtype'] = _subtype;
    map['behavior'] = _behavior;
    map['utm_source'] = _utmSource;
    map['android_id'] = _androidId;
    map['user_id'] = _userId;
    map['pkg'] = _pkg;
    map['ver'] = _ver;
    map['platform'] = _platform;
    map['platform_ver'] = "$_platformVer";
    map['model'] = _model;
    map['lan_id'] = _lanId;
    map['sec_id'] = _secId;
    map['sys_lan'] = _sysLan;
    map['country'] = _country;
    map['is_in_bg'] = _isInBg;
    map['is_anchor'] = _isAnchor;
    map['client_type'] = _clientType;
    map['bizver'] = _bizver;
    map['tm'] = _tm;
    return map;
  }
}

/// event : "Event Name" 事件类型
/// code : "123"         商品id
/// uuid : "abc123"
/// orderId : "Order123" 后台订单id
/// durationTime : 1000  当前事务耗时
/// elapsedTime : 500    事务间隔总耗时
/// result : "Success"   响应结果
/// resultCode : 200     响应码
/// tm : 1621479586524   当前时间戳
class LogUploadData {
  LogUploadData({
    required String event,
    required String code,
    String? uuid,
    required String orderId,
    num? durationTime,
    num? elapsedTime,
    required String result,
    required num resultCode,
    String orderNo = "",
    num? tm,
  }) {
    _event = event;
    _code = code;
    _uuid = uuid;
    _orderId = orderId;
    _durationTime = durationTime;
    _elapsedTime = elapsedTime;
    _result = "$result 订单号: $orderNo";
    _resultCode = resultCode;
    _tm = tm ?? DateTime.now().millisecondsSinceEpoch;
  }

  LogUploadData.fromJson(dynamic json) {
    _event = json['event'];
    _code = json['code'];
    _uuid = json['uuid'];
    _orderId = json['orderId'];
    _durationTime = json['durationTime'];
    _elapsedTime = json['elapsedTime'];
    _result = json['result'];
    _resultCode = json['resultCode'];
    _tm = json['tm'];
  }
  String? _event;
  String? _code;
  String? _uuid;
  String? _orderId;
  num? _durationTime;
  num? _elapsedTime;
  String? _result;
  num? _resultCode;
  num? _tm;
  LogUploadData copyWith({
    required String event,
    required String code,
    String? uuid,
    required String orderId,
    num? durationTime,
    num? elapsedTime,
    required String result,
    required num resultCode,
    num? tm,
  }) =>
      LogUploadData(
        event: event,
        code: code,
        uuid: uuid ?? _uuid,
        orderId: orderId,
        durationTime: durationTime ?? _durationTime,
        elapsedTime: elapsedTime ?? _elapsedTime,
        result: result,
        resultCode: resultCode,
        tm: tm ?? _tm,
      );
  String? get event => _event;
  String? get code => _code;
  String? get uuid => _uuid;
  String? get orderId => _orderId;
  num? get durationTime => _durationTime;
  num? get elapsedTime => _elapsedTime;
  String? get result => _result;
  num? get resultCode => _resultCode;
  num? get tm => _tm;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['event'] = _event;
    map['code'] = _code;
    map['uuid'] = _uuid;
    map['orderId'] = _orderId;
    map['durationTime'] = _durationTime;
    map['elapsedTime'] = _elapsedTime;
    map['result'] = _result;
    map['resultCode'] = _resultCode;
    map['tm'] = _tm;
    return map;
  }

  @override
  String toString() {
    return 'LogUploadData{_event: $_event, _code: $_code, _uuid: $_uuid, _orderId: $_orderId, _durationTime: $_durationTime, _elapsedTime: $_elapsedTime, _result: $_result, _resultCode: $_resultCode, _tm: $_tm}';
  }
}
