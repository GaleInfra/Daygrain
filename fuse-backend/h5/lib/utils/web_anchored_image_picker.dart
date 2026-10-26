import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class _PickSession {
  _PickSession(this.input, this.completer);

  final html.FileUploadInputElement input;
  final Completer<html.File?> completer;
  bool settled = false;

  void completeOnce(html.File? file) {
    if (settled) return;
    settled = true;
    html.window.removeEventListener('focus', onFocus);
    input.remove();
    if (!completer.isCompleted) completer.complete(file);
  }

  void onChange(html.Event _) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      completeOnce(files.first);
    } else {
      completeOnce(null);
    }
  }

  void onFocus(html.Event _) {
    html.window.removeEventListener('focus', onFocus);
    Future<void>.delayed(const Duration(milliseconds: 500)).whenComplete(() {
      if (!settled) completeOnce(null);
    });
  }
}

/// iOS WKWebView 会把系统「相册 / 拍照 / 选文件」气泡锚在 `<input type=file>` 的布局框上。
/// [image_picker_web] 先 click 再 append、且不设坐标，气泡会飘到页面角落或文档流末尾。
/// 这里把 input 钉在最近一次指针位置再 click，弹层贴在触发控件附近。
class WebAnchoredImagePicker {
  WebAnchoredImagePicker._();

  static bool _listening = false;
  static double? _lastClientX;
  static double? _lastClientY;

  static void ensurePointerTracking() {
    if (_listening) return;
    _listening = true;
    void remember(num x, num y) {
      _lastClientX = x.toDouble();
      _lastClientY = y.toDouble();
    }

    html.document.addEventListener('pointerdown', (html.Event e) {
      if (e is html.PointerEvent) remember(e.client.x, e.client.y);
    }, true);
    html.document.addEventListener('mousedown', (html.Event e) {
      if (e is html.MouseEvent) remember(e.client.x, e.client.y);
    }, true);
    html.document.addEventListener('touchstart', (html.Event e) {
      if (e is html.TouchEvent && e.touches != null && e.touches!.isNotEmpty) {
        final t = e.touches!.first;
        remember(t.client.x, t.client.y);
      }
    }, true);
  }

  static Future<html.File?> getImageAsFile({
    double? clientX,
    double? clientY,
  }) async {
    ensurePointerTracking();
    final completer = Completer<html.File?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    _pinToAnchor(input, clientX: clientX, clientY: clientY);

    final session = _PickSession(input, completer);
    input.onChange.listen(session.onChange);
    html.window.addEventListener('focus', session.onFocus);

    // 必须先入 DOM 再 click，否则 Safari / WKWebView 锚点无效。
    html.document.body?.append(input);
    input.click();

    return completer.future;
  }

  static Future<Uint8List?> getImageAsBytes({
    double? clientX,
    double? clientY,
  }) async {
    final file = await getImageAsFile(clientX: clientX, clientY: clientY);
    if (file == null) return null;
    final reader = html.FileReader();
    final done = Completer<Uint8List?>();
    reader.onError.listen((_) {
      if (!done.isCompleted) done.complete(null);
    });
    reader.onLoad.listen((_) {
      final result = reader.result;
      if (result is ByteBuffer) {
        done.complete(Uint8List.view(result));
      } else if (result is TypedData) {
        done.complete(Uint8List.fromList(result.buffer.asUint8List()));
      } else {
        done.complete(null);
      }
    });
    reader.readAsArrayBuffer(file);
    return done.future;
  }

  static void _pinToAnchor(
    html.FileUploadInputElement input, {
    double? clientX,
    double? clientY,
  }) {
    final vw = (html.window.innerWidth ?? 390).toDouble();
    final vh = (html.window.innerHeight ?? 844).toDouble();
    final rawX = clientX ?? _lastClientX ?? (vw / 2);
    final rawY = clientY ?? _lastClientY ?? (vh / 2);
    const size = 44.0;
    final left = (rawX - size / 2).clamp(0.0, (vw - size).clamp(0.0, vw));
    final top = (rawY - size / 2).clamp(0.0, (vh - size).clamp(0.0, vh));

    input.style
      ..position = 'fixed'
      ..left = '${left}px'
      ..top = '${top}px'
      ..width = '${size}px'
      ..height = '${size}px'
      ..opacity = '0'
      ..border = '0'
      ..padding = '0'
      ..margin = '0'
      ..overflow = 'hidden'
      ..zIndex = '2147483647'
      ..setProperty('webkitTapHighlightColor', 'transparent');
  }
}
