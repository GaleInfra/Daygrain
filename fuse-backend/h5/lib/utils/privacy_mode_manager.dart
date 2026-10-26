import 'package:shared_preferences/shared_preferences.dart';

class PrivacyModeManager {
  static const String _privacyModeKey = 'isPrivate';
  static const String _enterTimeKey = 'privacy_mode_enter_time';
  static const String _exitTimeKey = 'privacy_mode_exit_time';

  /// 设置隐私模式状态
  static Future<void> setPrivacyMode(bool isPrivate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyModeKey, isPrivate);

    // 记录进入或退出时间
    if (isPrivate) {
      // 进入隐私模式，记录当前时间
      await prefs.setInt(_enterTimeKey, DateTime.now().millisecondsSinceEpoch);
    } else {
      // 退出隐私模式，记录退出时间
      await prefs.setInt(_exitTimeKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// 获取隐私模式状态
  static Future<bool> isPrivacyModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyModeKey) ?? false;
  }

  /// 获取隐私模式停留时长（毫秒）
  static Future<int> getPrivacyModeDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final enterTime = prefs.getInt(_enterTimeKey) ?? 0;
    final exitTime = prefs.getInt(_exitTimeKey) ?? 0;

    if (enterTime == 0 || exitTime == 0 || exitTime < enterTime) {
      return 0;
    }

    return exitTime - enterTime;
  }

  /// 获取进入时间
  static Future<int> getEnterTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_enterTimeKey) ?? 0;
  }

  /// 获取退出时间
  static Future<int> getExitTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_exitTimeKey) ?? 0;
  }
}
