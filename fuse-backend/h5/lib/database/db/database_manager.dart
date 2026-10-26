import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:untitled1/database/mapper/video_call_mapper.dart';
import 'package:untitled1/res/constant.dart';

import '../base/base_mapper.dart';

/// 数据库工具
class DatabaseManager {
  DatabaseManager._internal();
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;

  /// 当前版本号
  static const int _version = 1;

  /// 数据库名
  static final String _dbName = "${Constant.appName}.db";

  /// 数据库对象
  Database? _database;

  /// 操作类对象
  final List<BaseMapper> _mapperList = [];

  /// 初始化
  Future init() async {
    // Get.put(RCMessageUserInfoMapper(), permanent: true);
    Get.put(VideoCallMapper(), permanent: true);
    if (GetPlatform.isWeb) {
      await Get.find<VideoCallMapper>().initWebDB();
    } else {
      var path = await getDatabasesPath();
      _database = await openDatabase(
        "$path/$_dbName",
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpdate,
      );
    }
  }

  /// 获取数据库
  Future<Database> getDataBase() async {
    if (_database == null) {
      init();
    }
    return _database!;
  }

  /// 创建数据表
  Future _onCreate(Database db, int version) async {
    var batch = db.batch();
    for (var item in _mapperList) {
      batch.execute(item.tableSqlString());
    }
    await batch.commit();
  }

  /// 更新数据表
  Future _onUpdate(Database db, int oldVersion, int newVersion) async {
    var batch = db.batch();
    for (var item in _mapperList) {
      batch.execute(item.updateSqlString(oldVersion, newVersion));
    }
    await batch.commit();
  }

  /// 添加操作类对象
  void addMapper(BaseMapper mapper) {
    if (!_mapperList.contains(mapper)) {
      _mapperList.add(mapper);
    }
  }

  /// 判断表是否存在
  Future<bool> isTableExits(String tableName) async {
    await getDataBase();
    String sql =
        "select count(1) from Sqlite_master where type  = 'table' and name = '$tableName'";
    var result = await _database?.rawQuery(sql);
    return result != null && result.isNotEmpty;
  }

  /// 关闭数据库
  close() {
    _database?.close();
    _database = null;
  }
}
