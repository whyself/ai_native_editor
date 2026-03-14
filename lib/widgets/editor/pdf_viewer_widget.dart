import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Renders a PDF file. Supports two display modes:
///   - Page mode (default): one page at a time with ‹ / › navigation.
///   - Continuous mode: all pages in a seamless scrollable list.
class PdfViewerWidget extends StatefulWidget {
  final String filePath;
  final bool isDark;

  const PdfViewerWidget({
    super.key,
    required this.filePath,
    required this.isDark,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  // ── Mode ───────────────────────────────────────────────────────────────────
  bool _isContinuous = false;

  // ── Page mode state ────────────────────────────────────────────────────────
  PdfController? _pageController;
  int _currentPage = 1;
  int _totalPages = 0;

  // ── Continuous mode state ──────────────────────────────────────────────────
  PdfControllerPinch? _pinchController;

  // ── Shared ─────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buildPageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _pinchController?.dispose();
    super.dispose();
  }

  // ── Controller lifecycle ───────────────────────────────────────────────────

  void _buildPageController() {
    try {
      _pageController = PdfController(
        document: PdfDocument.openFile(widget.filePath),
        initialPage: _currentPage,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _buildPinchController() {
    try {
      _pinchController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.filePath),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleMode() {
    if (_isContinuous) {
      // Switch back to page mode
      _pinchController?.dispose();
      _pinchController = null;
      setState(() {
        _isContinuous = false;
        _loading = true;
        _error = null;
      });
      _buildPageController();
    } else {
      // Switch to continuous mode
      _pageController?.dispose();
      _pageController = null;
      setState(() {
        _isContinuous = true;
        _loading = true;
        _error = null;
      });
      _buildPinchController();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface2 =
        widget.isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border = widget.isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;
    final textSecondary = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted =
        widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final primary =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    if (_error != null) {
      return _ErrorView(
          bg: bg, textMuted: textMuted, error: _error!);
    }

    return Column(
      children: [
        // ── Navigation / mode bar ─────────────────────────────────────────
        Container(
          height: 36,
          padding:
              const EdgeInsets.symmetric(horizontal: AppTheme.sp8),
          decoration: BoxDecoration(
            color: surface2,
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Row(
            children: [
              // Mode toggle
              Tooltip(
                message: _isContinuous ? '切换为分页浏览' : '切换为连续滚动',
                child: InkWell(
                  onTap: _toggleMode,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    child: Icon(
                      _isContinuous
                          ? Icons.auto_stories_outlined
                          : Icons.view_agenda_outlined,
                      size: 16,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),

              // Page-mode navigation (hidden in continuous mode)
              if (!_isContinuous) ...[
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18),
                  color: textSecondary,
                  onPressed: !_loading && _currentPage > 1
                      ? () => _pageController?.previousPage(
                            duration:
                                const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          )
                      : null,
                  tooltip: '上一页',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 28, minHeight: 28),
                ),
                const SizedBox(width: AppTheme.sp4),
                Text(
                  _loading ? '加载中…' : '$_currentPage / $_totalPages',
                  style:
                      TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(width: AppTheme.sp4),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  color: textSecondary,
                  onPressed: !_loading && _currentPage < _totalPages
                      ? () => _pageController?.nextPage(
                            duration:
                                const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          )
                      : null,
                  tooltip: '下一页',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 28, minHeight: 28),
                ),
                const Spacer(),
              ],

              // In continuous mode: just show total-pages label on the right
              if (_isContinuous) ...[
                const Spacer(),
                Text(
                  _loading
                      ? '加载中…'
                      : (_totalPages > 0
                          ? '共 $_totalPages 页'
                          : ''),
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ],
          ),
        ),

        // ── PDF content ───────────────────────────────────────────────────
        Expanded(
          child: ColoredBox(
            color: bg,
            child: _isContinuous
                ? _buildContinuousView(primary)
                : _buildPageView(primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPageView(Color primary) {
    if (_pageController == null) return const SizedBox.shrink();
    return PdfView(
      controller: _pageController!,
      scrollDirection: Axis.vertical,
      onDocumentLoaded: (doc) {
        setState(() {
          _totalPages = doc.pagesCount;
          _currentPage = 1;
          _loading = false;
        });
      },
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
      onDocumentError: (err) {
        setState(() {
          _error = err.toString();
          _loading = false;
        });
      },
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            Center(child: CircularProgressIndicator(color: primary)),
        pageLoaderBuilder: (_) =>
            Center(child: CircularProgressIndicator(color: primary)),
      ),
    );
  }

  Widget _buildContinuousView(Color primary) {
    if (_pinchController == null) return const SizedBox.shrink();
    return PdfViewPinch(
      controller: _pinchController!,
      onDocumentLoaded: (doc) {
        setState(() {
          _totalPages = doc.pagesCount;
          _loading = false;
        });
      },
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            Center(child: CircularProgressIndicator(color: primary)),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final Color bg;
  final Color textMuted;
  final String error;

  const _ErrorView(
      {required this.bg, required this.textMuted, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 36, color: textMuted),
            const SizedBox(height: AppTheme.sp8),
            Text('无法打开 PDF',
                style: TextStyle(color: textMuted)),
            const SizedBox(height: AppTheme.sp4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error,
                style: TextStyle(fontSize: 11, color: textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
