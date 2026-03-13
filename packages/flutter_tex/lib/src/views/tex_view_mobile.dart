import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex/src/utils/core_utils.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class TeXViewState extends State<TeXView> {
  final WebViewControllerPlus _webViewControllerPlus =
      TeXRenderingServer.webViewControllerPlus;

  double _teXViewHeight = initialHeight;
  String _lastRawData = "";

  @override
  void initState() {
    TeXRenderingServer.onTeXViewRenderedCallback = (_) async {
      final height =
          double.parse((await _webViewControllerPlus.webViewHeight).toString());
      if (_teXViewHeight != height && mounted) {
        setState(() {
          _teXViewHeight = height;
        });
        widget.onRenderFinished?.call(_teXViewHeight);
      }
    };

    TeXRenderingServer.onTapCallback =
        (tapCallbackMessage) => widget.child.onTapCallback(tapCallbackMessage);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _renderTeXView();
    return IndexedStack(
      index: widget.loadingWidgetBuilder?.call(context) != null
          ? _teXViewHeight == initialHeight
              ? 1
              : 0
          : 0,
      children: <Widget>[
        SizedBox(
          height: _teXViewHeight,
          child: WebViewWidget(
            controller: _webViewControllerPlus,
          ),
        ),
        widget.loadingWidgetBuilder?.call(context) ?? const SizedBox.shrink()
      ],
    );
  }

  void _renderTeXView() async {
    var currentRawData = getRawData(widget);
    if (currentRawData != _lastRawData) {
      if (widget.loadingWidgetBuilder != null) _teXViewHeight = initialHeight;
      await _webViewControllerPlus
          .runJavaScript("initTeXView($currentRawData);");
      _lastRawData = currentRawData;
    }
  }
}
