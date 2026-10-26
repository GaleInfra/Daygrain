/*
{
    "conversationType": 1,
    "targetId": "1351074033617207296",
    "latestMessage": {
        "messageType": "LC:SingleJsonMsg",
        "channelId": "",
        "content": {
            "content": "{\"tppTitle\":\"You can get UP TO 20% more coins.Valid for 24 hours\",\"tppImageUrl\":\"http://test-agilecdn.livchat.me/banner/cxkp20220224.png?Expires=1742208465&OSSAccessKeyId=LTAI5tNPNT6g1inCHkxgcUGz&Signature=04uFAGTmu4pKhurrJN3e3Bz8eXE%3D\",\"tppUrl\":\"https://new-test-h5.blinku.me/H5-app/index.html?entry=im_outstore_card&token=eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxODg3MTI0MDM3OTMxNDk5NTIwIiwidXNlcl90eXBlIjoxLCJleHAiOjQ4OTQ0MzU4MzQsImNyZWF0ZWQiOjE3Mzg3NjIyMzQ0NTF9.MtIzALYfqdJoQHX746q0S8u4cPncPGE_kU0S7RX_n5qeito6eNCznzsoR0nyxxQ5B8Ip4g2IgMFT3B-UAy1jFQ\",\"tppOutsideTitle\":\"You can get UP TO 20% more coins.Valid for 24 hours\"}",
            "contentType": "tpp",
            "extra": "{\"contentType\":\"tpp\"}"
        },
        "senderUserId": "1351074033617207296",
        "targetId": "1351074033617207296",
        "conversationType": 1,
        "sentTime": 1738806925304,
        "receivedTime": 1738827182827,
        "messageUId": "CKR3-S1FU-32Q7-QJNF",
        "messageDirection": 2,
        "isPersited": true,
        "isCounted": true,
        "isMentioned": false,
        "disableNotification": false,
        "canIncludeExpansion": false,
        "receivedStatus": 1,
        "pushConfig": {
            "iOSConfig": {},
            "androidConfig": {
                "notificationId": ""
            },
            "pushTitle": null,
            "pushContent": null,
            "pushData": null,
            "disablePushTitle": false,
            "forceShowDetailContent": false,
            "templateId": null
        },
        "isInterrupt": false,
        "isModifyMessage": false,
        "isOffLineMessage": true
    },
    "unreadMessageCount": 2,
    "hasMentioned": false,
    "lastUnreadTime": 1738806925304,
    "notificationStatus": 2,
    "notificationLevel": 0,
    "isTop": true,
    "channelId": "",
    "unreadMentionedCount": 0
}
**/
import 'dart:convert';

class JSConversation {
  int? conversationType;
  String? targetId;
  JSMessage? latestMessage;
  int? unreadMessageCount;
  bool? hasMentioned;
  int? lastUnreadTime;
  int? notificationStatus;
  int? notificationLevel;
  bool? isTop;
  String? channelId;
  int? unreadMentionedCount;

  JSConversation(
      {this.conversationType,
      this.targetId,
      this.latestMessage,
      this.unreadMessageCount,
      this.hasMentioned,
      this.lastUnreadTime,
      this.notificationStatus,
      this.notificationLevel,
      this.isTop,
      this.channelId,
      this.unreadMentionedCount});

  factory JSConversation.fromJson(Map<String, dynamic> json) {
    dynamic latestMessage;
    if (json['latestMessage'] != null) {
      try {
        latestMessage = JSMessage.fromJson(json['latestMessage']);
      } catch (e) {}
    }

    return JSConversation(
        conversationType: json['conversationType'],
        targetId: json['targetId'] ?? "",
        latestMessage: latestMessage,
        unreadMessageCount: json['unreadMessageCount'],
        hasMentioned: json['hasMentioned'],
        lastUnreadTime: json['lastUnreadTime'],
        notificationStatus: json['notificationStatus'],
        notificationLevel: json['notificationLevel'],
        isTop: json['isTop'],
        channelId: json['channelId'],
        unreadMentionedCount: json['unreadMentionedCount']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['conversationType'] = conversationType;
    json['targetId'] = targetId;
    json['latestMessage'] = latestMessage?.toJson();
    json['unreadMessageCount'] = unreadMessageCount;
    json['hasMentioned'] = hasMentioned;
    json['lastUnreadTime'] = lastUnreadTime;
    json['notificationStatus'] = notificationStatus;
    json['notificationLevel'] = notificationLevel;
    json['isTop'] = isTop;
    json['channelId'] = channelId;
    json['unreadMentionedCount'] = unreadMentionedCount;
    return json;
  }
}

class JSMessage {
  late String messageType;
  int? conversationType; //1: 单聊 3: 群聊 4: 聊天室 5: 客服会话 6: 系统消息 7: 默认关注的公众号 8: 手动关注的公众号 9: RTCLib 房间
  String? targetId;
  int? messageId;
  String? messageUId;
  bool? offLine;
  int? receivedTime;
  int? sentTime;
  int? receivedStatus; //0:UNREAD 1:READ 2:LISTENED 4:DOWNLOADED 8:RETRIEVED
  int? sentStatus;
  String? senderUserId;
  int? messageDirection; //1:send 2:receive
  JSMentionedInfo? mentionedInfo;
  JPushOptions? pushOptions;
  String? extra;
  String? expansion;
  dynamic content;

