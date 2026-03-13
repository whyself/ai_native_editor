import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_node.dart';
import '../providers/workspace_provider.dart';

/// 拖拽数据载体
///
/// [sourcePanelId] 非空时表示拖拽来自工作区内的面板（用于面板间移动），
/// 为 null 时表示来自侧边栏（仅打开，无需关闭源）。
class PanelDragData {
  final PanelContent content;
  final String? sourcePanelId;
  const PanelDragData({required this.content, this.sourcePanelId});
}

/// 拖拽放下的方位（决定分割方向）
enum DropZone { left, right, top, bottom, center }

/// 面板容器（含 VS Code 风格的拖放方位感知 + 标题栏可拖拽移位）
class PanelContainer extends ConsumerStatefulWidget {
  final LeafNode node;

  const PanelContainer({
    super.key,
    required this.node,
  });

  @override
  ConsumerState<PanelContainer> createState() => _PanelContainerState();
}

class _PanelContainerState extends ConsumerState<PanelContainer> {
  DropZone? _activeDropZone;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider);
    final isActive = workspace.activePanelId == widget.node.content.id;
    final colorScheme = Theme.of(context).colorScheme;

    // Listener.onPointerDown 不进入手势 arena，不会与子组件（InkWell、Draggable）竞争，
    // 确保任何触点都能激活面板，同时关闭按钮的 onTap 照常工作。
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        ref.read(workspaceProvider.notifier).setActivePanel(widget.node.content.id);
      },
      child: DragTarget<PanelDragData>(
        // 拒绝面板拖到自身
        onWillAcceptWithDetails: (details) =>
            details.data.sourcePanelId != widget.node.content.id,
        onMove: (details) {
          final zone = _getDropZone(context, details.offset);
          if (zone != _activeDropZone) {
            setState(() => _activeDropZone = zone);
          }
        },
        onLeave: (_) {
          setState(() => _activeDropZone = null);
        },
        onAcceptWithDetails: (details) {
          final zone = _activeDropZone ?? DropZone.right;
          setState(() => _activeDropZone = null);

          final sourceId = details.data.sourcePanelId;

          if (zone == DropZone.center) {
            ref.read(workspaceProvider.notifier).replacePanelContent(
                  widget.node.content.id, details.data.content);
          } else {
            final direction = (zone == DropZone.left || zone == DropZone.right)
                ? SplitDirection.vertical
                : SplitDirection.horizontal;
            final insertBefore = zone == DropZone.left || zone == DropZone.top;
            ref.read(workspaceProvider.notifier).splitPanel(
                  widget.node.content.id, direction, details.data.content,
                  insertBefore: insertBefore);
          }

          // 面板间移动：关闭拖拽来源面板
          if (sourceId != null && sourceId != widget.node.content.id) {
            ref.read(workspaceProvider.notifier).closePanel(sourceId);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isDragOver = candidateData.isNotEmpty;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(
                    color: isDragOver
                        ? colorScheme.primary
                        : (isActive
                            ? colorScheme.primary
                            : colorScheme.outlineVariant),
                    width: isDragOver ? 2 : (isActive ? 2 : 1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildTitleBar(context, colorScheme, isActive),
                    Expanded(child: _buildContent(context, colorScheme)),
                  ],
                ),
              ),
              if (_activeDropZone != null && isDragOver)
                Positioned.fill(child: _buildDropOverlay(colorScheme)),
            ],
          );
        },
      ),
    );
  }

  /// 根据全局坐标判断落入面板的哪个方位
  DropZone _getDropZone(BuildContext context, Offset globalOffset) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return DropZone.center;

    final local = box.globalToLocal(globalOffset);
    final size = box.size;
    if (size.width <= 0 || size.height <= 0) return DropZone.center;

    final nx = (local.dx / size.width).clamp(0.0, 1.0);
    final ny = (local.dy / size.height).clamp(0.0, 1.0);

    if (nx > 0.3 && nx < 0.7 && ny > 0.3 && ny < 0.7) return DropZone.center;

    final distances = {
      DropZone.left: nx,
      DropZone.right: 1 - nx,
      DropZone.top: ny,
      DropZone.bottom: 1 - ny,
    };
    return distances.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  /// VS Code 风格的方位高亮覆盖层
  Widget _buildDropOverlay(ColorScheme colorScheme) {
    final color = colorScheme.primary.withOpacity(0.2);
    final border = Border.all(
        color: colorScheme.primary.withOpacity(0.6), width: 2);

    switch (_activeDropZone!) {
      case DropZone.left:
        return Row(children: [
          Expanded(
              child: Container(
                  decoration: BoxDecoration(color: color, border: border))),
          const Expanded(child: SizedBox()),
        ]);
      case DropZone.right:
        return Row(children: [
          const Expanded(child: SizedBox()),
          Expanded(
              child: Container(
                  decoration: BoxDecoration(color: color, border: border))),
        ]);
      case DropZone.top:
        return Column(children: [
          Expanded(
              child: Container(
                  decoration: BoxDecoration(color: color, border: border))),
          const Expanded(child: SizedBox()),
        ]);
      case DropZone.bottom:
        return Column(children: [
          const Expanded(child: SizedBox()),
          Expanded(
              child: Container(
                  decoration: BoxDecoration(color: color, border: border))),
        ]);
      case DropZone.center:
        return Container(
            decoration: BoxDecoration(color: color, border: border));
    }
  }

  Widget _buildTitleBar(
      BuildContext context, ColorScheme colorScheme, bool isActive) {
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 可拖拽区域（图标 + 标题）——携带 sourcePanelId 以便目标侧关闭源面板
          Expanded(
            child: Draggable<PanelDragData>(
              data: PanelDragData(
                content: widget.node.content,
                sourcePanelId: widget.node.content.id,
              ),
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.primaryContainer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIcon(),
                          size: 16,
                          color: colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        widget.node.content.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.4,
                child: _buildTitleContent(colorScheme, isActive),
              ),
              child: _buildTitleContent(colorScheme, isActive),
            ),
          ),
          // 关闭按钮——独立于 Draggable 之外，不存在手势竞争
          SizedBox(
            width: 28,
            height: 28,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref
                      .read(workspaceProvider.notifier)
                      .closePanel(widget.node.content.id);
                },
                borderRadius: BorderRadius.circular(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleContent(ColorScheme colorScheme, bool isActive) {
    return Row(
      children: [
        Icon(Icons.drag_indicator,
            size: 14,
            color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
        const SizedBox(width: 4),
        Icon(_getIcon(), size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.node.content.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    switch (widget.node.content.type) {
      case PanelType.empty:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('AI Native Freeform Editor',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color:
                          colorScheme.onSurfaceVariant.withOpacity(0.5))),
              const SizedBox(height: 8),
              Text('从侧边栏拖拽文档至此处',
                  style: TextStyle(
                      fontSize: 14,
                      color:
                          colorScheme.onSurfaceVariant.withOpacity(0.4))),
            ],
          ),
        );
      case PanelType.markdown:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '\u{1F4C4} Markdown 编辑器\n\n文件: ${widget.node.content.filePath ?? "未命名"}',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        );
      case PanelType.aiChat:
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text('\u{1F916} AI Agent 对话面板',
              style: TextStyle(color: colorScheme.onSurface)),
        );
    }
  }

  IconData _getIcon() {
    switch (widget.node.content.type) {
      case PanelType.empty:
        return Icons.dashboard;
      case PanelType.markdown:
        return Icons.description;
      case PanelType.aiChat:
        return Icons.smart_toy;
    }
  }
}
