import 'package:flutter/material.dart';

/// 防止文字自动换行
/// 当中英文混合，或者中文与数字或者特殊符号，或则英文单词时，文本会被自动换行，
/// 这样会导致，换行时上一行可能会留很大的空白区域
/// 把每个字符插入一个0宽的字符， \u{200B}
extension FixAutoLines on String {
  String fixAutoLines() {
    return Characters(this).join('\u{200B}');
  }

  //字符串截断超出部分显示...

  String truncateThan(int n, {suffix = '...'}) {
    if (characters.length <= n) {
      return this;
    }

    int count = 0;
    final buffer = StringBuffer();
    for (var codePoint in runes) {
      final isEmoji = _isEmoji(codePoint);
      if (!isEmoji) {
        buffer.write(String.fromCharCode(codePoint));
        count++;
      }
      if (count >= n) {
        break;
      }
    }
    return buffer.toString() + suffix;
  }

  static bool _isEmoji(int codePoint) {
    return (codePoint >= 0x1F600 && codePoint <= 0x1F64F) ||
        (codePoint >= 0x1F300 && codePoint <= 0x1F5FF) ||
        (codePoint >= 0x2700 && codePoint <= 0x27BF) ||
        (codePoint >= 0x2600 && codePoint <= 0x26FF) ||
        (codePoint >= 0xFE00 && codePoint <= 0xFE0F) ||
        (codePoint >= 0x1F1E6 && codePoint <= 0x1F1FF) ||
        (codePoint >= 0x1F680 && codePoint <= 0x1F6FF) ||
        (codePoint >= 0x1F900 && codePoint <= 0x1F9FF);
  }
}
