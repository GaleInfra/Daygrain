import 'package:flutter/cupertino.dart';

/// create: 2023/5/8
/// desc:
class OverlayUtil {
  OverlayUtil._internal();

  static final OverlayUtil _instance = OverlayUtil._internal();

  factory OverlayUtil() => _instance;

  final Map<String, OverlayEntry> _entrys = {};

  /// 显示
  /// [tag] 该悬浮的标记名称
  void show({
    required BuildContext context,
    required Widget child,
    required String tag,
  }) {
    if (!_entrys.containsKey(tag)) {
      OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) {
          return child;
        },
      );
      _entrys.addAll({tag: overlayEntry});
      Overlay.of(context).insert(overlayEntry);
    }
  }

  /// 关闭
  /// [tag] 该悬浮的标记名称
  void dismiss({
    required String tag,
  }) {
    if (_entrys.containsKey(tag)) {
      _entrys[tag]?.remove();
      _entrys.remove(tag);
    }
  }

  /// 关闭所有
  void dismissAll() {
    _entrys.forEach((key, value) {
      value.remove();
    });
    _entrys.clear();
  }
}
