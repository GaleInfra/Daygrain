import 'package:sqflite/sqflite.dart';

import '../db/database_manager.dart';


/// 数据表操作基类
abstract class BaseMapper {

  BaseMapper() {
    DatabaseManager().addMapper(this);
  }

  /// 表名
  String tableName();

  /// 表创建sql语句
  String tableSqlString();

  /// 表更新sql语句
  String updateSqlString(int oldVersion, int newVersion);

  /// 获取数据库
  Future<Database> getDatabase()async {
    return await DatabaseManager().getDataBase();
  }
}