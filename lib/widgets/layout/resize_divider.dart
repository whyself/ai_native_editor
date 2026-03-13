import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A 1px visual divider with a 16px touch hotzone.
/// Long-press drag to resize. Double-tap to reset.
class ResizeDivider extends StatefulWidget {
  final Axis axis; // horizontal divider = vertical layout; vertical divider = horizontal layout
  final VoidCallback? onDoubleTap;
  final void Function(double delta) onDrag;

  const ResizeDivider({
    super.key,
    required this.axis,
    required this.onDrag,
    this.onDoubleTap,
  });

  @override
  State<ResizeDivider> createState() => _ResizeDividerState();
}

class _ResizeDividerState extends State<ResizeDivider> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final hoverColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    final isVertical = widget.axis == Axis.vertical;

    return MouseRegion(
      cursor: isVertical ? SystemMouseCursors.resizeColumn : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        onVerticalDragStart: isVertical ? null : (_) => setState(() => _dragging = true),
        onVerticalDragUpdate: isVertical ? null : (d) => widget.onDrag(d.delta.dy),
        onVerticalDragEnd: isVertical ? null : (_) => setState(() => _dragging = false),
        onHorizontalDragStart: isVertical ? (_) => setState(() => _dragging = true) : null,
        onHorizontalDragUpdate: isVertical ? (d) => widget.onDrag(d.delta.dx) : null,
        onHorizontalDragEnd: isVertical ? (_) => setState(() => _dragging = false) : null,
        child: Container(
          width: isVertical ? 16 : double.infinity,
          height: isVertical ? double.infinity : 16,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isVertical ? 1 : double.infinity,
            height: isVertical ? double.infinity : 1,
            color: _dragging ? hoverColor : borderColor,
          ),
        ),
      ),
    );
  }
}
