import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pane_node.dart';
import '../../providers/pane_tree_provider.dart';
import '../../services/file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

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
/// and call [save] from the title-bar save button.
class MarkdownEditorState extends ConsumerState<MarkdownEditor> {
  late final TextEditingController _controller;
  late final UndoHistoryController _undoController;
  late final FocusNode _focusNode;
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
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) _loadFile();
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
    // Only trigger once per dirty cycle to avoid flooding the provider.
    final node = findNode(ref.read(paneTreeProvider), widget.leafId);
    if (node is LeafNode && !node.hasUnsavedChanges) {
      ref.read(paneTreeProvider.notifier).markUnsaved(widget.leafId, true);
    }
  }

  /// Save the file and clear the unsaved indicator.
  Future<void> save() async {
    await FileService.instance.writeFile(widget.filePath, _controller.text);
    if (mounted) {
      ref.read(paneTreeProvider.notifier).markSaved(widget.leafId);
    }
  }

  void undo() => _undoController.undo();

  @override
  void dispose() {
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
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): save,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
      },
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
    );
  }
}
