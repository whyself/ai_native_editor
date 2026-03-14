import 'package:flutter/material.dart';
import '../../models/drag_payload.dart';
import '../../models/pane_node.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PaneTitleBar extends StatelessWidget {
  final LeafNode leaf;
  final VoidCallback onClose;
  final VoidCallback onTogglePreview;
  final VoidCallback onOpenPreview;
  final VoidCallback onUndo;
  final VoidCallback? onSave;
  final bool isDark;

  const PaneTitleBar({
    super.key,
    required this.leaf,
    required this.onClose,
    required this.onTogglePreview,
    required this.onOpenPreview,
    required this.onUndo,
    this.onSave,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final border =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          // ── File icon + name — long-press drags pane OR to AI ────────────
          Expanded(
            child: LongPressDraggable<DragPayload>(
              data: TitleBarPayload(
                leafId: leaf.id,
                filePath: leaf.filePath,
              ),
              delay: const Duration(milliseconds: 400),
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface3
                        : AppColors.lightSurface3,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radius6),
                    border: Border.all(color: primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_with, size: 12, color: textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        leaf.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: _FileNameArea(
                leaf: leaf,
                isDark: isDark,
                textSecondary: textSecondary,
                textPrimary: textPrimary,
                primary: primary,
              ),
            ),
          ),

          // ── Source / Rendered toggle (hidden for preview-only panes) ─────
          if (leaf.filePath != null &&
              leaf.contentType == ContentType.markdown &&
              !leaf.previewOnly)
            _SegmentedControl(
              isPreview: leaf.isPreviewMode,
              onToggle: onTogglePreview,
              isDark: isDark,
            ),

          const SizedBox(width: AppTheme.sp4),

          // ── Save button (only when dirty, not for PDF) ────────────────
          if (leaf.hasUnsavedChanges &&
              !leaf.isPreviewMode &&
              leaf.filePath != null &&
              leaf.contentType != ContentType.pdf)
            _TitleBarBtn(
              icon: Icons.save_outlined,
              tooltip: '保存 (Ctrl+S)',
              onTap: onSave ?? () {},
              isDark: isDark,
              color: primary,
            ),

          // ── Undo button (not for PDF) ─────────────────────────────────
          if (!leaf.isPreviewMode &&
              leaf.filePath != null &&
              leaf.contentType != ContentType.pdf)
            _TitleBarBtn(
              icon: Icons.undo,
              tooltip: '撤销',
              onTap: onUndo,
              isDark: isDark,
            ),

          // ── Open preview pane (hidden for preview-only panes) ────────
          if (leaf.filePath != null &&
              leaf.contentType == ContentType.markdown &&
              !leaf.previewOnly)
            _TitleBarBtn(
              icon: Icons.call_split_outlined,
              tooltip: '新建预览窗口',
              onTap: onOpenPreview,
              isDark: isDark,
            ),

          // ── Close button ──────────────────────────────────────────────
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

// ── File name area ────────────────────────────────────────────────────────────

class _FileNameArea extends StatelessWidget {
  final LeafNode leaf;
  final bool isDark;
  final Color textSecondary;
  final Color textPrimary;
  final Color primary;

  const _FileNameArea({
    required this.leaf,
    required this.isDark,
    required this.textSecondary,
    required this.textPrimary,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.sp8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            leaf.previewOnly
                ? Icons.visibility_outlined
                : leaf.contentType == ContentType.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.description_outlined,
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
    );
  }
}

// ── Segmented control ─────────────────────────────────────────────────────────

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
    final surface3 =
        isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
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
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
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

// ── Title bar button ──────────────────────────────────────────────────────────

class _TitleBarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  const _TitleBarBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color ?? textSecondary),
        ),
      ),
    );
  }
}