  JSMessage(
      {required this.messageType,
      this.conversationType,
      this.targetId,
      this.messageId,
      this.messageUId,
      this.offLine,
      this.receivedTime,
      this.sentTime,
      this.receivedStatus,
      this.sentStatus,
      this.senderUserId,
      this.messageDirection,
      this.mentionedInfo,
      this.pushOptions,
      this.extra,
      this.expansion,
      this.content});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['messageType'] = messageType;
    json['conversationType'] = conversationType;
    json['targetId'] = targetId;
    json['messageId'] = messageId;
    json['messageUId'] = messageUId;
    json['offLine'] = offLine;
    json['receivedTime'] = receivedTime;
    json['sentTime'] = sentTime;
    json['receivedStatus'] = receivedStatus;
    json['sentStatus'] = sentStatus;
    json['senderUserId'] = senderUserId;
    json['messageDirection'] = messageDirection;
    json['mentionedInfo'] = mentionedInfo?.toJson();
    json['pushOptions'] = pushOptions?.toJson();
    json['extra'] = extra;
    json['expansion'] = expansion;
    json['content'] = content?.toJson();
    return json;
  }

  factory JSMessage.fromJson(Map<String, dynamic> json) {
    dynamic content;
    String messageType = json['messageType'];
    String? extra = json['extra'];
    if (messageType == JSMessageType.singleJsonMsg) {
      content = JSSingleJsonMsgMessageContent.fromJson(json['content']);
    } else if (messageType == JSMessageType.text) {
      content = JSTextMessageContent.fromJson(json['content']);
    } else if (messageType == JSMessageType.image) {
      content = JSImageMessageContent.fromJson(json['content']);
    } else if (messageType == JSMessageType.file) {
      content = JSFileMessageContent.fromJson(json['content']);
    } else if (messageType == JSMessageType.voice) {
      content = JSVoiceMessageContent.fromJson(json['content']);
    } else if (messageType == JSMessageType.hyperLinkMessage) {
      content = JSHyperLinkMessageContent.fromJson(json['content']);
    } else if (messageType == JSMessageType.noneFlagMessage) {
      content = RCNoneFlagMessageContent.fromJson(json['content']);
    } else if (messageType == JSMessageType.command) {
      dynamic content2 = json['content'];
      content = content2;
    } else {
      content = JSMessageContent.fromJson(json['content']);
    }
    return JSMessage(
        messageType: messageType,
        conversationType: json['conversationType'],
        targetId: json['targetId'],
        messageId: json['messageId'],
        messageUId: json['messageUId'],
        offLine: json['offLine'],
        receivedTime: json['receivedTime'],
        sentTime: json['sentTime'],
        receivedStatus: json['receivedStatus'],
        sentStatus: json['sentStatus'],
        senderUserId: json['senderUserId'],
        messageDirection: json['messageDirection'],
        mentionedInfo: json['mentionedInfo'] != null ? JSMentionedInfo.fromJson(json['mentionedInfo']) : null,
        pushOptions: json['pushOptions'] != null ? JPushOptions.fromJson(json['pushOptions']) : null,
        extra: extra,
        expansion: json['expansion'],
        content: content);
  }
}

class JSMentionedInfo {
  int? type;
  List<String>? userIdList;
  String? mentionedContent;

