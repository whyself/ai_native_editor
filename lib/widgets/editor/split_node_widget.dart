import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pane_node.dart';
import '../../providers/pane_tree_provider.dart';
import '../layout/resize_divider.dart';
import 'leaf_node_widget.dart';

/// Renders a SplitNode as two children separated by a draggable divider.
class SplitNodeWidget extends ConsumerWidget {
  final SplitNode node;

  const SplitNodeWidget({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(paneTreeProvider.notifier);
    final isHorizontal = node.axis == Axis.horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = isHorizontal ? constraints.maxWidth : constraints.maxHeight;
        final minRatio = isHorizontal
            ? 200 / (totalSize > 0 ? totalSize : 200)
            : 150 / (totalSize > 0 ? totalSize : 150);
        final maxRatio = 1 - minRatio;
        final ratio = node.ratio.clamp(minRatio, maxRatio);

        Widget first = _buildChild(node.first);
        Widget second = _buildChild(node.second);

        if (isHorizontal) {
          return Row(
            children: [
              SizedBox(
                width: totalSize * ratio,
                child: first,
              ),
              ResizeDivider(
                axis: Axis.vertical,
                onDrag: (delta) {
                  final newRatio = ratio + delta / totalSize;
                  notifier.setRatio(node.id, newRatio);
                },
              ),
              Expanded(child: second),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(
                height: totalSize * ratio,
                child: first,
              ),
              ResizeDivider(
                axis: Axis.horizontal,
                onDrag: (delta) {
                  final newRatio = ratio + delta / totalSize;
                  notifier.setRatio(node.id, newRatio);
                },
              ),
              Expanded(child: second),
            ],
          );
        }
      },
    );
  }

  Widget _buildChild(PaneNode node) => switch (node) {
        LeafNode() => LeafNodeWidget(leaf: node),
        SplitNode() => SplitNodeWidget(node: node),
      };
}
