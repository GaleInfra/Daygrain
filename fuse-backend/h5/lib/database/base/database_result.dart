/// 返回数据封装
class DatabaseResult<T> {
  DatabaseResult({
    required this.status,
    required this.msg,
    required this.data,
  });

  /// 成功封装
  DatabaseResult.success({
    this.msg = '成功',
    required this.data,
  }) {
    status = true;
  }

  /// 失败封装
  DatabaseResult.fail({
    required this.msg,
  }) {
    status = false;
  }

  /// 查询成功
  late bool status;

  /// 返回消息
  String msg;

  /// 返回数据
  T? data;
}