  JSMentionedInfo({this.type, this.userIdList, this.mentionedContent});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['type'] = type;
    json['userIdList'] = userIdList;
    json['mentionedContent'] = mentionedContent;
    return json;
  }

  factory JSMentionedInfo.fromJson(Map<String, dynamic> json) {
    return JSMentionedInfo(type: json['type'], userIdList: json['userIdList'], mentionedContent: json['mentionedContent']);
  }
}

class JPushOptions {
  Map<String, dynamic>? iOSConfig;
  Map<String, dynamic>? androidConfig;
  String? pushTitle;
  String? pushContent;
  String? pushData;
  bool? disablePushTitle;
  bool? forceShowDetailContent;
  String? templateId;

  JPushOptions({this.iOSConfig, this.androidConfig, this.pushTitle, this.pushContent, this.pushData, this.disablePushTitle, this.forceShowDetailContent, this.templateId});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['iOSConfig'] = iOSConfig;
    json['androidConfig'] = androidConfig;
    json['pushTitle'] = pushTitle;
    json['pushContent'] = pushContent;
    json['pushData'] = pushData;
    json['disablePushTitle'] = disablePushTitle;
    json['forceShowDetailContent'] = forceShowDetailContent;
    json['templateId'] = templateId;
    return json;
  }

  factory JPushOptions.fromJson(Map<String, dynamic> json) {
    return JPushOptions(
        iOSConfig: json['iOSConfig'],
        androidConfig: json['androidConfig'],
        pushTitle: json['pushTitle'],
        pushContent: json['pushContent'],
        pushData: json['pushData'],
        disablePushTitle: json['disablePushTitle'],
        forceShowDetailContent: json['forceShowDetailContent'],
        templateId: json['templateId']);
  }
}

/**
 * "content": {
            "content": "{\"tppTitle\":\"You can get UP TO 20% more coins.Valid for 24 hours\",\"tppImageUrl\":\"http://test-agilecdn.livchat.me/banner/cxkp20220224.png?Expires=1742208465&OSSAccessKeyId=LTAI5tNPNT6g1inCHkxgcUGz&Signature=04uFAGTmu4pKhurrJN3e3Bz8eXE%3D\",\"tppUrl\":\"https://new-test-h5.blinku.me/H5-app/index.html?entry=im_outstore_card&token=eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxODg3MTI0MDM3OTMxNDk5NTIwIiwidXNlcl90eXBlIjoxLCJleHAiOjQ4OTQ0MzU4MzQsImNyZWF0ZWQiOjE3Mzg3NjIyMzQ0NTF9.MtIzALYfqdJoQHX746q0S8u4cPncPGE_kU0S7RX_n5qeito6eNCznzsoR0nyxxQ5B8Ip4g2IgMFT3B-UAy1jFQ\",\"tppOutsideTitle\":\"You can get UP TO 20% more coins.Valid for 24 hours\"}",
            "contentType": "tpp",
            "extra": "{\"contentType\":\"tpp\"}"
        },
 * 
*/
class JSSingleJsonMsgMessageContent {
  String? contentType;
  String? content;
  String? extra;

  JSSingleJsonMsgMessageContent({this.contentType, this.content, this.extra});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['contentType'] = contentType;
    json['content'] = content;
    json['extra'] = extra;
    return json;
  }

  factory JSSingleJsonMsgMessageContent.fromJson(Map<String, dynamic> json) {
    return JSSingleJsonMsgMessageContent(contentType: json['contentType'], content: json['content'], extra: json['extra']);
  }

  QuestionData? get questionData {
    if (contentType == "script-question" && content != null) {
      return QuestionData.fromJson(jsonDecode(content!));
    }
    return null;
  }

  VideoData? get videoData {
    if (contentType == "video" && content != null) {
      return VideoData.fromJson(jsonDecode(content!));
    }
    return null;
  }

  ExtensionData? get extensionData {
    if (contentType == "video" && extra != null) {
      return ExtensionData.fromJson(jsonDecode(extra!));
    }
    return null;
  }

}
/**
 * 
 * "{"videoUrl":"https://test-agilecdn.livchat.me/livchat/images/dev/20240521/1716312816483.mp4?Expires=1756554773&OSSAccessKeyId=LTAI5tNPNT6g1inCHkxgcUGz&Signature=3dEQt%2FvjK2oxM4GCtO7KqCs0gsI%3D","videoThumb":"https://test-agilecdn.livchat.me/livchat/images/dev/20240521/1716312816483.mp4?Expires=1756554773&OSSAccessKeyId=LTAI5tNPNT6g1inCHkxgcUGz&Signature=IB1g6DibVkAvEq4703aJ7Rgot%2BI%3D&x-oss-process=video%2Fsnapshot%2Ct_1%2Cf_jpg%2Cm_fast%2Car_auto%2Cw_160"}"
 */
