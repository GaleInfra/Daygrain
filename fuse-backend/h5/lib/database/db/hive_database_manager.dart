import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled1/common_logic/cache_manager.dart';
import '../box/video_call_box.dart';

class HiveDatabaseManager {
  static const String videoCallBoxName = 'm_video_calls';
  static const String stringCacheBoxName = 'string_cache';

  static Box<VideoCallBox>? _videoCallBox;
  static Box<String>? _stringCacheBox;

  static Box<VideoCallBox> get videoCallBox {
    if (_videoCallBox == null) {
      throw Exception('Database not initialized. Call initDatabase() first.');
    }
    return _videoCallBox!;
  }

  static Box<String> get stringCacheBox {
    if (_stringCacheBox == null) {
      throw Exception('Database not initialized. Call initDatabase() first.');
    }
    return _stringCacheBox!;
  }

  static Future<void> initDatabase() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDir.path);
    }

    // 注册适配器
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VideoCallBoxAdapter());
    }

    // 打开盒子
    try {
      _videoCallBox = await Hive.openBox<VideoCallBox>(videoCallBoxName);
      _stringCacheBox = await Hive.openBox<String>(stringCacheBoxName);
    } catch (e) {
      print('打开盒子失败：$e');
      //删除数据后重新打开
      await Hive.deleteBoxFromDisk(videoCallBoxName);
      await Hive.deleteBoxFromDisk(stringCacheBoxName);
      _videoCallBox = await Hive.openBox<VideoCallBox>(videoCallBoxName);
      _stringCacheBox = await Hive.openBox<String>(stringCacheBoxName);
    }
    if (kIsWeb) {
      await CacheManager.migrateSPUtilCacheToHive();

      //如果 _stringCacheBox 数量超过1000 则清空最早插入的900条
      if ((_stringCacheBox?.length ?? 0) > 1000) {
        for (var i = 0; i < 900; i++) {
          try {
            await _stringCacheBox?.deleteAt(i);
            
          } catch (e) {
            
          }
        }
      }
    }
  }

  static Future<void> closeDatabase() async {
    try {
      await _videoCallBox?.close();
    } catch (e) {}
    try {
      await _stringCacheBox?.close();
    } catch (e) {}
    try {
      await Hive.close();
    } catch (e) {}
  }

  static Future<void> clearDatabase() async {
    try {
      await _videoCallBox?.clear();
    } catch (e) {}
    try {
      await _stringCacheBox?.clear();
    } catch (e) {}
  }

  //删除全部盒子重新打开
  static Future<void> deleteAllBox() async {
    await closeDatabase();
    try {
      await clearDatabase();
    } catch (e) {}
    //重新打开
    await initDatabase();
  }
}
