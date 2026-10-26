import 'package:get/get.dart';
import 'package:untitled1/model/gift/gift_model.dart';
import 'package:untitled1/net/request_repository.dart';

/// create: 2024/1/18
/// desc: 礼物列表数据管理
class GiftManager {
  GiftManager._init();
  static final GiftManager _instance = GiftManager._init();
  factory GiftManager() => _instance;
  static GiftManager get to => _instance;

  final RequestRepository _request = Get.find<RequestRepository>();

  final List<GiftModel> _giftList = [];
  List<GiftModel> get giftList => _giftList;

  // 获取礼物列表并排序
  Future getGift({int retryNum = 0}) async {
    if (retryNum > 5) {
      return;
    }
    await _request.giftList(
      onSuccess: (data) {
        _giftList.clear();
        _giftList.addAll(data);
        _giftList.sort((a, b) => b.sortNo!.compareTo(a.sortNo!));
      },
      onFail: (code, msg) {
        // 错误时重试
        getGift(retryNum: ++retryNum);
      }
    );
  }
}
