import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_markdown_latex/flutter_markdown_latex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/live_content_provider.dart';
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Safe LaTeX inline syntax: only matches  $...$  and  $$...$$  delimiters.
///
/// [LatexInlineSyntax] from flutter_markdown_latex also registers ( ) and [ ]
/// as delimiters, which match ordinary prose and trigger a null-bool cast crash.
/// This replacement restricts matching to dollar-sign delimiters only.
class _SafeLatexInlineSyntax extends md.InlineSyntax {
  _SafeLatexInlineSyntax()
      : super(r'\$\$([^\$\n]+?)\$\$|\$([^\$\n]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final isDisplay = match.group(1) != null;
    final content = match.group(1) ?? match.group(2) ?? '';
    final element = md.Element.text('latex', content);
    element.attributes['MathStyle'] = isDisplay ? 'display' : 'text';
    parser.addNode(element);
    return true;
  }
}

class MarkdownPreview extends ConsumerStatefulWidget {
  final String filePath;
  final bool isDark;

  const MarkdownPreview({
    super.key,
    required this.filePath,
    required this.isDark,
  });

  @override
  ConsumerState<MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends ConsumerState<MarkdownPreview> {
  /// Content loaded from disk — used as fallback when no live draft exists.
  String _diskContent = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(MarkdownPreview old) {
    super.didUpdateWidget(old);
    if (old.filePath != widget.filePath) _loadFile();
  }

  Future<void> _loadFile() async {
    setState(() => _loading = true);
    final content = await FileService.instance.readFile(widget.filePath);
    if (!mounted) return;
    setState(() {
      _diskContent = content ?? '';
      _loading = false;
    });
  }

  MarkdownStyleSheet _buildStyleSheet(bool isDark) {
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final surface2 = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final surface3 = isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final codeFg = isDark ? AppColors.darkPrimaryGlow : primary;

    final mono = GoogleFonts.jetBrainsMono(fontSize: 13, color: codeFg);

    return MarkdownStyleSheet(
      p: TextStyle(color: textColor, fontSize: 15, height: 1.7),
      h1: TextStyle(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.3),
      h2: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4),
      h3: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4),
      h4: TextStyle(
          color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
      h5: TextStyle(
          color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
      h6: TextStyle(
          color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
      em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
      strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      del: TextStyle(
          color: textColor, decoration: TextDecoration.lineThrough),
      a: TextStyle(
          color: primary,
          decoration: TextDecoration.underline,
          decorationColor: primary),
      code: mono.copyWith(backgroundColor: surface3),
      codeblockDecoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(8),
      ),
      codeblockPadding: const EdgeInsets.all(16),
      blockquote: TextStyle(color: textColor),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: primary, width: 3)),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
      tableHead: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      tableBody: TextStyle(color: textColor),
      tableBorder: TableBorder.all(color: borderColor),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      listBullet: TextStyle(color: textColor, fontSize: 15),
      listIndent: 24,
      blockSpacing: 12,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
    );
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

    // Prefer live (unsaved) editor draft; fall back to on-disk content.
    final liveContent = ref.watch(liveContentProvider(widget.filePath));
    final content = liveContent ?? _diskContent;

    return ColoredBox(
      color: bgColor,
      child: Markdown(
        // Key includes content hash so the scroll position resets on file
        // switch but NOT on every live-content update (avoids scroll jump).
        key: ValueKey(widget.filePath),
        data: content,
        styleSheet: _buildStyleSheet(widget.isDark),
        padding: const EdgeInsets.all(AppTheme.sp24),
        selectable: true,
        builders: {
          'latex': LatexElementBuilder(
            textStyle: TextStyle(color: primary),
            textScaleFactor: 1.1,
          ),
        },
        extensionSet: md.ExtensionSet(
          [
            ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
            LatexBlockSyntax()
          ],
          [
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            _SafeLatexInlineSyntax()
          ],
        ),
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href),
                mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
