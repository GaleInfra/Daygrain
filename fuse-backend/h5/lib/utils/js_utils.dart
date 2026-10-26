import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS('JSON.stringify')
external String stringify(Object obj);

@JS('JSON.parse')
external Object parse(String obj);

@JS('Object.keys')
external List<String> getObjectKeys(jsObject);

@JS('Object.entries')
external dynamic getObjectEntries(jsObject);

@JS('Map')
class JSMap {
  external factory JSMap([dynamic jsObject]);
  external JSMap set(dynamic key, dynamic value);
}

@JS('Array.from')
external List<dynamic> arrayFrom(jsObject);

/// dart map 转成 js 的 Object
dynamic dartToJS(obj) {
  if (obj is List) {
    return obj.map(dartToJS).toList();
  }
  if (obj is Map) {
    var jsObj = js_util.newObject();
    obj.forEach((k, v) {
      var value = dartToJS(v);
      js_util.setProperty(jsObj, k, value);
    });
    return jsObj;
  }
  return obj;
}

/// dart map 转为 js map
JSMap? toJSMap(Map<dynamic, dynamic>? map) {
  if (map == null) return null;
  var jsMap = JSMap();
  map.forEach((key, value) {
    jsMap.set(key, value);
  });
  return jsMap;
}

dynamic jsToDart(obj) {
  if (obj == null) return null;
  if (obj is bool || obj is num || obj is String) return obj;
  // JsArray
  if (obj is Iterable) return obj.map(jsToDart).toList();
  // Js Map
  if (obj.toString().contains('Map')) return jsMapToDart(obj);
  // JsObject
  return Map<String, dynamic>.fromIterable(getObjectKeys(obj), value: (key) => jsToDart(js_util.getProperty(obj, key)));
}

Map<String, dynamic> jsMapToDart(map) {
  // {k1:v1,k2:v2} => arrayFrom => [[k1,v1], [k2,v2]]
  return {for (var v in arrayFrom(map)) v[0]: v[1]};
}

@anonymous
@JS()
class BHCallbackJS {
  external dynamic get onSuccess;
  external set onSuccess(dynamic func);

  external dynamic get onError;
  external set onError(dynamic func);
}

class BHCallbackWeb {
  BHCallbackWeb({required this.onSuccess, required this.onError});

  final Function(dynamic value) onSuccess;
  final Function(int code) onError;

  BHCallbackJS toJS() {
    var callbackJS = BHCallbackJS();
    callbackJS.onSuccess = allowInterop(onSuccess);
    callbackJS.onError = allowInterop(onError);
    return callbackJS;
  }
}

@anonymous
@JS()
class BHSendMessageCallbackJS {
  external dynamic get onSuccess;
  external set onSuccess(dynamic func);

  external dynamic get onError;
  external set onError(dynamic func);

  external dynamic get onSendBefore;
  external set onSendBefore(dynamic func);
}

class BHSendMessageCallbackWeb {
  BHSendMessageCallbackWeb({required this.onSuccess, required this.onError, required this.onSendBefore});

  final Function(dynamic value) onSuccess;
  final Function(int code) onError;
  final Function(dynamic value) onSendBefore;

  BHSendMessageCallbackJS toJS() {
    var callbackJS = BHSendMessageCallbackJS();
    callbackJS.onSuccess = allowInterop(onSuccess);
    callbackJS.onError = allowInterop(onError);
    callbackJS.onSendBefore = allowInterop(onSendBefore);
    return callbackJS;
  }
}
//onSendBefore
