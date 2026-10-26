import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class WEbWebViewWidget extends StatefulWidget {
  final String url;

  WEbWebViewWidget({super.key, required this.url}) {
    // Register the view factory

    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
      (int viewId) => html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..width = '800'
        ..height = '600',
    );
  }

  @override
  _WEbWebViewWidgetState createState() => _WEbWebViewWidgetState();
}

class _WEbWebViewWidgetState extends State<WEbWebViewWidget> {
  @override
  void initState() {
    super.initState();
  }

  // 调用 JavaScript 函数
  void _callJavaScriptFunction() {
    // 获取 iframe 元素
    final iframe =
        html.document.getElementById('iframeElement') as html.IFrameElement;

    // 调用 iframe 中的 JavaScript 函数
    // iframe.contentWindow
    //     ?.callMethod('yourJavaScriptFunction', ['Hello from Flutter!']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HtmlElementView(viewType: 'iframeElement'),
        ElevatedButton(
          onPressed: _callJavaScriptFunction,
          child: const Text('Call JS Function'),
        ),
      ],
    );
  }
}
