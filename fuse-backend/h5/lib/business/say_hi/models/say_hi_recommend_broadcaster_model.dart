import 'package:untitled1/model/broadcaster/broadcaster_model.dart';
import 'package:untitled1/model/user/user_info_model.dart';

/**
 * {
            "broadcasterId": "1810563163557593088",
            "broadcasterName": "ElectricDream_218",
            "avatarMapPath": "20250625/175082074409585238.png",
            "gender": 2,
            "country": "USA",
            "unitPrice": 150,
            "videoMapPaths": [
                "livchat/images/dev/20240722/1721632399520.mp4",
                "20250415/1744713047919.mp4"
            ],
            "avatarUrl": "http://livchat.oss-us-west-1.aliyuncs.com/20250625/175082074409585238.png?Expires=1758596745&OSSAccessKeyId=LTAI5tNPNT6g1inCHkxgcUGz&Signature=kiayING3L%2FHXwD%2BA5IEkqKau1RA%3D&x-oss-process=image%2Fcrop%2Cx_22%2Cy_0%2Cw_699%2Ch_699%2Cnorth%2Fresize%2Cm_fill%2Ch_480%2Cw_480%2Climit_1",
            "age": 19
        }
 * 
*/
//SayHi推荐主播数据模型
class SayHiRecommendBroadcasterModel {
  final String? broadcasterId;
  final String? broadcasterName;
  final String? avatarMapPath;
  final int? gender;
  final String? country;
  final int? unitPrice;
  final List<String>? videoMapPaths;
  final String? avatarUrl;
  final int? age;
  String? countryAndEmoji;

  SayHiRecommendBroadcasterModel({
    required this.broadcasterId,
    required this.broadcasterName,
    required this.avatarMapPath,
    required this.gender,
    required this.country,
    required this.unitPrice,
    required this.videoMapPaths,
    required this.avatarUrl,
    required this.age,
    this.countryAndEmoji,
  });

  factory SayHiRecommendBroadcasterModel.fromJson(Map<String, dynamic> json) {
    List<String>? videoMapPathsList;
    if (json['videoMapPaths'] != null) {
      if (json['videoMapPaths'] is List) {
        videoMapPathsList = (json['videoMapPaths'] as List).map<String>((e) => e.toString()).toList();
      }
    }
    
    return SayHiRecommendBroadcasterModel(
      broadcasterId: json['broadcasterId'],
      broadcasterName: json['broadcasterName'],
      avatarMapPath: json['avatarMapPath'],
      gender: json['gender'],
      country: json['country'],
      unitPrice: json['unitPrice'],
      videoMapPaths: videoMapPathsList,
      avatarUrl: json['avatarUrl'],
      age: json['age'],
      countryAndEmoji: json['countryAndEmoji'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'broadcasterId': broadcasterId,
      'broadcasterName': broadcasterName,
      'avatarMapPath': avatarMapPath,
      'gender': gender,
      'country': country,
      'unitPrice': unitPrice,
      'videoMapPaths': videoMapPaths,
      'avatarUrl': avatarUrl,
      'age': age,
      'countryAndEmoji': countryAndEmoji,
    };
  }

  //BroadcasterModel 转 SayHiRecommendBroadcasterModel
  factory SayHiRecommendBroadcasterModel.fromBroadcasterModel(BroadcasterModel broadcaster) {
    return SayHiRecommendBroadcasterModel(
      broadcasterId: broadcaster.userId,
      broadcasterName: broadcaster.nickname,
      avatarMapPath: broadcaster.avatarMapPath,
      gender: broadcaster.gender,
      country: broadcaster.country,
      unitPrice: int.tryParse(broadcaster.unit ?? "0"),
      videoMapPaths: broadcaster.videoMapPaths,
      avatarUrl: broadcaster.avatar,
      age: broadcaster.age,
      countryAndEmoji: broadcaster.countryAndEmoji,
    );
  }

  //UserInfoModel 转 SayHiRecommendBroadcasterModel
  factory SayHiRecommendBroadcasterModel.fromUserInfoModel(UserInfoModel userInfo) {
    return SayHiRecommendBroadcasterModel(
      broadcasterId: userInfo.userId,
      broadcasterName: userInfo.nickname,
      avatarMapPath: null,
      gender: userInfo.gender,
      country: userInfo.country,
      unitPrice: userInfo.unitPrice,
      videoMapPaths: null,
      avatarUrl: userInfo.avatarUrl,
      age: userInfo.age,
      countryAndEmoji: null,
    );
  }
}