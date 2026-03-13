import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/split_node.dart';
import 'resizable_divider.dart';
import 'panel_container.dart';

/// 递归渲染分区树的核心组件
///
/// 根据 SplitNode 递归地构建 Row/Column + 分割线布局，
/// 最终叶子节点渲染为 PanelContainer。
///
/// 使用 Flexible + flex 比例分配空间，避免硬算 SizedBox 像素导致负值。
class SplitView extends ConsumerWidget {
  final SplitNode node;

  const SplitView({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentNode = node;
    if (currentNode is LeafNode) {
      return PanelContainer(node: currentNode);
    } else if (currentNode is BranchNode) {
      return _buildBranch(context, ref, currentNode);
    }
    return const SizedBox.shrink();
  }

  Widget _buildBranch(BuildContext context, WidgetRef ref, BranchNode branch) {
    final isVertical = branch.direction == SplitDirection.vertical;
    const dividerThickness = 8.0;

    // 将 ratio (0~1) 转换为整数 flex 值，精度足够
    final firstFlex = (branch.ratio * 1000).round().clamp(1, 999);
    final secondFlex = 1000 - firstFlex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = isVertical ? constraints.maxWidth : constraints.maxHeight;

        final children = <Widget>[
          // 第一个子区域
          Flexible(
            flex: firstFlex,
            child: SplitView(node: branch.first),
          ),
          // 可拖拽的分割线
          ResizableDivider(
            branchNodeId: branch.id,
            direction: branch.direction,
            thickness: dividerThickness,
            totalSize: totalSize,
            currentRatio: branch.ratio,
          ),
          // 第二个子区域
          Flexible(
            flex: secondFlex,
            child: SplitView(node: branch.second),
          ),
        ];

        if (isVertical) {
          return Row(children: children);
        } else {
          return Column(children: children);
        }
      },
    );
  }
}
