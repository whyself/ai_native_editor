import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pane_node.dart';
import '../../providers/pane_tree_provider.dart';
import '../../providers/live_content_provider.dart';
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

// Editor typography constants — must stay in sync between editor and line numbers.
const _kFontSize = 14.0;
const _kLineHeight = 1.6;
const _kLineHeightPx = _kFontSize * _kLineHeight; // 22.4 px per line
const _kEditorPadding = AppTheme.sp16; // 16 px top / bottom / left / right

class MarkdownEditor extends ConsumerStatefulWidget {
  final String leafId;
  final String filePath;
  final bool isDark;

  const MarkdownEditor({
    super.key,
    required this.leafId,
    required this.filePath,
    required this.isDark,
  });

  @override
  MarkdownEditorState createState() => MarkdownEditorState();
}

/// Public state so [LeafNodeWidget] can hold a [GlobalKey<MarkdownEditorState>]
/// and call [save] / [undo] from the title-bar buttons.
class MarkdownEditorState extends ConsumerState<MarkdownEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _editorScrollController;
  late final ScrollController _lineNumberController;
  bool _loaded = false;

  // ── Simple debounced undo stack ──────────────────────────────────────────
  final List<String> _undoHistory = [];
  String _lastSnapshot = '';
  Timer? _undoDebounce;

  // ── Debounced preview sync ────────────────────────────────────────────────
  Timer? _previewSyncTimer;

  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _editorScrollController = ScrollController();
    _lineNumberController = ScrollController();
    // Mirror editor scroll → line numbers
    _editorScrollController.addListener(_syncLineNumbers);
    _loadFile();
  }

  void _syncLineNumbers() {
    if (!_lineNumberController.hasClients ||
        !_editorScrollController.hasClients) return;
    final offset = _editorScrollController.offset;
    final max = _lineNumberController.position.maxScrollExtent;
    _lineNumberController.jumpTo(offset.clamp(0.0, max));
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) _loadFile();
  }

  Future<void> _loadFile() async {
    setState(() => _loaded = false);
    _undoDebounce?.cancel();
    _previewSyncTimer?.cancel();
    _undoHistory.clear();
    // Clear any stale live-content so the preview reads from disk.
    ref.read(liveContentProvider(widget.filePath).notifier).state = null;
    final content = await FileService.instance.readFile(widget.filePath);
    if (!mounted) return;
    _controller.text = content ?? '';
    _lastSnapshot = _controller.text;
    _lineCount = _countLines(_controller.text);
    setState(() => _loaded = true);
  }

  static int _countLines(String text) =>
      text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

  void _onChanged(String text) {
    // Update line count.
    final newCount = _countLines(text);
    if (newCount != _lineCount) setState(() => _lineCount = newCount);

    // Mark unsaved once per dirty cycle.
    final node = findNode(ref.read(paneTreeProvider), widget.leafId);
    if (node is LeafNode && !node.hasUnsavedChanges) {
      ref.read(paneTreeProvider.notifier).markUnsaved(widget.leafId, true);
    }

    // Debounced history push: push previous snapshot after 600 ms of inactivity.
    _undoDebounce?.cancel();
    _undoDebounce = Timer(const Duration(milliseconds: 600), () {
      _undoHistory.add(_lastSnapshot);
      _lastSnapshot = text;
      if (_undoHistory.length > 100) _undoHistory.removeAt(0);
    });

    // Debounced preview sync: update live content after 800 ms of inactivity.
    _previewSyncTimer?.cancel();
    _previewSyncTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        ref.read(liveContentProvider(widget.filePath).notifier).state = text;
      }
    });
  }

  /// Save the file and clear the unsaved indicator.
  Future<void> save() async {
    // Flush any pending undo snapshot immediately before saving.
    _undoDebounce?.cancel();
    _undoHistory.add(_lastSnapshot);
    _lastSnapshot = _controller.text;

    await FileService.instance.writeFile(widget.filePath, _controller.text);
    if (mounted) {
      // Immediately push current text to the preview (cancels pending debounce).
      _previewSyncTimer?.cancel();
      ref.read(liveContentProvider(widget.filePath).notifier).state =
          _controller.text;
      ref.read(paneTreeProvider.notifier).markSaved(widget.leafId);
    }
  }

  void undo() {
    if (_undoHistory.isEmpty) return;
    _undoDebounce?.cancel();
    final prev = _undoHistory.removeLast();
    _lastSnapshot = prev;
    // Preserve cursor at end of restored text.
    _controller.value = TextEditingValue(
      text: prev,
      selection: TextSelection.collapsed(offset: prev.length),
    );
    // Ensure text field has focus so the change is visible.
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _undoDebounce?.cancel();
    _previewSyncTimer?.cancel();
    _editorScrollController.removeListener(_syncLineNumbers);
    _controller.dispose();
    _focusNode.dispose();
    _editorScrollController.dispose();
    _lineNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final caretColor =
        widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final lineNumBg =
        widget.isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final lineNumColor =
        widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final dividerColor = widget.isDark
        ? AppColors.darkBorderSubtle
        : AppColors.lightBorderSubtle;

    if (!_loaded) {
      return Center(
        child: CircularProgressIndicator(
          color: caretColor,
          strokeWidth: 2,
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): save,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Line numbers column ──────────────────────────────────────
          Container(
            width: 48,
            color: lineNumBg,
            child: Stack(
              children: [
                // Right border
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(width: 1, color: dividerColor),
                ),
                // Number list (mirrors editor scroll position)
                Positioned.fill(
                  child: ListView.builder(
                    controller: _lineNumberController,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                        top: _kEditorPadding, bottom: _kEditorPadding),
                    itemCount: _lineCount,
                    itemExtent: _kLineHeightPx,
                    itemBuilder: (_, i) => Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            height: _kLineHeightPx / 12,
                            color: lineNumColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Editor ──────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: bgColor,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _editorScrollController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: _onChanged,
                cursorColor: caretColor,
                selectionControls: materialTextSelectionControls,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: _kFontSize,
                  height: _kLineHeight,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(_kEditorPadding),
                  fillColor: bgColor,
                  filled: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
