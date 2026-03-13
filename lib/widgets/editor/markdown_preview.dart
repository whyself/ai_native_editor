import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:markdown/markdown.dart' as md;
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class MarkdownPreview extends StatefulWidget {
  final String filePath;
  final bool isDark;

  const MarkdownPreview({
    super.key,
    required this.filePath,
    required this.isDark,
  });

  @override
  State<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<MarkdownPreview> {
  String? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MarkdownPreview old) {
    super.didUpdateWidget(old);
    if (old.filePath != widget.filePath) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final content = await FileService.instance.readFile(widget.filePath);
    if (!mounted) return;
    setState(() {
      _content = content ?? '';
      _loading = false;
    });
  }

  /// Convert a Flutter [Color] to a CSS hex string (e.g. `#1a1a2e`).
  static String _hex(Color c) =>
      '#${(c.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  String _buildDocument(bool isDark) {
    final bg = _hex(isDark ? AppColors.darkBackground : AppColors.lightBackground);
    final text = _hex(isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final primary = _hex(isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final surface2 = _hex(isDark ? AppColors.darkSurface2 : AppColors.lightSurface2);
    final surface3 = _hex(isDark ? AppColors.darkSurface3 : AppColors.lightSurface3);
    final borderColor =
        _hex(isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle);
    final codeFg = isDark ? '#9B8DF7' : primary;

    final css = '''
html, body {
  background-color: $bg;
  color: $text;
  font-family: -apple-system, "Segoe UI", "Inter", sans-serif;
  font-size: 15px;
  line-height: 1.7;
  padding: ${AppTheme.sp24}px;
  margin: 0;
  word-wrap: break-word;
  box-sizing: border-box;
}
h1 { font-size: 28px; font-weight: 700; line-height: 1.3; margin: 1.2em 0 0.6em; }
h2 { font-size: 22px; font-weight: 600; line-height: 1.4; margin: 1em 0 0.5em; }
h3 { font-size: 18px; font-weight: 600; line-height: 1.4; margin: 0.8em 0 0.4em; }
h4, h5, h6 { font-size: 16px; font-weight: 600; margin: 0.6em 0 0.3em; }
p { margin: 0.8em 0; }
a { color: $primary; text-decoration: underline; }
code {
  font-family: "JetBrains Mono", "Fira Code", monospace;
  font-size: 13px;
  color: $codeFg;
  background: $surface3;
  padding: 2px 5px;
  border-radius: 4px;
}
pre {
  background: $surface2;
  border-radius: 8px;
  padding: 16px;
  overflow-x: auto;
  margin: 1em 0;
}
pre code { background: transparent; padding: 0; font-size: 13px; }
blockquote {
  border-left: 3px solid $primary;
  margin: 1em 0;
  padding: 4px 0 4px 16px;
  color: $text;
}
hr { border: none; border-top: 1px solid $borderColor; margin: 1em 0; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid $borderColor; padding: 8px 12px; text-align: left; }
th { background: $surface2; font-weight: 600; }
img { max-width: 100%; height: auto; border-radius: 4px; }
ul, ol { padding-left: 24px; }
li { margin: 4px 0; }
/* KaTeX display math centering */
.katex-display { margin: 1em 0; overflow-x: auto; overflow-y: hidden; }
''';

    // Convert markdown to HTML using github-flavoured rendering.
    final htmlBody = md.markdownToHtml(
      _content ?? '',
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );

    return '<style>$css</style>$htmlBody';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final primary =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    if (_loading) {
      return Container(
        color: bgColor,
        child: Center(
          child: CircularProgressIndicator(color: primary, strokeWidth: 2),
        ),
      );
    }

    return TeXView(
      child: TeXViewDocument(
        _buildDocument(widget.isDark),
        style: TeXViewStyle(
          backgroundColor: bgColor,
        ),
      ),
      style: TeXViewStyle(
        backgroundColor: bgColor,
      ),
      loadingWidgetBuilder: (_) => Container(
        color: bgColor,
        child: Center(
          child: CircularProgressIndicator(color: primary, strokeWidth: 2),
        ),
      ),
    );
  }
}