//视频内容数据
class VideoData {
  String? videoUrl;
  String? videoThumb;

  VideoData({this.videoUrl, this.videoThumb});

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(videoUrl: json['videoUrl'], videoThumb: json['videoThumb']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['videoUrl'] = videoUrl;
    json['videoThumb'] = videoThumb;
    return json;
  }
}

/**
 * 
 * {"isLock":false,"scriptId":"85f19f477fcb486e83374fa98a2f4530","imMessageType":3,"contentType":"video"}
 * 
*/
//扩展数据
class ExtensionData {
  bool? isLock;
  String? scriptId;
  int? imMessageType;
  String? contentType;

  ExtensionData({this.isLock, this.scriptId, this.imMessageType, this.contentType});

  factory ExtensionData.fromJson(Map<String, dynamic> json) {
    return ExtensionData(isLock: json['isLock'], scriptId: json['scriptId'], imMessageType: json['imMessageType'], contentType: json['contentType']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['isLock'] = isLock;
    json['scriptId'] = scriptId;
    json['imMessageType'] = imMessageType;
    json['contentType'] = contentType;
    return json;
  }
}



//问答数据模型
class QuestionData {
  String? content;
  List<String>? replies;

  QuestionData({this.content, this.replies});

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    List<String>? repliesList;
    if (json['replies'] != null) {
      if (json['replies'] is String) {
        // If replies is a string, decode it first
        repliesList = jsonDecode(json['replies']).map<String>((e) => e.toString()).toList();
      } else if (json['replies'] is List) {
        // If replies is already a list, convert it directly
        repliesList = (json['replies'] as List).map<String>((e) => e.toString()).toList();
      }
    }
    return QuestionData(content: json['content'], replies: repliesList);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content;
    json['replies'] = replies;
    return json;
  }
}


//文本消息内容
class JSTextMessageContent {
  String? content;
  String? extra;

  JSTextMessageContent({this.content, this.extra});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content;
    json['extra'] = extra;
    return json;
  }

  factory JSTextMessageContent.fromJson(Map<String, dynamic> json) {
    return JSTextMessageContent(content: json['content'], extra: json['extra']);
  }
}

//图片消息内容
/**
 {
    "content": "",
    "imageUri": "http://test-agilecdn.livchat.me/im/images/20250206/1739983364129161216_1738832026427.jpg?Expires=1746608031&OSSAccessKeyId=LTAI5tNPNT6g1inCHkxgcUGz&Signature=WcJFiRS%2B9wRcrPF%2BpWz2jIHKmPA%3D&x-oss-process=image%2Fresize%2Cm_lfit%2Ch_1080%2Cw_1080%2Climit_1",
    "isFull": false
}
 * 
*/
class JSImageMessageContent {
  String? content;
  String? imageUri;
  bool? isFull;

  JSImageMessageContent({this.content, this.imageUri, this.isFull});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content;
    json['imageUri'] = imageUri;
    json['isFull'] = isFull;
    return json;
  }

  factory JSImageMessageContent.fromJson(Map<String, dynamic> json) {
    return JSImageMessageContent(content: json['content'], imageUri: json['imageUri'], isFull: json['isFull']);
  }
}

///文件消息内容
/*
{
    "name": "Screenshot_2025-11-25-14-17-52-512_com.fengchao1.android.jpg",
    "size": 548607,
    "type": "jpg",
    "fileUrl": "https://bucket7-b-2.ronghub.com/WFVIRVxPUVdYD1xZUAkHAw0BCAMHDgQBBgEBBgUKAQYFDwMIDAsCAgU0ODAw.jpg"
}
*/
class JSFileMessageContent {
  String? name;
  int? size;
  String? type;
  String? fileUrl;

