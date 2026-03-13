import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

/// A rendering server for TeXView. This is backed by a [LocalhostServer] and a [WebViewControllerPlus].
/// Make sure to call [run] before using the [webViewControllerPlus].
class TeXRenderingServer {
  static final WebViewControllerPlus webViewControllerPlus =
      WebViewControllerPlus();
  static final LocalhostServer _server = LocalhostServer();

  static RenderingEngineCallback? onPageFinished,
      onTapCallback,
      onTeXViewRenderedCallback;

  static Future<void> start(
      {int port = 0, Map mathJaxConfig = const {}}) async {
    var controllerCompleter = Completer<void>();

    await _server.start(port: port);

    webViewControllerPlus
      ..addJavaScriptChannel(
        'OnTapCallback',
        onMessageReceived: (onTapCallbackMessage) =>
            onTapCallback?.call(onTapCallbackMessage.message),
      )
      ..addJavaScriptChannel(
        'TeXViewRenderedCallback',
        onMessageReceived: (teXViewRenderedCallbackMessage) =>
            onTeXViewRenderedCallback
                ?.call(teXViewRenderedCallbackMessage.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _debugPrint("Page finished loading: $url");
            onPageFinished?.call(url);
            controllerCompleter.complete();
          },
          onNavigationRequest: (request) {
            if (request.url.contains(
                "http://localhost:${_server.port}/packages/flutter_tex/core/flutter_tex.html")) {
              return NavigationDecision.navigate;
            } else {
              _launchURL(request.url);
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..setOnConsoleMessage(
        (message) {
          _debugPrint(message.message);
        },
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadFlutterAssetWithServer(
          "packages/flutter_tex/core/flutter_tex.html", _server.port!);

    return controllerCompleter.future;
  }

  static _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  static void _debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static Future<void> stop() async {
    await _server.close();
  }
}

typedef RenderingEngineCallback = void Function(dynamic message);
