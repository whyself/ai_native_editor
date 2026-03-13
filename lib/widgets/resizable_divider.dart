import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_node.dart';
import '../providers/workspace_provider.dart';

/// 可拖拽的分割线组件（StatefulWidget 版本）
///
/// 使用本地 state 追踪拖拽中的比例，避免每次 onPanUpdate
/// 都等待 Provider rebuild 后才能响应下一帧，从而消除迟钝感。
class ResizableDivider extends ConsumerStatefulWidget {
  final String branchNodeId;
  final SplitDirection direction;
  final double thickness;
  final double totalSize;
  final double currentRatio;

  const ResizableDivider({
    super.key,
    required this.branchNodeId,
    required this.direction,
    this.thickness = 8.0,
    required this.totalSize,
    required this.currentRatio,
  });

  @override
  ConsumerState<ResizableDivider> createState() => _ResizableDividerState();
}

class _ResizableDividerState extends ConsumerState<ResizableDivider> {
  bool _isDragging = false;
  bool _isHovering = false;
  // 本地追踪拖拽中的比例，避免每帧都依赖已过期的 widget.currentRatio
  double _localRatio = 0.0;

  @override
  Widget build(BuildContext context) {
    final isVertical = widget.direction == SplitDirection.vertical;
    final colorScheme = Theme.of(context).colorScheme;
    final isHighlighted = _isDragging || _isHovering;

    return MouseRegion(
      cursor: isVertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => setState(() {
          _isDragging = true;
          // 拖拽开始时从 widget 同步一次当前比例
          _localRatio = widget.currentRatio;
        }),
        onPanUpdate: (details) {
          final delta = isVertical ? details.delta.dx : details.delta.dy;
          final availableSize = widget.totalSize - widget.thickness;
          if (availableSize <= 0) return;
          final deltaRatio = delta / availableSize;
          // 累加到本地 ratio，不依赖 widget.currentRatio（可能落后一帧）
          _localRatio = (_localRatio + deltaRatio).clamp(0.15, 0.85);
          ref.read(workspaceProvider.notifier).updateRatio(
                widget.branchNodeId,
                _localRatio,
              );
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        onPanCancel: () => setState(() => _isDragging = false),
        child: Container(
          width: isVertical ? widget.thickness : double.infinity,
          height: isVertical ? double.infinity : widget.thickness,
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isVertical ? (isHighlighted ? 4 : 2) : 40,
              height: isVertical ? 40 : (isHighlighted ? 4 : 2),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
