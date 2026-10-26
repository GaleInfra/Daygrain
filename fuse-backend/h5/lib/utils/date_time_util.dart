/// create: 2023/5/4
/// desc:
class DateTimeUtil {
  /// 消息列表时间格式化
  static String timeFormat(int time) {
    if (time == 0) {
      return "";
    }
    var current = DateTime.fromMillisecondsSinceEpoch(time);
    var now = DateTime.now();

    ///现在的ui显示最后一条消息的发送时间
    return "${current.year != now.year ? "${current.year}-" : ""} ${current.month}-${current.day} ${current.hour}:${(current.minute.toString().padLeft(2, "0"))}";
    // var difference = now.difference(current);
    // if (difference.inSeconds < 60) {
    //   return "now";
    // } else if (difference.inMinutes < 60) {
    //   return "${difference.inMinutes} m ago";
    // } else if (difference.inHours < 24) {
    //   // 小于1天
    //   return "${difference.inHours} h ago";
    // } else if (difference.inDays < 7) {
    //   // 小于7天大于1天，显示几天前
    //   return "${difference.inDays} d ago";
    // } else {
    //   return "${current.year != now.year ? "${current.year}-" : ""}"
    //       "${current.month}-${current.day}";
    // }
  }

  /// 转为mm:ss格式
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  /// 转为mm:ss格式
  static String formatDurationEva(int duration) {
    int hour = duration ~/ 3600; // 使用整除符号
    int min = (duration ~/ 60) % 60;
    int second = duration % 60;
    String timeText = "";
    if (hour > 0) {
      timeText = "${hour}h${min}m${second}s";
    } else if (min > 0) {
      timeText = "${min}m${second}s";
    } else {
      timeText = "${second}s";
    }
    return timeText;
  }

  /// 转换语音条格式
  static String formatVoiceDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return "${duration.inSeconds}''";
    }
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes'$seconds''";
  }

  /// 获取 yyyy-MM-dd 格式时间
  static String getDateTimeStr({DateTime? dateTime}) {
    dateTime ??= DateTime.now();
    return "${dateTime.year}-${dateTime.month < 10 ? "0${dateTime.month}" : dateTime.month}-${dateTime.day < 10 ? "0${dateTime.day}" : dateTime.day}";
  }

  static String getDateTimeForChat(DateTime dateTime) {
    String year = "";
    String month = "";
    String day = "";
    DateTime now = DateTime.now();
    if (now.year != dateTime.year) {
      year = "${dateTime.year.toString()}-";
    }
    if (now.year != dateTime.year ||
        now.month != dateTime.month ||
        now.day != dateTime.day) {
      month = "${dateTime.month.toString()}-";
      day = "${dateTime.day.toString()}  ";
    }

    return "$year$month$day${dateTime.hour < 10 ? "0${dateTime.hour}" : dateTime.hour}:${dateTime.minute < 10 ? "0${dateTime.minute}" : dateTime.minute}";
  }

  //// 获取当前时间的秒级时间戳
  static int getNowSecond() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  // 判断时间戳是否是今天 秒级单位
  static bool isToday(int timestamp) {
    DateTime now = DateTime.now();
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000); // 将时间戳转换为 DateTime 对象
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
