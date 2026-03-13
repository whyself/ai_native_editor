import 'package:flutter/material.dart';
import '../../models/pane_node.dart';
import '../../theme/app_colors.dart';

/// Translucent overlay shown during drag-over to indicate drop target zone.
class DropZoneOverlay extends StatelessWidget {
  final DropZone? zone;

  const DropZoneOverlay({super.key, this.zone});

  @override
  Widget build(BuildContext context) {
    if (zone == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DropZonePainter(zone!),
        ),
      ),
    );
  }
}

class _DropZonePainter extends CustomPainter {
  final DropZone zone;
  _DropZonePainter(this.zone);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = AppColors.dropHighlight;
    final border = Paint()
      ..color = AppColors.dropHighlightBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = switch (zone) {
      DropZone.top => Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      DropZone.bottom => Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5),
      DropZone.left => Rect.fromLTWH(0, 0, size.width * 0.5, size.height),
      DropZone.right => Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.5, size.height),
      DropZone.center => Rect.fromLTWH(0, 0, size.width, size.height),
    };

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(_DropZonePainter old) => old.zone != zone;
}

/// Detects which zone a drag position falls into.
DropZone detectDropZone(Offset localPos, Size size) {
  final nx = localPos.dx / size.width;
  final ny = localPos.dy / size.height;
  const t = 0.25;
  if (ny < t) return DropZone.top;
  if (ny > 1 - t) return DropZone.bottom;
  if (nx < t) return DropZone.left;
  if (nx > 1 - t) return DropZone.right;
  return DropZone.center;
}
