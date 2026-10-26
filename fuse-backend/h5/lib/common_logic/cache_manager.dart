//基于Hive封装的缓存管理
import 'dart:convert';
import 'package:untitled1/model/infoflow/info_flow_model.dart';
import 'package:untitled1/database/db/hive_database_manager.dart';
import 'package:untitled1/utils/sp_util.dart';
import '../model/broadcaster/broadcaster_extra_info_model.dart';
import '../model/user/user_info_model.dart';
import 'app_config_manager.dart';

/// create: 2023/4/23
/// desc: 缓存管理
class CacheManager {
  static const String _userGetNameAndAvatarKey = "userGetNameAndAvatarKey";
  
  //获取用户名称头像信息接口缓存
  static UserInfoModel? userGetNameAndAvatarCache(String userId) {
    final key = "$_userGetNameAndAvatarKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
    final json = HiveDatabaseManager.stringCacheBox.get(key, defaultValue: "");
    if (json?.isEmpty ?? true) {
      return null;
    }
    try {
      return UserInfoModel.fromJson(jsonDecode(json!));
    } catch (e) {
      return null;
    }
  }

  //清空用户名称头像信息接口缓存
  static Future<void> clearUserGetNameAndAvatarCache(String userId) async {
    final key = "$_userGetNameAndAvatarKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
    await HiveDatabaseManager.stringCacheBox.delete(key);
  }

  //保存用户名称头像信息接口缓存
  static Future<bool> saveUserGetNameAndAvatarCache(String userId, String jsonData) async {
    try {
      final key = "$_userGetNameAndAvatarKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
      await HiveDatabaseManager.stringCacheBox.put(key, jsonData);
      return true;
    } catch (e) {
      return false;
    }
  }

  static const String _userGetInfoKey = "cache_manager_userGetInfo";

  //获取用户名详情信息接口缓存
  static UserInfoModel? userInfoCache(String userId) {
    final key = "$_userGetInfoKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
    final json = HiveDatabaseManager.stringCacheBox.get(key, defaultValue: "");
    if (json?.isEmpty ?? true) {
      return null;
    }
    try {
      return UserInfoModel.fromJson(jsonDecode(json!));
    } catch (e) {
      return null;
    }
  }

  //清空用户名详情信息接口缓存
  static Future<void> clearUserInfoCache(String userId) async {
    final key = "$_userGetInfoKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
    await HiveDatabaseManager.stringCacheBox.delete(key);
  }

  //保存用户名详情信息接口缓存
  static Future<bool> saveUserInfoCache(String userId, String jsonData) async {
    try {
      final key = "$_userGetInfoKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
      await HiveDatabaseManager.stringCacheBox.put(key, jsonData);
      return true;
    } catch (e) {
      return false;
    }
  }

  //用户扩展信息缓存
  static const String _userExtendInfoKey = "cache_manager_userExtendInfo";
  
  static BroadcasterExtraInfoModel? userExtendInfoCache(String userId) {
    final key = "$_userExtendInfoKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
    final json = HiveDatabaseManager.stringCacheBox.get(key, defaultValue: "");
    if (json?.isEmpty ?? true) {
      return null;
    }
    try {
      return BroadcasterExtraInfoModel.fromJson(jsonDecode(json!));
    } catch (e) {
      return null;
    }
  }

  //保存用户扩展信息缓存
  static Future<bool> saveUserExtendInfoCache(String userId, String jsonData) async {
    try {
      final key = "$_userExtendInfoKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
      await HiveDatabaseManager.stringCacheBox.put(key, jsonData);
      return true;
    } catch (e) {
      return false;
    }
  }

  //清空用户扩展信息缓存
  static Future<void> clearUserExtendInfoCache(String userId) async {
    final key = "$_userExtendInfoKey${userId}_${AppConfigManager.userInfoModel.userId ?? "0"}";
    await HiveDatabaseManager.stringCacheBox.delete(key);
  }

  //用户扩展信息缓存
  static const String _dyVideoKey = "cache_manager_dyvideo";
  
  static InfoFlowModel? dyVideoCache() {
    final key = "$_dyVideoKey${AppConfigManager.userInfoModel.userId ?? "0"}";
    final json = HiveDatabaseManager.stringCacheBox.get(key, defaultValue: "");
    if (json?.isEmpty ?? true) {
      return null;
    }
    try {
      return InfoFlowModel.fromJson(jsonDecode(json!));
    } catch (e) {
      return null;
    }
  }

  //保存用户扩展信息缓存
  static Future<bool> saveDyVideoCache(String jsonData) async {
    try {
      final key = "$_dyVideoKey${AppConfigManager.userInfoModel.userId ?? "0"}";
      await HiveDatabaseManager.stringCacheBox.put(key, jsonData);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清空旧的SPUtil缓存数据
  /// 在迁移到Hive后调用此方法清理SharedPreferences中的缓存
  static Future<void> clearLegacySPUtilCache() async {
    try {
      // 获取所有存储的key
      final Set<String> allKeys = SPUtil.getKeys();
      
      // 定义需要清理的缓存key前缀
      final List<String> cacheKeyPrefixes = [
        _userGetNameAndAvatarKey,
        _userGetInfoKey,
        _userExtendInfoKey,
        _dyVideoKey,
      ];
      
      // 清理匹配的缓存key
      for (String key in allKeys) {
        for (String prefix in cacheKeyPrefixes) {
          if (key.startsWith(prefix)) {
            await SPUtil.remove(key);
            break;
          }
        }
      }
      
      print('SPUtil legacy cache cleared successfully');
    } catch (e) {
      print('Error clearing SPUtil legacy cache: $e');
    }
  }

  /// 迁移SPUtil缓存数据到Hive
  /// 将SPUtil中的缓存数据迁移到Hive，然后清理SPUtil缓存
  static Future<void> migrateSPUtilCacheToHive() async {
    try {
      // 获取所有存储的key
      final Set<String> allKeys = SPUtil.getKeys();
      
      // 定义需要迁移的缓存key前缀
      final List<String> cacheKeyPrefixes = [
        _userGetNameAndAvatarKey,
        _userGetInfoKey,
        _userExtendInfoKey,
        _dyVideoKey,
      ];
      
      
      // 迁移匹配的缓存数据
      for (String key in allKeys) {
        for (String prefix in cacheKeyPrefixes) {
          if (key.startsWith(prefix)) {
            // 从SPUtil删除
            await SPUtil.remove(key);
            break;
          }
        }
      }
      
    } catch (e) {
      print('Error migrating SPUtil cache to Hive: $e');
    }
  }
}
