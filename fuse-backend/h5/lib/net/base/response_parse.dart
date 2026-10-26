
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:untitled1/base_manager.dart';
import 'package:untitled1/language/bh_language_manager.dart';
import 'package:untitled1/user_valid_manager.dart';

import '../../res/my_keys.dart';
import '../../utils/sp_util.dart';
import '../../utils/toast.dart';
import '../api_address.dart';
import '../transformer/default_http_transformer.dart';
import '../transformer/http_transformer.dart';
import 'api_response.dart';
import 'network_exception.dart';

/// @description: 成功回调函数
typedef Success<T> = Function(T data);

/// 错误回调函数
typedef Fail = Function(int code, String msg);

/// 接口返回msg回调（仅在接口成功时回调，因为接口失败时会有fail回调）
typedef MessageBack = Function(String msg);

/// 请求成功，处理内部状态码
/// [response] 返回体
/// [success] 成功回调
/// [onFail] 错误回调
/// Returns true when the caller should retry the request after a silent re-login.
Future<bool> onRequestSuccess(
  Response response,
  Success success,
  Fail? onFail,
  MessageBack? onMessageBack,
) async {
  HttpTransformer transformer = DefaultHttpTransformer.getInstance();
  ApiResponse apiResponse = transformer.parse(response);
  if (apiResponse.ok) {
    success.call(apiResponse.data);
  } else {
    if (_loginLose(apiResponse.error!.code)) {
      final shouldRetry = await _recoverLoginLost(response, apiResponse);
      if (shouldRetry) {
        return true;
      }
    } else {
      onFail?.call(apiResponse.error!.code, apiResponse.error!.message);
    }
  }
  onMessageBack?.call(apiResponse.msg ?? "");
  return false;
}

/// Silent re-login on session-lost codes. No toast and no Index/welcome
/// navigation when recovery succeeds; retry the request in place.
Future<bool> _recoverLoginLost(Response response, ApiResponse apiResponse) async {
  // oauth itself must not recurse into silent re-login
  if (response.requestOptions.path.contains(ApiAddress.login)) {
    return false;
  }
  // Cold start (welcome) owns token probe + oauth + the single Index push.
  // Starting silent re-login here deadlocks: validLogin/preRequest await
  // this request, which would await clickLogin, which awaits getStrategy.
  if (BaseManager.instance.isColdStartOpening) {
    return false;
  }
  final currentToken = response.requestOptions.headers["Authorization"];
  final localToken = SPUtil.getString(MyKeys.token);
  // Already recovering: never await the in-progress future (Dio callbacks
  // are not in the silent-relogin Zone, so a clickLogin getStrategy would
  // wait on the future that is waiting on it). Retry only if token rotated.
  if (BaseManager.instance.isSilentReloginInProgress) {
    if (localToken.isNotEmpty && currentToken != "Bearer $localToken") {
      return true;
    }
    return false;
  }
  final preToken = UserValidManager.instance.loginModel?.token;
  final matchesCurrentSession = currentToken == "Bearer $localToken" ||
      currentToken == "Bearer $preToken";
  if (matchesCurrentSession) {
    final recovered = await BaseManager.instance.trySilentRelogin();
    if (recovered) {
      return true;
    }
    _fallbackLoseLogin();
    return false;
  }
  // Stale request after a newer token was already saved — retry in place.
  if (localToken.isNotEmpty) {
    return true;
  }
  return false;
}

void _fallbackLoseLogin() {
  Toast.showMsg("error_invalidLogin".bhTR,
      displayType: SmartToastType.onlyRefresh);
  BaseManager.instance.loseLogin();
}

/// 错误回调
/// [code] 错误代码
/// [msg] 错误信息
/// [fail] 错误回调
void onError(int code, String msg, Fail? fail) {
  if (_loginLose(code)) {
    if (BaseManager.instance.isColdStartOpening ||
        BaseManager.instance.isSilentReloginInProgress) {
      fail?.call(code, msg);
      return;
    }
    // DioException path: same silent recovery as the parsed-body path.
    BaseManager.instance.trySilentRelogin().then((recovered) {
      if (!recovered) {
        _fallbackLoseLogin();
      }
    });
    return;
  }
  if (10010003 == code) {
    // 被系统拉黑 — not used for login-lost (those codes are handled above)
    Toast.showMsg(msg);
  }
  if (code == 0) {
    code = HttpExceptionCode.unknownError;
    msg = "error"; //'未知异常';
  } else if (code != HttpExceptionCode.timeoutError &&
      code != HttpExceptionCode.cancelError) {
    msg = "error_network".bhTR; // 网络异常
  }
  fail?.call(code, msg);
}

/// 是否登录失效
bool _loginLose(int code) {
  return code == 10010304 ||
      code == 100103 ||
      code == 10010303 ||
      code == 10010302 ||
      code == 10010301 ||
      code == 10010003;
}
