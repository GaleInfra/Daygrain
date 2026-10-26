import 'dart:convert';
import 'dart:developer';

class RunJavaScript {
  static String getInitWebView(Map<String, dynamic> apis) {
    String jsonStr = '';

    apis.forEach((key, value) {
      jsonStr +=
      '$key:(arg)=>{$value.postMessage(typeof arg=="object"? JSON.stringify( arg || {} ) :  (arg || "" ) ) },';
    });

    String script = 'window.JSBridgeService = {$jsonStr};';
    log("Flutter insert script:: $script");
    return script;
  }

  static String setJsApiWithGetSupportApi(Map<String, dynamic> apis) {
    String jsonStr = '';
    List<String> apis0 = [];

    apis.forEach((key, value) {
      apis0.add(key);
    });
    jsonStr = jsonEncode(apis0);

    // String script = 'window.getSupportApi(' + jsonStr + ');';
    String script = 'window.getSupportApi=()=>$jsonStr';
    log("Flutter insert script:: $script");
    return script;
  }

}
