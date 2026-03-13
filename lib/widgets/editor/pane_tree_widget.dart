import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pane_node.dart';
import '../../providers/pane_tree_provider.dart';
import 'leaf_node_widget.dart';
import 'split_node_widget.dart';

/// Root widget that renders the entire PaneTree.
class PaneTreeWidget extends ConsumerWidget {
  const PaneTreeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final root = ref.watch(paneTreeProvider);
    return _buildNode(root);
  }

  Widget _buildNode(PaneNode node) => switch (node) {
        LeafNode() => LeafNodeWidget(leaf: node),
        SplitNode() => SplitNodeWidget(node: node),
      };
}
