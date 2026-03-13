import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'editor_toolbar.dart';

class MarkdownEditor extends StatefulWidget {
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
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final TextEditingController _controller;
  late final UndoHistoryController _undoController;
  late final FocusNode _focusNode;
  Timer? _saveTimer;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _undoController = UndoHistoryController();
    _focusNode = FocusNode();
    _loadFile();
  }

  @override
  void didUpdateWidget(MarkdownEditor old) {
    super.didUpdateWidget(old);
    if (old.filePath != widget.filePath) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    setState(() => _loaded = false);
    final content = await FileService.instance.readFile(widget.filePath);
    if (!mounted) return;
    _controller.text = content ?? '';
    _undoController.value = UndoHistoryValue.empty;
    setState(() => _loaded = true);
  }

  void _onChanged(String _) {
    // Mark unsaved
    if (mounted) {
      // Notify provider about unsaved state
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), _save);
    }
  }

  Future<void> _save() async {
    await FileService.instance.writeFile(widget.filePath, _controller.text);
    if (mounted) {
      // Will be called by parent to clear unsaved state
    }
  }

  void _undo() => _undoController.undo();

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller.dispose();
    _undoController.dispose();
    _focusNode.dispose();
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

    if (!_loaded) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          strokeWidth: 2,
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: bgColor,
              child: TextField(
                controller: _controller,
                undoController: _undoController,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: _onChanged,
                cursorColor: caretColor,
                selectionControls: materialTextSelectionControls,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  height: 1.6,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppTheme.sp16),
                  fillColor: bgColor,
                  filled: true,
                ),
              ),
            ),
          ),
          // Formatting toolbar (shown always for touch users)
          EditorToolbar(
            controller: _controller,
            isDark: widget.isDark,
          ),
        ],
      ),
    );
  }
}
