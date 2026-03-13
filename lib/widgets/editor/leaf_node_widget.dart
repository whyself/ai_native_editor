import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/drag_payload.dart';
import '../../models/pane_node.dart';
import '../../providers/pane_tree_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'drop_zone_overlay.dart';
import 'markdown_editor.dart';
import 'markdown_preview.dart';
import 'pane_title_bar.dart';

class LeafNodeWidget extends ConsumerStatefulWidget {
  final LeafNode leaf;

  const LeafNodeWidget({super.key, required this.leaf});

  @override
  ConsumerState<LeafNodeWidget> createState() => _LeafNodeWidgetState();
}

class _LeafNodeWidgetState extends ConsumerState<LeafNodeWidget> {
  DropZone? _hoverZone;
  // GlobalKey lets the title-bar save button reach into the editor's save().
  final _editorKey = GlobalKey<MarkdownEditorState>();

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final leaf = widget.leaf;
    final notifier = ref.read(paneTreeProvider.notifier);
    final surface = isDark ? AppColors.darkSurface1 : AppColors.lightSurface1;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return DragTarget<DragPayload>(
      onWillAcceptWithDetails: (details) {
        final payload = details.data;
        if (payload is TitleBarPayload) {
          // Don't allow dropping a pane onto itself.
          return payload.leafId != leaf.id;
        }
        if (payload is FilePathPayload) {
          // Reject if this file is already open in any leaf.
          final tree = ref.read(paneTreeProvider);
          final alreadyOpen = collectLeafIds(tree)
              .map((id) => findNode(tree, id))
              .whereType<LeafNode>()
              .any((n) => n.filePath == payload.filePath);
          return !alreadyOpen;
        }
        return true;
      },
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(details.offset);
        final zone = detectDropZone(local, box.size);
        if (zone != _hoverZone) setState(() => _hoverZone = zone);
      },
      onLeave: (_) => setState(() => _hoverZone = null),
      onAcceptWithDetails: (details) {
        setState(() => _hoverZone = null);
        final payload = details.data;
        final zone = detectDropZone(
          (context.findRenderObject() as RenderBox).globalToLocal(details.offset),
          (context.findRenderObject() as RenderBox).size,
        );
        switch (payload) {
          case FilePathPayload(:final filePath):
            if (zone == DropZone.center) {
              notifier.openFile(leaf.id, filePath);
            } else {
              notifier.splitWithFile(leaf.id, filePath, zone);
            }
          case PanePayload(:final leafId):
            notifier.moveLeaf(leafId, leaf.id, zone);
          case TitleBarPayload(:final leafId):
            notifier.moveLeaf(leafId, leaf.id, zone);
        }
      },
      builder: (context, candidates, rejected) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: border),
          ),
          child: Stack(
            children: [
              // Main content column
              Column(
                children: [
                  // Title bar — drag handles now live inside PaneTitleBar
                  _buildTitleBar(notifier, leaf),
                  // Content area
                  Expanded(child: _buildContent(leaf)),
                ],
              ),
              // Drop zone overlay
              if (_hoverZone != null) DropZoneOverlay(zone: _hoverZone),
              // Empty state drop indicator
              if (leaf.filePath == null)
                _EmptyDropTarget(isDark: isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleBar(PaneTreeNotifier notifier, LeafNode leaf) {
    return PaneTitleBar(
      leaf: leaf,
      isDark: isDark,
      onClose: () => notifier.closeLeaf(leaf.id),
      onTogglePreview: () =>
          notifier.setPreviewMode(leaf.id, !leaf.isPreviewMode),
      onOpenPreview: () => notifier.openPreviewPane(leaf.id),
      onUndo: () => _editorKey.currentState?.undo(),
      onSave: () => _editorKey.currentState?.save(),
    );
  }

  Widget _buildContent(LeafNode leaf) {
    if (leaf.filePath == null) {
      return _WelcomePane(isDark: isDark);
    }
    if (leaf.isPreviewMode) {
      return MarkdownPreview(filePath: leaf.filePath!, isDark: isDark);
    }
    return MarkdownEditor(
      key: _editorKey,
      leafId: leaf.id,
      filePath: leaf.filePath!,
      isDark: isDark,
    );
  }
}

class _WelcomePane extends StatelessWidget {
  final bool isDark;
  const _WelcomePane({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_indicator, size: 40, color: textMuted),
            const SizedBox(height: AppTheme.sp12),
            Text(
              '拖入文件开始阅读',
              style: TextStyle(fontSize: 16, color: textMuted),
            ),
            const SizedBox(height: AppTheme.sp8),
            Text(
              '或从左侧文件列表拖拽文件至此',
              style: TextStyle(fontSize: 13, color: textMuted.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDropTarget extends StatelessWidget {
  final bool isDark;
  const _EmptyDropTarget({required this.isDark});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
