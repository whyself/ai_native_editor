import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

String _markdownFlutterTeX = r"""
# flutter_tex
[![GitHub stars](https://img.shields.io/github/stars/Shahxad-Akram/flutter_tex?style=social)](https://github.com/Shahxad-Akram/flutter_tex/stargazers) [![pub package](https://img.shields.io/pub/v/flutter_tex.svg)](https://pub.dev/packages/flutter_tex)

# Contents
- [flutter\_tex](#flutter_tex)
- [Contents](#contents)
- [About](#about)
- [How it works?](#how-it-works)
- [Demo Video](#demo-video)
  - [Click to Watch Demo on Youtube](#click-to-watch-demo-on-youtube)
- [How to setup?](#how-to-setup)
    - [Android](#android)
    - [iOS](#ios)
    - [Web](#web)
- [How to use?](#how-to-use)
- [Examples](#examples)
    - [Quick Example](#quick-example)
    - [TeXView Document Example](#texview-document-example)
      - [TeXView Document Example](#texview-document-example-1)
    - [TeXView Markdown Example](#texview-markdown-example)
      - [TeXView Markdown Example](#texview-markdown-example-1)
    - [TeXView Quiz Example](#texview-quiz-example)
      - [TeXView Quiz Example](#texview-quiz-example-1)
    - [TeXView Custom Fonts Example](#texview-custom-fonts-example)
      - [TeXView Custom Fonts Example](#texview-custom-fonts-example-1)
    - [TeXView Image and Video Example](#texview-image-and-video-example)
      - [TeXView Image and Video Example](#texview-image-and-video-example-1)
    - [TeXView InkWell Example](#texview-inkwell-example)
      - [TeXView InkWell Example](#texview-inkwell-example-1)
    - [Complete Example](#complete-example)
      - [Complete Example Code](#complete-example-code)
- [Web Demo:](#web-demo)
- [Api Changes:](#api-changes)
- [Api Usage:](#api-usage)
- [Limitations:](#limitations)

# About
A Flutter Package to render **fully offline** all types of equations and expressions based on **LaTeX** , **TeX** and **MathML**, most commonly used are as followings:

- **Mathematics / Maths Equations and expressions** (Algebra, Calculus, Geometry, Geometry etc...)

- **Physics Equations and expressions**

- **Signal Processing Equations and expressions**

- **Chemistry Equations and expressions**

- **Statistics / Stats Equations and expressions**

- It also includes full **HTML** with **JavaScript** support.

# How it works?

Flutter TeX is a flutter dart wrapper around the most powerful JavaScript library [MathJax](https://github.com/mathjax/MathJax) which render the equations in [webview_flutter_plus](https://pub.dartlang.org/packages/webview_flutter_plus). All credits goes to the developer of those libraries.


# Demo Video

## [Click to Watch Demo on Youtube](https://www.youtube.com/watch?v=YiNbVEXV_NM)

# How to setup?

**Minmum flutter SDK requirement is 3.27.x**


**1:** Add flutter_tex latest  [![pub package](https://img.shields.io/pub/v/flutter_tex.svg)](https://pub.dev/packages/flutter_tex) version under dependencies to your package's pubspec.yaml file.

```yaml
dependencies:
  flutter_tex: ^4.1.0
``` 

**2:** You can install packages from the command line:

```bash
$ flutter packages get
```

Alternatively, your editor might support flutter packages get. Check the docs for your editor to learn more.


**3:** Now you need to put the following implementations in `Android`, `iOS`, and `Web` respectively.

### Android
Make sure to add this line `android:usesCleartextTraffic="true"` in your `<project-directory>/android/app/src/main/AndroidManifest.xml` under `application` like this.

```xml
<application
       ...
       ...
       android:usesCleartextTraffic="true">
</application>
```

It completely works offline, without internet connection, but these are required permissions to work properly:


```xml
    <uses-permission android:name="android.permission.INTERNET" />
```

It'll still work in debug mode without permissions, but it won't work in release application without mentioned permissions.

### iOS
Add following code in your `<project-directory>/ios/Runner/Info.plist`

```plist
<key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key> <true/>
  </dict>
<key>io.flutter.embedded_views_preview</key> <true/> 
```

### Web
For Web support you need to put `<script src="assets/packages/flutter_tex/js/flutter_tex.js"></script>` and `<script type="text/javascript">window.flutterWebRenderer = "canvaskit";</script>` in `<head>` tag of your `<project-directory>/web/index.html` like this.

```html
<head>
    ...
    ...
    <script src="assets/packages/flutter_tex/js/flutter_tex.js"></script>
</head>
```

# How to use?

In your Dart code, you can use like:

```dart
import 'package:flutter_tex/flutter_tex.dart'; 
```

Make sure to setup `TeXRederingServer` before rendering TeX:

```dart
main() async {

  if (!kIsWeb) {
    await TeXRenderingServer.start();
  }

  runApp(...);
}
```

Now you can use `TeXView` as a widget:

# Examples

### Quick Example

```dart
TeXView(
    child: TeXViewColumn(children: [
      TeXViewInkWell(
        id: "id_0",
        child: TeXViewColumn(children: [
          TeXViewDocument(r\"\"\"<h2>Flutter \( \rm\\TeX \)</h2>\"\"\",
              style: TeXViewStyle(textAlign: TeXViewTextAlign.center)),
          TeXViewContainer(
            child: TeXViewImage.network(
                'https://raw.githubusercontent.com/Shahxad-Akram/flutter_tex/master/example/assets/flutter_tex_banner.png'),
            style: TeXViewStyle(
              margin: TeXViewMargin.all(10),
              borderRadius: TeXViewBorderRadius.all(20),
            ),
          ),
          TeXViewDocument(r\"\"\"<p>                                
                       When \(a \ne 0 \), there are two solutions to \(ax^2 + bx + c = 0\) and they are
                       $$x = {-b \pm \sqrt{b^2-4ac} \over 2a}.$$</p>\"\"\",
              style: TeXViewStyle.fromCSS(
                  'padding: 15px; color: white; background: green'))
        ]),
      )
    ]),
    style: TeXViewStyle(
      elevation: 10,
      borderRadius: TeXViewBorderRadius.all(25),
      border: TeXViewBorder.all(TeXViewBorderDecoration(
          borderColor: Colors.blue,
          borderStyle: TeXViewBorderStyle.solid,
          borderWidth: 5)),
      backgroundColor: Colors.white,
    ),
   );
```

### TeXView Document Example
#### [TeXView Document Example](https://github.com/Shahxad-Akram/flutter_tex/blob/master/example/lib/tex_view_document_example.dart)

### TeXView Markdown Example
#### [TeXView Markdown Example](https://github.com/Shahxad-Akram/flutter_tex/blob/master/example/lib/tex_view_markdown_example.dart)

### TeXView Quiz Example
#### [TeXView Quiz Example](https://github.com/Shahxad-Akram/flutter_tex/blob/master/example/lib/tex_view_quiz_example.dart)

### TeXView Custom Fonts Example
#### [TeXView Custom Fonts Example](https://github.com/Shahxad-Akram/flutter_tex/blob/master/example/lib/tex_view_fonts_example.dart)

### TeXView Image and Video Example
#### [TeXView Image and Video Example](https://github.com/Shahxad-Akram/flutter_tex/blob/master/example/lib/tex_view_image_video_example.dart)

### TeXView InkWell Example
#### [TeXView InkWell Example](https://github.com/Shahxad-Akram/flutter_tex/blob/master/example/lib/tex_view_ink_well_example.dart)

### Complete Example
#### [Complete Example Code](https://github.com/Shahxad-Akram/flutter_tex/tree/master/example)


[Demo Source](https://github.com/Shahxad-Akram/flutter_tex/tree/master/example)

# Web Demo:
You can find web demo at [https://flutter-tex.web.app](https://flutter-tex.web.app)

# Api Changes:
* Please see [CHANGELOG.md](https://github.com/Shahxad-Akram/flutter_tex/blob/master/CHANGELOG.md).

# Api Usage:
- `children:` A list of `TeXViewWidget`

- **`TeXViewWidget`**
    - `TeXViewDocument` Holds TeX data by using a raw string e.g. `r\"\"\"$$x = {-b \pm \sqrt{b^2-4ac} \over 2a}.$$<br> \"\"\"` You can also put HTML and Javascript code in it.
    - `TeXViewMarkdown` Holds markdown data.
    - `TeXViewContainer` Holds a single `TeXViewWidget` with styling.
    - `TeXViewImage` renders image from assets or network.
    - `TeXViewColumn` holds a list of `TeXViewWidget` vertically.
    - `TeXViewInkWell` for listening tap events. Its child and id is mandatory.
    - `TeXViewGroup` a group of `TeXViewGroupItem` usually used to create quiz layout.
    - `TeXViewDetails` like html `<details>`.


- `TeXViewStyle()` You can style each and everything using `TeXViewStyle()` or by using custom `CSS` code by `TeXViewStyle.fromCSS()` where you can pass hard coded String containing CSS code. For more information please check the example.
    

- `loadingWidgetBuilder:` Show a loading widget before rendering completes.

- `onRenderFinished:` Callback with the rendered page height, when TEX rendering finishes.

For more please see the [Example](https://github.com/Shahxad-Akram/flutter_tex/tree/master/example).

# Limitations:
- Please avoid using too many `TeXView` in a single page, because this is based on [webview_flutter_plus](https://pub.dartlang.org/packages/webview_flutter_plus) a complete web browser. Which may cause slowing down your app. I am trying to add all necessary widgets within `TeXView`, So please prefer to use `TeXViewWidget`. You can check [example folder](https://github.com/Shahxad-Akram/flutter_tex/tree/master/example) for details. If you find any problem you can [report an issue](https://github.com/Shahxad-Akram/flutter_tex/issues/new).


""";

class TeXViewMarkdownExamples extends StatelessWidget {
  const TeXViewMarkdownExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("TeXViewMarkdown"),
      ),
      body: TeXView(
        child: TeXViewMarkdown(_markdownFlutterTeX,
            style: TeXViewStyle.fromCSS("")),
        style: const TeXViewStyle(
          margin: TeXViewMargin.all(10),
          padding: TeXViewPadding.all(20),
          elevation: 10,
          borderRadius: TeXViewBorderRadius.all(25),
          border: TeXViewBorder.all(
            TeXViewBorderDecoration(
                borderColor: Colors.blue,
                borderStyle: TeXViewBorderStyle.solid,
                borderWidth: 5),
          ),
          backgroundColor: Colors.white,
        ),
        loadingWidgetBuilder: (context) => const Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              Text("Rendering...")
            ],
          ),
        ),
      ),
    );
  }
}
