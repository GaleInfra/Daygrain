import 'package:sqflite/sqflite.dart';
import 'package:untitled1/database/base/base_mapper.dart';

import '../../utils/common_util.dart';
import '../dao/rc_message_userinfo_dao.dart';

/// create: 2023/5/5
/// desc: 融云消息会话用户表
class RCMessageUserInfoMapper extends BaseMapper {
  @override
  String tableName() => "RCMessageUserInfo";

  @override
  String tableSqlString() {
    return '''create table ${tableName()} (
    columnId integer primary key autoincrement,
    userId text not null,
    nickname text not null,
    avatar text not null
    )''';
  }

  @override
  String updateSqlString(int oldVersion, int newVersion) => "";

  /// 保存用户数据
  Future<bool> insertUserInfo(RcMessageUserinfoDao dao)async {
    Database db = await getDatabase();
    var result = await db.insert(tableName(), dao.toJson());
    logger.d("${tableName()}插入用户信息【${dao.toJson()}】结果==========> ${result > 0}");
    return result > 0;
  }

  /// 查询用户数据
  Future queryUserInfo(String userId)async {
    // Database db = await getDatabase();
  }

  /// 查询是否存在
  Future<bool> queryExist(String userId)async {
    Database db = await getDatabase();
    String sql = "select count(*) from ${tableName()} where userId = '$userId'";
    var result = Sqflite.firstIntValue(await db.rawQuery(sql));
    logger.d("查询用户信息【$userId】 是否存在(count)==========> $result");
    return (result ?? 0) > 0;
  }
}