  JSFileMessageContent({this.name, this.size, this.type, this.fileUrl});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['name'] = name;
    json['size'] = size;
    json['type'] = type;
    json['fileUrl'] = fileUrl;
    return json;
  }

  factory JSFileMessageContent.fromJson(Map<String, dynamic> json) {
    return JSFileMessageContent(name: json['name'], size: json['size'], type: json['type'], fileUrl: json['fileUrl']);
  }
}

///语音消息
/**
 {
    "name": "544.aac",
    "remoteUrl": "https://bucket7-b-2.ronghub.com/WlVAQ15PWVFaD1RfUgkPBQ8BAAUFDgwHBAEJAAcKCQAHDwsODgsKBQU2ODg2.aac",
    "duration": 2
}
 * 
*/
class JSVoiceMessageContent {
  String? name;
  String? remoteUrl;
  String? localUrl;
  double? duration;

  JSVoiceMessageContent({this.name, this.remoteUrl, this.localUrl, this.duration});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['name'] = name;
    json['remoteUrl'] = remoteUrl;
    json['localUrl'] = localUrl;
    json['duration'] = duration;
    return json;
  }

  factory JSVoiceMessageContent.fromJson(Map<String, dynamic> json) {
    return JSVoiceMessageContent(name: json['name'], remoteUrl: json['remoteUrl'], localUrl: json['localUrl'], duration: json['duration']);
  }
}

//自定义消息 HyperLink
/*
    content = map['content'];
    contentType = map['contentType'];
    extra = map['extra'];
*/
class JSHyperLinkMessageContent {
  String? content;
  String? contentType;
  String? extra;

  JSHyperLinkMessageContent({this.content, this.contentType, this.extra});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content;
    json['contentType'] = contentType;
    json['extra'] = extra;
    return json;
  }

  factory JSHyperLinkMessageContent.fromJson(Map<String, dynamic> json) {
    return JSHyperLinkMessageContent(content: json['content'], contentType: json['contentType'], extra: json['extra']);
  }
}

///空消息
/*
    map['content'] = content;
    map['contentType'] = contentType;
    map['extra'] = extra;
*/
class RCNoneFlagMessageContent {
  String? content;
  String? contentType;
  String? extra;

  RCNoneFlagMessageContent({this.content, this.contentType, this.extra});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content;
    json['contentType'] = contentType;
    json['extra'] = extra;
    return json;
  }

  factory RCNoneFlagMessageContent.fromJson(Map<String, dynamic> json) {
    return RCNoneFlagMessageContent(content: json['content'], contentType: json['contentType'], extra: json['extra']);
  }
}

///默认消息内容
class JSMessageContent {
  String? content;

  JSMessageContent({this.content});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content;
    return json;
  }

  factory JSMessageContent.fromJson(Map<String, dynamic> json) {
    return JSMessageContent(content: json['content']);
  }
}

/**
 	var ha, ga, fa = la("RC:ImgMsg"),
	pa = la("RC:HQVCMsg"),
	Ia = la("RC:SightMsg"),
	va = la("RC:TxtMsg"),
	Ea = la("RC:CombineMsg"),
	_a = la("RC:FileMsg"),
	Ca = la("RC:GIFMsg"),
	Ra = la("RC:VcMsg"),
	Ta = la("RC:LBSMsg"),
	ma = la("RC:ReferenceMsg"),
	Sa = la("RC:ImgTextMsg"),
 * 
*/
//消息类型
class JSMessageType {
  static const text = "RC:TxtMsg";
  static const voice = "RC:HQVCMsg";
  static const image = "RC:ImgMsg";
  static const file = "RC:FileMsg";
  static const location = "RC:LBSMsg";
  static const richContent = "RC:ImgTextMsg";
  static const combine = "RC:CombineMsg";
  static const sight = "RC:SightMsg";
  static const gif = "RC:GIFMsg";
  static const unknown = "RC:UnknownMsg";
  static const reference = "RC:ReferenceMsg";
  static const singleJsonMsg = "LC:SingleJsonMsg";
  static const noneFlagMessage = "LC:NoneFlagMsg";
  static const hyperLinkMessage = "LC:HyperLinkMsg";
  //command
  static const command = "RC:CmdMsg";
  static const commandNotification = "RC:CmdNtf";
}

enum SentStatus {
  sending(10),
  failed(20),
  sent(30),
  received(40),
  read(50),
  destroyed(60);

  final int value;
  const SentStatus(this.value);
}
