import 'package:flutter/material.dart';
import '../../models/pane_node.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PaneTitleBar extends StatelessWidget {
  final LeafNode leaf;
  final VoidCallback onClose;
  final VoidCallback onTogglePreview;
  final VoidCallback onOpenPreview;
  final VoidCallback onUndo;
  final bool isDark;

  const PaneTitleBar({
    super.key,
    required this.leaf,
    required this.onClose,
    required this.onTogglePreview,
    required this.onOpenPreview,
    required this.onUndo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          // File name (draggable handle - long-press)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.sp12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: AppTheme.sp6),
                  Flexible(
                    child: Text(
                      leaf.hasUnsavedChanges
                          ? '${leaf.displayName} ●'
                          : leaf.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: leaf.hasUnsavedChanges ? primary : textPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Source / Rendered toggle (only for markdown)
          if (leaf.filePath != null && leaf.contentType == ContentType.markdown)
            _SegmentedControl(
              isPreview: leaf.isPreviewMode,
              onToggle: onTogglePreview,
              isDark: isDark,
            ),

          const SizedBox(width: AppTheme.sp4),

          // Undo button
          if (!leaf.isPreviewMode && leaf.filePath != null)
            _TitleBarBtn(
              icon: Icons.undo,
              tooltip: '撤销 (Ctrl+Z)',
              onTap: onUndo,
              isDark: isDark,
            ),

          // Open preview pane
          if (leaf.filePath != null && leaf.contentType == ContentType.markdown)
            _TitleBarBtn(
              icon: Icons.call_split_outlined,
              tooltip: '新建预览窗口',
              onTap: onOpenPreview,
              isDark: isDark,
            ),

          // Close button
          _TitleBarBtn(
            icon: Icons.close,
            tooltip: '关闭',
            onTap: onClose,
            isDark: isDark,
          ),

          const SizedBox(width: AppTheme.sp4),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  final bool isPreview;
  final VoidCallback onToggle;
  final bool isDark;

  const _SegmentedControl({
    required this.isPreview,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface3 = isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: surface3,
        borderRadius: BorderRadius.circular(AppTheme.radius6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: '源码',
            isActive: !isPreview,
            onTap: isPreview ? onToggle : null,
            isDark: isDark,
          ),
          _Segment(
            label: '渲染',
            isActive: isPreview,
            onTap: isPreview ? null : onToggle,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final bool isDark;

  const _Segment({
    required this.label,
    required this.isActive,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface2 = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? primary : textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TitleBarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _TitleBarBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: textSecondary),
        ),
      ),
    );
  }
}
