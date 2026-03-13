import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Markdown formatting toolbar shown above the keyboard during editing.
class EditorToolbar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const EditorToolbar({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp8),
        child: Row(
          children: [
            _formatBtn('H1', () => _insertPrefix('# ')),
            _formatBtn('H2', () => _insertPrefix('## ')),
            _formatBtn('H3', () => _insertPrefix('### ')),
            _divider(),
            _iconBtn(Icons.format_bold, () => _wrapSelection('**', '**')),
            _iconBtn(Icons.format_italic, () => _wrapSelection('*', '*')),
            _iconBtn(Icons.format_strikethrough, () => _wrapSelection('~~', '~~')),
            _divider(),
            _iconBtn(Icons.code, () => _wrapSelection('`', '`')),
            _formatBtn('```', () => _insertCodeBlock()),
            _divider(),
            _iconBtn(Icons.format_list_bulleted, () => _insertPrefix('- ')),
            _iconBtn(Icons.check_box_outline_blank, () => _insertPrefix('- [ ] ')),
            _iconBtn(Icons.link, () => _insertLink()),
          ],
        ),
      ),
    );
  }

  Widget _formatBtn(String label, VoidCallback onTap) {
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: textSecondary),
      ),
    );
  }

  Widget _divider() {
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: border,
    );
  }

  void _insertPrefix(String prefix) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) {
      controller.text = '$prefix$text';
      controller.selection = TextSelection.collapsed(offset: prefix.length);
      return;
    }
    // Find start of line
    final start = text.lastIndexOf('\n', sel.start - 1) + 1;
    final newText = text.replaceRange(start, start, prefix);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + prefix.length),
    );
  }

  void _wrapSelection(String before, String after) {
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid) return;
    final selected = sel.textInside(text);
    final replacement = '$before$selected$after';
    final newText = text.replaceRange(sel.start, sel.end, replacement);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.start + before.length + selected.length,
      ),
    );
  }

  void _insertCodeBlock() {
    final text = controller.text;
    final sel = controller.selection;
    final pos = sel.isValid ? sel.start : text.length;
    const block = '```\n\n```';
    final newText = text.replaceRange(pos, sel.isValid ? sel.end : pos, block);
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + 4),
    );
  }

  void _insertLink() {
    final text = controller.text;
    final sel = controller.selection;
    final selected = sel.isValid ? sel.textInside(text) : '';
    const placeholder = '[文字](url)';
    final replacement = selected.isEmpty ? placeholder : '[$selected](url)';
    final newText = text.replaceRange(
      sel.isValid ? sel.start : text.length,
      sel.isValid ? sel.end : text.length,
      replacement,
    );
    controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (sel.isValid ? sel.start : text.length) + replacement.length,
      ),
    );
  }
}
