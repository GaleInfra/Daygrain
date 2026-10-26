import 'package:untitled1/res/gift_image.dart';

/// create: 2023/4/26
/// desc: 礼物图标工具
class GiftUtil {
  static final List<GiftImageModel> giftImageList = [
    GiftImageModel(name: aiMaShiBao, image: GiftImage.aiMaShiBao, thumbnail: GiftImage.aiMaShiBaoTmp),
    GiftImageModel(name: biao, image: GiftImage.biao, thumbnail: GiftImage.biaoTmp),
    GiftImageModel(name: bieShu, image: GiftImage.bieShu, thumbnail: GiftImage.bieShuTmp),
    GiftImageModel(name: chengBao, image: GiftImage.chengBao, thumbnail: GiftImage.chengBaoTmp),
    GiftImageModel(name: chuang, image: GiftImage.chuang, thumbnail: GiftImage.chuangTmp),
    GiftImageModel(name: chunGao, image: GiftImage.chunGao, thumbnail: GiftImage.chunGaoTmp),
    GiftImageModel(name: erHuan, image: GiftImage.erHuan, thumbnail: GiftImage.erHuanTmp),
    GiftImageModel(name: feiJi, image: GiftImage.feiJi, thumbnail: GiftImage.feiJiTmp),
    GiftImageModel(name: huangGuan, image: GiftImage.huangGuan, thumbnail: GiftImage.huangGuanTmp),
    GiftImageModel(name: hunSha, image: GiftImage.hunSha, thumbnail: GiftImage.hunShaTmp),
    GiftImageModel(name: jieZi, image: GiftImage.jieZi, thumbnail: GiftImage.jieZiTmp),
    GiftImageModel(name: kiss, image: GiftImage.kiss, thumbnail: GiftImage.kissTmp),
    GiftImageModel(name: meiGui, image: GiftImage.meiGui, thumbnail: GiftImage.meiGuiTmp),
    GiftImageModel(name: paoChe, image: GiftImage.paoChe, thumbnail: GiftImage.paoCheTmp),
    GiftImageModel(name: qiaoKeLi, image: GiftImage.qiaoKeLi, thumbnail: GiftImage.qiaoKeLiTmp),
    GiftImageModel(name: qingGua, image: GiftImage.qingGua, thumbnail: GiftImage.qingGuaTmp),
    GiftImageModel(name: rose, image: GiftImage.rose, thumbnail: GiftImage.roseTmp),
    GiftImageModel(name: shouZhuo, image: GiftImage.shouZhuo, thumbnail: GiftImage.shouZhuoTmp),
    GiftImageModel(name: shuiJingXie, image: GiftImage.shuiJingXie, thumbnail: GiftImage.shuiJingXieTmp),
    GiftImageModel(name: xiangBing, image: GiftImage.xiangBing, thumbnail: GiftImage.xiangBingTmp),
    GiftImageModel(name: xiangJiao, image: GiftImage.xiangJiao, thumbnail: GiftImage.xiangJiaoTmp),
    GiftImageModel(name: xiangLian, image: GiftImage.xiangLian, thumbnail: GiftImage.xiangLianTmp),
    GiftImageModel(name: xiangShui, image: GiftImage.xiangShui, thumbnail: GiftImage.xiangShuiTmp),
    GiftImageModel(name: xiong, image: GiftImage.xiong, thumbnail: GiftImage.xiongTmp),
    GiftImageModel(name: yongYi, image: GiftImage.yongYi, thumbnail: GiftImage.yongYiTmp),
    GiftImageModel(name: youLun, image: GiftImage.youLun, thumbnail: GiftImage.youLunTmp),
  ];

  /// 爱马仕包
  static const String aiMaShiBao = "aimashibao";

  /// 表
  static const String biao = "biao";

  /// 别墅
  static const String bieShu = "bieshu";

  /// 城堡
  static const String chengBao = "chengbao";

  /// 床
  static const String chuang = "chuang";

  /// 唇膏
  static const String chunGao = "chungao";

  /// 耳环
  static const String erHuan = "erhuan";

  /// 飞机
  static const String feiJi = "feiji";

  /// 皇冠
  static const String huangGuan = "huangguan";

  /// 婚纱
  static const String hunSha = "hunsha";

  /// 戒指
  static const String jieZi = "jiezi";

  /// kiss
  static const String kiss = "kiss";

  /// 玫瑰
  static const String meiGui = "meigui";

  /// 跑车
  static const String paoChe = "paoche";

  /// 巧克力
  static const String qiaoKeLi = "qiaokeli";

  /// 青瓜
  static const String qingGua = "qinggua";

  /// 一束玫瑰
  static const String rose = "rose";

  /// 手镯
  static const String shouZhuo = "shouzhuo";

  /// 水晶鞋
  static const String shuiJingXie = "shuijingxie";

  /// 香槟
  static const String xiangBing = "xiangbing";

  /// 香蕉
  static const String xiangJiao = "xiangjiao";

  /// 项链
  static const String xiangLian = "xianglian";

  /// 香水
  static const String xiangShui = "xiangshui";

  /// 熊
  static const String xiong = "xiong";

  /// 泳衣
  static const String yongYi = "yongyi";

  /// 邮轮
  static const String youLun = "youlun";
}

/// 礼物图片模型
class GiftImageModel {
  GiftImageModel({
    required this.name,
    required this.image,
    required this.thumbnail,
  });

  /// 名称
  final String name;

  /// 图标路径
  final String image;

  ///缩略图
  final String thumbnail;
}
