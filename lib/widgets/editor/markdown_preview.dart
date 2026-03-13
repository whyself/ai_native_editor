import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final primary = widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    if (_loading) {
      return Container(
        color: bgColor,
        child: Center(
          child: CircularProgressIndicator(color: primary, strokeWidth: 2),
        ),
      );
    }

    return Container(
      color: bgColor,
      child: Markdown(
        data: _content ?? '',
        selectable: true,
        padding: const EdgeInsets.all(AppTheme.sp24),
        onTapLink: (text, href, title) async {
          if (href != null) {
            final uri = Uri.tryParse(href);
            if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        styleSheet: MarkdownStyleSheet(
          p: GoogleFonts.inter(
            fontSize: 15,
            height: 1.7,
            color: textPrimary,
          ),
          h1: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            height: 1.3,
          ),
          h2: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            height: 1.4,
          ),
          h3: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            height: 1.4,
          ),
          code: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            color: widget.isDark ? const Color(0xFF9B8DF7) : AppColors.lightPrimary,
            backgroundColor: widget.isDark
                ? AppColors.darkSurface3
                : AppColors.lightSurface3,
          ),
          codeblockDecoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
            borderRadius: BorderRadius.circular(AppTheme.radius8),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: primary,
                width: 3,
              ),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 16),
          a: TextStyle(color: primary, decoration: TextDecoration.underline),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: widget.isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
