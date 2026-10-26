import 'dart:async';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// create: 2024/1/18
/// desc: 弹窗队列
class DialogQueueUtil {
  DialogQueueUtil._init();
  static final DialogQueueUtil _instance = DialogQueueUtil._init();
  static DialogQueueUtil get to => _instance;

  final List<DialogQueueElement> _queueList = [];

  // 对话框状态
  bool _isShowing = false;

  // 弹窗总闸：未打开时不消费队列
  bool _isGateOpen = true;

  // 添加弹窗
  Future addDialog(DialogQueueElement element) async {
    _queueList.add(element);
    _showNext();
  }

  // 关闭所有
  void closeAll() {
    _isShowing = false;
    SmartDialog.dismiss(status: SmartStatus.allDialog);
    _queueList.clear();
  }

  _showNext() {
    // 当总闸关闭时，允许具备“闸外展示能力”的弹窗穿透展示，但不改变队列顺序
    if (!_isGateOpen) {
      if (_isShowing) return;
      // 查找队列中第一个允许在关闸时展示且未消费的元素
      final int index = _queueList.indexWhere((e) => e.allowWhenGateClosed == true && e.consumed == false);
      if (index == -1) return;
      _isShowing = true;
      final DialogQueueElement element = _queueList[index];
      element.onShow.call().then((value) {
        // 标记为已消费，但保留其在队列中的原始位置，保持兼容性
        element.consumed = true;
        _isShowing = false;
        // 继续尝试展示下一个可穿透的弹窗
        _showNext();
      });
      return;
    }
    if (!_isShowing && _queueList.isNotEmpty) {
      // 当总闸打开时，跳过所有已经在关闸期间消费过的元素（保持队列顺序但不重复展示）
      while (_queueList.isNotEmpty && _queueList.first.consumed == true) {
        _queueList.removeAt(0);
      }
      if (_queueList.isEmpty) return;
      _isShowing = true;
      _queueList.removeAt(0).onShow.call().then((value) {
        _isShowing = false;
        _showNext();
      });
    }
  }

  /// 关闭总闸，暂停后续弹窗展示
  void closeGate() {
    _isGateOpen = false;
  }

  /// 打开总闸，恢复弹窗展示（会立刻尝试展示下一条）
  void openGate() {
    _isGateOpen = true;
    _showNext();
  }
}

typedef OnShow = Future Function();

class DialogQueueElement {
  DialogQueueElement({required this.onShow, this.allowWhenGateClosed = false})
      : consumed = false;

  final OnShow onShow;
  
  /// 当总闸关闭时，是否允许穿透展示
  final bool allowWhenGateClosed;
  
  /// 是否已经在关闸期间被消费展示过
  bool consumed;

  Future showDialog() {
    return onShow.call();
  }
}
