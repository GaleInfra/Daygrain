import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// @description: 系统全局的适配工具
class StyleUtil {
  ///[isPortrait] true锁定竖屏 false锁定横屏
  ///[isFullScreen] true全屏
  static Future<void> redoSystemStyle(
      {bool isPortrait = true, bool isFullScreen = false}) async {
    if (isPortrait) {
      //锁定竖屏
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
    } else {
      //锁定横屏
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    if (isFullScreen) {
      //全屏
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: [SystemUiOverlay.top]);
    } else {
      //默认
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    }
  }

  /// 改变状态栏颜色
  static setSystemUIOverlayStyleLight(bool isLight) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLight ? Brightness.light : Brightness.dark,
      ),
    );
  }
}
